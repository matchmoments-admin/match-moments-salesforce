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
        
        syncLineupsFromESPN({ matchId: this.recordId })
            .then(result => {
                if (result.success) {
                    // Reload lineups after sync
                    this.loadLineups();
                    
                    // Show success toast
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result.message || 'Lineups synced from ESPN successfully',
                            variant: 'success'
                        })
                    );
                } else {
                    throw new Error(result.message || 'Failed to sync lineups');
                }
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = this.getErrorMessage(error);
                console.error('Error syncing lineups from ESPN:', error);
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.errorMessage,
                        variant: 'error'
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
     * @description Extract error message from various error formats
     * @param error Error object from Apex call
     * @return String error message
     */
    getErrorMessage(error) {
        if (!error) {
            return 'An unexpected error occurred';
        }
        
        try {
            // Handle Apex exception
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
            
            return 'An unexpected error occurred';
        } catch (parseError) {
            console.error('Error parsing error object:', parseError);
            return 'An error occurred. Please check the browser console for details.';
        }
    }
    
}

