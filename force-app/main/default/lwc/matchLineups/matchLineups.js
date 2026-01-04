/**
 * @description Match Lineups component - displays both teams' lineups with formations
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMatchLineups from '@salesforce/apex/MatchSummaryController.getMatchLineups';
import syncLineupsFromESPN from '@salesforce/apex/MatchSummaryController.syncLineupsFromESPN';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Name'
];

export default class MatchLineups extends LightningElement {
    @api recordId;
    
    @track homeLineup = null;
    @track awayLineup = null;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track hasLineups = false;
    @track isCreatingLineup = false;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.loadLineups();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match';
            this.isLoading = false;
        }
    }
    
    loadLineups() {
        getMatchLineups({ matchId: this.recordId })
            .then(result => {
                this.homeLineup = result.homeLineup || null;
                this.awayLineup = result.awayLineup || null;
                this.hasLineups = result.hasLineups || false;
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = this.getErrorMessage(error);
                this.isLoading = false;
                console.error('Error loading lineups:', error);
            });
    }
    
    handleSyncFromESPN() {
        this.isCreatingLineup = true;
        this.hasError = false;
        this.errorMessage = '';
        
        syncLineupsFromESPN({ matchId: this.recordId })
            .then(result => {
                if (result.success) {
                    // Reload lineups after sync
                    this.loadLineups();
                    
                    // Build success message
                    let successMessage = result.message || 'Lineups synced from ESPN successfully';
                    
                    // Show warnings if any
                    if (result.warnings && Array.isArray(result.warnings) && result.warnings.length > 0) {
                        const warningCount = result.warnings.length;
                        successMessage += ` (${warningCount} warning${warningCount !== 1 ? 's' : ''} - see details below)`;
                        
                        // Show warning toast
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Sync Completed with Warnings',
                                message: `${warningCount} warning${warningCount !== 1 ? 's' : ''} occurred during sync. Some data may be incomplete.`,
                                variant: 'warning',
                                mode: 'sticky'
                            })
                        );
                    }
                    
                    // Show success toast
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: successMessage,
                            variant: 'success',
                            mode: result.warnings && result.warnings.length > 0 ? 'dismissable' : 'pester'
                        })
                    );
                    
                    // Log warnings to console for debugging
                    if (result.warnings && Array.isArray(result.warnings) && result.warnings.length > 0) {
                        console.warn('Lineup sync warnings:', result.warnings);
                    }
                } else {
                    throw new Error(result.message || 'Failed to sync lineups');
                }
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = this.getErrorMessage(error);
                console.error('Error syncing lineups from ESPN:', error);
                
                // Determine if error is actionable
                const actionableMessage = this.getActionableErrorMessage(this.errorMessage);
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Sync Failed',
                        message: actionableMessage.userMessage,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            })
            .finally(() => {
                this.isCreatingLineup = false;
            });
    }
    
    // Getters
    get hasAnyLineups() {
        return this.hasLineups || (this.homeLineup?.hasLineup === true) || (this.awayLineup?.hasLineup === true);
    }
    
    get homeFormation() {
        return this.homeLineup?.formation || 'N/A';
    }
    
    get awayFormation() {
        return this.awayLineup?.formation || 'N/A';
    }
    
    get homePlayers() {
        if (!this.homeLineup?.players) return { starting: [], bench: [] };
        return this.parseLineupPlayers(this.homeLineup.players, this.homeLineup);
    }
    
    get awayPlayers() {
        if (!this.awayLineup?.players) return { starting: [], bench: [] };
        return this.parseLineupPlayers(this.awayLineup.players, this.awayLineup);
    }
    
    parseLineupPlayers(playersData, lineup) {
        const players = [];
        const captainId = lineup?.captainId;
        
        // Parse goalkeeper
        if (playersData.goalkeeper) {
            players.push({
                ...playersData.goalkeeper,
                position: 'GK',
                isGoalkeeper: true,
                isCaptain: playersData.goalkeeper.playerId === captainId
            });
        }
        
        // Parse formation lines
        if (playersData.lines && Array.isArray(playersData.lines)) {
            playersData.lines.forEach(line => {
                if (line.players && Array.isArray(line.players)) {
                    line.players.forEach(player => {
                        players.push({
                            ...player,
                            position: player.position || 'MF',
                            isGoalkeeper: false,
                            isCaptain: player.playerId === captainId
                        });
                    });
                }
            });
        }
        
        // Parse bench
        const bench = [];
        if (playersData.bench && Array.isArray(playersData.bench)) {
            playersData.bench.forEach(player => {
                bench.push({
                    ...player,
                    position: player.position || 'SUB',
                    isSubstitute: true,
                    isCaptain: player.playerId === captainId
                });
            });
        }
        
        return { starting: players, bench: bench };
    }
    
    get homeStartingXI() {
        return this.homePlayers.starting || [];
    }
    
    get homeBench() {
        return this.homePlayers.bench || [];
    }
    
    get awayStartingXI() {
        return this.awayPlayers.starting || [];
    }
    
    get awayBench() {
        return this.awayPlayers.bench || [];
    }
    
    get homeTeamName() {
        return this.homeLineup?.team?.name || 'Home Team';
    }
    
    get awayTeamName() {
        return this.awayLineup?.team?.name || 'Away Team';
    }
    
    get homeTeamLogo() {
        return this.homeLineup?.team?.logoUrl;
    }
    
    get awayTeamLogo() {
        return this.awayLineup?.team?.logoUrl;
    }
    
    get canSyncFromESPN() {
        return !this.hasLineups && !this.isLoading && !this.isCreatingLineup;
    }
    
    get homeTeamHasLineup() {
        return this.homeLineup?.hasLineup === true;
    }
    
    get awayTeamHasLineup() {
        return this.awayLineup?.hasLineup === true;
    }
    
    get homeTeamId() {
        return this.homeLineup?.team?.id;
    }
    
    get awayTeamId() {
        return this.awayLineup?.team?.id;
    }
    
    /**
     * @description Handle image loading errors (e.g., CSP violations)
     * @param event Error event from img onerror handler
     */
    handleImageError(event) {
        // Hide the broken image and let the fallback icon show
        if (event.target) {
            event.target.style.display = 'none';
        }
        // Log warning (CSP violations are expected for external ESPN images)
        console.warn('Team logo image failed to load (may be blocked by CSP):', event.target?.src);
    }
    
    /**
     * @description Extract error message from various error formats
     * @param error Error object from Apex call
     * @return String error message
     */
    getErrorMessage(error) {
        if (!error) {
            return 'An unexpected error occurred';
        }
        
        try {
            // Handle Apex exception (AuraHandledException, ESPNException, etc.)
            if (error.body) {
                if (error.body.message) {
                    return error.body.message;
                } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    return error.body.pageErrors[0].message;
                } else if (error.body.fieldErrors) {
                    const fieldErrors = Object.values(error.body.fieldErrors);
                    if (fieldErrors.length > 0 && fieldErrors[0].length > 0) {
                        return fieldErrors[0][0].message;
                    }
                } else if (error.body.output && error.body.output.errors) {
                    // Handle additional error formats
                    const errors = error.body.output.errors;
                    if (Array.isArray(errors) && errors.length > 0) {
                        return errors[0].message || errors[0];
                    }
                }
            }
            
            // Handle standard JavaScript error
            if (error.message) {
                return error.message;
            }
            
            // Handle string errors
            if (typeof error === 'string') {
                return error;
            }
            
            // Handle error objects with status/statusText
            if (error.status && error.statusText) {
                return `HTTP ${error.status}: ${error.statusText}`;
            }
            
            return 'An unexpected error occurred';
        } catch (parseError) {
            console.error('Error parsing error object:', parseError);
            return 'An error occurred. Please check the browser console for details.';
        }
    }
    
    /**
     * @description Get actionable error message with user guidance
     * @param errorMessage The raw error message
     * @return Object with userMessage and actionable flag
     */
    getActionableErrorMessage(errorMessage) {
        if (!errorMessage) {
            return {
                userMessage: 'An unexpected error occurred. Please try again or contact your administrator.',
                actionable: false
            };
        }
        
        const lowerMessage = errorMessage.toLowerCase();
        
        // ESPN API errors
        if (lowerMessage.includes('espn event id') || lowerMessage.includes('event id')) {
            return {
                userMessage: 'ESPN Event ID is missing or invalid. Please set the ESPN_Event_ID__c field on the match record.',
                actionable: true
            };
        }
        
        if (lowerMessage.includes('espn api') || lowerMessage.includes('espn')) {
            if (lowerMessage.includes('timeout') || lowerMessage.includes('timed out')) {
                return {
                    userMessage: 'ESPN API request timed out. Please try again in a moment.',
                    actionable: true
                };
            }
            if (lowerMessage.includes('not found') || lowerMessage.includes('404')) {
                return {
                    userMessage: 'ESPN event not found. Please verify the ESPN_Event_ID__c field is correct.',
                    actionable: true
                };
            }
            if (lowerMessage.includes('unavailable') || lowerMessage.includes('500') || lowerMessage.includes('503')) {
                return {
                    userMessage: 'ESPN API is temporarily unavailable. Please try again later.',
                    actionable: true
                };
            }
            if (lowerMessage.includes('rate limit') || lowerMessage.includes('429')) {
                return {
                    userMessage: 'ESPN API rate limit exceeded. Please wait a moment before trying again.',
                    actionable: true
                };
            }
        }
        
        // Data validation errors
        if (lowerMessage.includes('competition') && lowerMessage.includes('required')) {
            return {
                userMessage: 'This match is not linked to a Competition. Please set the Competition__c field before syncing lineups.',
                actionable: true
            };
        }
        
        if (lowerMessage.includes('team') && (lowerMessage.includes('not found') || lowerMessage.includes('missing'))) {
            return {
                userMessage: 'Team information is missing. Please ensure Home_Team__c and Away_Team__c are set on the match record.',
                actionable: true
            };
        }
        
        // DML errors
        if (lowerMessage.includes('field') && lowerMessage.includes('required')) {
            return {
                userMessage: 'Required fields are missing. Please check the error details and ensure all required fields are populated.',
                actionable: true
            };
        }
        
        if (lowerMessage.includes('validation') || lowerMessage.includes('validation rule')) {
            return {
                userMessage: 'Data validation failed. Please check the match and team records meet all validation requirements.',
                actionable: true
            };
        }
        
        // Permission errors
        if (lowerMessage.includes('permission') || lowerMessage.includes('access') || lowerMessage.includes('insufficient')) {
            return {
                userMessage: 'You do not have permission to perform this action. Please contact your administrator.',
                actionable: true
            };
        }
        
        // Governor limit errors
        if (lowerMessage.includes('governor') || lowerMessage.includes('limit')) {
            return {
                userMessage: 'Salesforce governor limits were exceeded. Please try syncing fewer records at once or contact your administrator.',
                actionable: true
            };
        }
        
        // Network/connection errors
        if (lowerMessage.includes('network') || lowerMessage.includes('connection') || lowerMessage.includes('fetch')) {
            return {
                userMessage: 'Network error occurred. Please check your internet connection and try again.',
                actionable: true
            };
        }
        
        // Default: return original message but indicate it may need admin help
        return {
            userMessage: errorMessage + ' If this issue persists, please contact your administrator.',
            actionable: false
        };
    }
    
}

