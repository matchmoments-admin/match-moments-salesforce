/**
 * @description Match Statistics component - displays possession chart and statistics comparison bars
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getMatchStats from '@salesforce/apex/MatchSummaryController.getMatchStats';
import getMatchSummary from '@salesforce/apex/MatchSummaryController.getMatchSummary';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Name'
];

export default class MatchStats extends LightningElement {
    @api recordId;
    
    @track matchData = {};
    @track stats = {};
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.loadData();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match';
            this.isLoading = false;
        }
    }
    
    loadData() {
        Promise.all([
            getMatchStats({ matchId: this.recordId }),
            getMatchSummary({ matchId: this.recordId })
        ])
        .then(([stats, summary]) => {
            this.stats = stats || {};
            this.matchData = summary.match || {};
            this.isLoading = false;
        })
        .catch(error => {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match statistics';
            this.isLoading = false;
            console.error('Error loading match stats:', error);
        });
    }
    
    // Getters
    get homePossession() {
        return this.stats.homePossession || 50;
    }
    
    get awayPossession() {
        return this.stats.awayPossession || 50;
    }
    
    get homePossessionStyle() {
        return `width: ${this.homePossession}%`;
    }
    
    get awayPossessionStyle() {
        return `width: ${this.awayPossession}%`;
    }
    
    get homeShotsOnGoal() {
        return this.stats.homeShotsOnGoal || 0;
    }
    
    get awayShotsOnGoal() {
        return this.stats.awayShotsOnGoal || 0;
    }
    
    get homeShotsOnGoalStyle() {
        const total = this.homeShotsOnGoal + this.awayShotsOnGoal;
        const width = total > 0 ? (this.homeShotsOnGoal / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get awayShotsOnGoalStyle() {
        const total = this.homeShotsOnGoal + this.awayShotsOnGoal;
        const width = total > 0 ? (this.awayShotsOnGoal / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get homeShotAttempts() {
        return this.stats.homeShotAttempts || 0;
    }
    
    get awayShotAttempts() {
        return this.stats.awayShotAttempts || 0;
    }
    
    get homeShotAttemptsStyle() {
        const total = this.homeShotAttempts + this.awayShotAttempts;
        const width = total > 0 ? (this.homeShotAttempts / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get awayShotAttemptsStyle() {
        const total = this.homeShotAttempts + this.awayShotAttempts;
        const width = total > 0 ? (this.awayShotAttempts / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get homeYellowCards() {
        return this.stats.homeYellowCards || 0;
    }
    
    get awayYellowCards() {
        return this.stats.awayYellowCards || 0;
    }
    
    get homeYellowCardsStyle() {
        const total = this.homeYellowCards + this.awayYellowCards;
        const width = total > 0 ? (this.homeYellowCards / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get awayYellowCardsStyle() {
        const total = this.homeYellowCards + this.awayYellowCards;
        const width = total > 0 ? (this.awayYellowCards / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get homeCornerKicks() {
        return this.stats.homeCornerKicks || 0;
    }
    
    get awayCornerKicks() {
        return this.stats.awayCornerKicks || 0;
    }
    
    get homeCornerKicksStyle() {
        const total = this.homeCornerKicks + this.awayCornerKicks;
        const width = total > 0 ? (this.homeCornerKicks / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get awayCornerKicksStyle() {
        const total = this.homeCornerKicks + this.awayCornerKicks;
        const width = total > 0 ? (this.awayCornerKicks / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get homeSaves() {
        return this.stats.homeSaves || 0;
    }
    
    get awaySaves() {
        return this.stats.awaySaves || 0;
    }
    
    get homeSavesStyle() {
        const total = this.homeSaves + this.awaySaves;
        const width = total > 0 ? (this.homeSaves / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get awaySavesStyle() {
        const total = this.homeSaves + this.awaySaves;
        const width = total > 0 ? (this.awaySaves / total) * 100 : 0;
        return `width: ${width}%`;
    }
    
    get homeTeamName() {
        return this.matchData.homeTeam?.name || 'Home';
    }
    
    get awayTeamName() {
        return this.matchData.awayTeam?.name || 'Away';
    }
    
    get hasStats() {
        return Object.keys(this.stats).length > 0;
    }
}
