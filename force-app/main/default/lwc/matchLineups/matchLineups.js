/**
 * @description Match Lineups component - displays both teams' lineups with formations
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getMatchLineups from '@salesforce/apex/MatchSummaryController.getMatchLineups';

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
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body?.message || 'Error loading lineups';
                this.isLoading = false;
                console.error('Error loading lineups:', error);
            });
    }
    
    // Getters
    get hasLineups() {
        return this.homeLineup || this.awayLineup;
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
    
}

