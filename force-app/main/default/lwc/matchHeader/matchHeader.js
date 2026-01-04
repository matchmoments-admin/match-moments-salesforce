/**
 * @description Match Header component - displays match scoreboard with teams, scores, goal scorers, and match status
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getMatchSummary from '@salesforce/apex/MatchSummaryController.getMatchSummary';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Name'
];

export default class MatchHeader extends LightningElement {
    @api recordId;
    
    @track matchData = {};
    @track goalScorers = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            // Record loaded, now fetch summary
            this.loadMatchSummary();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match';
            this.isLoading = false;
        }
    }
    
    loadMatchSummary() {
        getMatchSummary({ matchId: this.recordId })
            .then(result => {
                this.matchData = result.match || {};
                this.goalScorers = result.goalScorers || [];
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body?.message || 'Error loading match summary';
                this.isLoading = false;
                console.error('Error loading match summary:', error);
            });
    }
    
    // Getters
    get homeTeam() {
        return this.matchData.homeTeam || {};
    }
    
    get awayTeam() {
        return this.matchData.awayTeam || {};
    }
    
    get competition() {
        return this.matchData.competition || {};
    }
    
    get scoreDisplay() {
        const home = this.matchData.homeScore || 0;
        const away = this.matchData.awayScore || 0;
        return `${home} - ${away}`;
    }
    
    get matchStatus() {
        return this.matchData.status || 'Unknown';
    }
    
    get statusBadgeVariant() {
        const status = this.matchStatus.toLowerCase();
        if (status === 'final' || status === 'ft') return 'success';
        if (status === 'in progress' || status === 'live') return 'error';
        if (status === 'scheduled') return 'info';
        return 'default';
    }
    
    get formattedDate() {
        if (!this.matchData.matchDateTime) return '';
        const date = new Date(this.matchData.matchDateTime);
        return date.toLocaleDateString('en-US', { 
            weekday: 'short', 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    get homeGoalScorers() {
        if (!this.matchData.homeTeam) return [];
        return this.goalScorers.filter(gs => gs.teamId === this.matchData.homeTeam.id);
    }
    
    get awayGoalScorers() {
        if (!this.matchData.awayTeam) return [];
        return this.goalScorers.filter(gs => gs.teamId === this.matchData.awayTeam.id);
    }
    
    formatGoalScorer(scorer) {
        const minute = scorer.minute || 0;
        const playerName = scorer.playerName || 'Unknown';
        return `${playerName} - ${minute}'`;
    }
    
    get formattedHomeGoalScorers() {
        return this.homeGoalScorers.map(scorer => this.formatGoalScorer(scorer));
    }
    
    get formattedAwayGoalScorers() {
        return this.awayGoalScorers.map(scorer => this.formatGoalScorer(scorer));
    }
}

