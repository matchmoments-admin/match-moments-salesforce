/**
 * @description Match Timeline component - visual horizontal timeline of match events
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getMatchMoments from '@salesforce/apex/MatchSummaryController.getMatchMoments';
import getMatchSummary from '@salesforce/apex/MatchSummaryController.getMatchSummary';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Name'
];

export default class MatchTimeline extends LightningElement {
    @api recordId;
    
    @track moments = [];
    @track matchData = {};
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
            getMatchMoments({ matchId: this.recordId }),
            getMatchSummary({ matchId: this.recordId })
        ])
        .then(([moments, summary]) => {
            // Add icon properties to each moment
            const processedMoments = (moments || []).map(moment => ({
                ...moment,
                iconName: this.getEventIconName(moment),
                iconVariant: this.getEventIconVariant(moment)
            }));
            this.moments = processedMoments;
            this.matchData = summary.match || {};
            this.isLoading = false;
        })
        .catch(error => {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading timeline';
            this.isLoading = false;
            console.error('Error loading timeline data:', error);
        });
    }
    
    // Getters
    get homeTeamId() {
        return this.matchData.homeTeam?.id;
    }
    
    get awayTeamId() {
        return this.matchData.awayTeam?.id;
    }
    
    get timelineEvents() {
        // Group events by minute and create timeline structure
        const eventsByMinute = {};
        const keyEvents = this.moments.filter(m => 
            m.eventType === 'Goal' || 
            m.eventType === 'Yellow Card' || 
            m.eventType === 'Red Card' || 
            m.eventType === 'Substitution'
        );
        
        keyEvents.forEach(moment => {
            const minute = moment.minute || 0;
            if (!eventsByMinute[minute]) {
                eventsByMinute[minute] = [];
            }
            eventsByMinute[minute].push(moment);
        });
        
        // Create timeline points
        const timeline = [];
        const maxMinute = Math.max(...this.moments.map(m => m.minute || 0), 90);
        
        // Add key minutes (0, 45, 90, and event minutes)
        const keyMinutes = new Set([0, 45, 90]);
        keyEvents.forEach(m => keyMinutes.add(m.minute || 0));
        
        Array.from(keyMinutes).sort((a, b) => a - b).forEach(minute => {
            timeline.push({
                minute: minute,
                label: this.getMinuteLabel(minute),
                events: eventsByMinute[minute] || [],
                isPeriodMarker: minute === 0 || minute === 45 || minute === 90
            });
        });
        
        return timeline;
    }
    
    getMinuteLabel(minute) {
        if (minute === 0) return 'KO';
        if (minute === 45) return 'HT';
        if (minute === 90) return 'FT';
        return `${minute}'`;
    }
    
    getEventIconName(moment) {
        const iconMap = {
            'Goal': 'utility:success',
            'Yellow Card': 'utility:warning',
            'Red Card': 'utility:error',
            'Substitution': 'utility:switch'
        };
        return iconMap[moment.eventType] || 'utility:info';
    }
    
    getEventIconVariant(moment) {
        if (moment.eventType === 'Goal') return 'success';
        if (moment.eventType === 'Red Card') return 'error';
        if (moment.eventType === 'Yellow Card') return 'warning';
        return 'default';
    }
    
    isHomeTeamEvent(moment) {
        return moment.team?.id === this.homeTeamId;
    }
    
    isAwayTeamEvent(moment) {
        return moment.team?.id === this.awayTeamId;
    }
    
    get hasEvents() {
        return this.timelineEvents.length > 0;
    }
}

