/**
 * @description Match Commentary component - chronological list of Match_Moment__c with filtering
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getMatchMoments from '@salesforce/apex/MatchSummaryController.getMatchMoments';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Name'
];

export default class MatchCommentary extends LightningElement {
    @api recordId;
    
    @track allMoments = [];
    @track filteredMoments = [];
    @track selectedEventType = 'all';
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    
    eventTypeOptions = [
        { label: 'All Events', value: 'all' },
        { label: 'Goals', value: 'Goal' },
        { label: 'Yellow Cards', value: 'Yellow Card' },
        { label: 'Red Cards', value: 'Red Card' },
        { label: 'Substitutions', value: 'Substitution' },
        { label: 'Other', value: 'other' }
    ];
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.loadMatchMoments();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match';
            this.isLoading = false;
        }
    }
    
    loadMatchMoments() {
        getMatchMoments({ matchId: this.recordId })
            .then(result => {
                // Add icon properties and formatted time to each moment
                const processedMoments = (result || []).map(moment => ({
                    ...moment,
                    iconName: this.getEventIconName(moment),
                    iconVariant: this.getEventIconVariant(moment),
                    formattedTime: this.formatTime(moment)
                }));
                this.allMoments = processedMoments;
                this.applyFilter();
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body?.message || 'Error loading match commentary';
                this.isLoading = false;
                console.error('Error loading match moments:', error);
            });
    }
    
    handleEventTypeChange(event) {
        this.selectedEventType = event.detail.value;
        this.applyFilter();
    }
    
    applyFilter() {
        if (this.selectedEventType === 'all') {
            this.filteredMoments = [...this.allMoments];
        } else if (this.selectedEventType === 'other') {
            this.filteredMoments = this.allMoments.filter(moment => 
                moment.eventType !== 'Goal' && 
                moment.eventType !== 'Yellow Card' && 
                moment.eventType !== 'Red Card' && 
                moment.eventType !== 'Substitution'
            );
        } else {
            this.filteredMoments = this.allMoments.filter(moment => 
                moment.eventType === this.selectedEventType
            );
        }
    }
    
    // Getters
    get eventIcon() {
        const iconMap = {
            'Goal': 'utility:success',
            'Penalty Goal': 'utility:success',
            'Yellow Card': 'utility:warning',
            'Red Card': 'utility:error',
            'Substitution': 'utility:switch',
            'Try': 'utility:success',
            'Conversion': 'utility:success',
            'Wicket': 'utility:success'
        };
        return iconMap[this.eventType] || 'utility:info';
    }
    
    getEventIconName(moment) {
        const iconMap = {
            'Goal': 'utility:success',
            'Penalty Goal': 'utility:success',
            'Yellow Card': 'utility:warning',
            'Red Card': 'utility:error',
            'Substitution': 'utility:switch',
            'Try': 'utility:success',
            'Conversion': 'utility:success',
            'Wicket': 'utility:success'
        };
        return iconMap[moment.eventType] || 'utility:info';
    }
    
    getEventIconVariant(moment) {
        if (moment.eventType === 'Goal' || moment.eventType === 'Penalty Goal') return 'success';
        if (moment.eventType === 'Red Card') return 'error';
        if (moment.eventType === 'Yellow Card') return 'warning';
        return 'default';
    }
    
    formatTime(moment) {
        const minute = moment.minute || 0;
        const second = moment.second || 0;
        if (second > 0) {
            return `${minute}'${second}"`;
        }
        return `${minute}'`;
    }
    
    get hasMoments() {
        return this.filteredMoments.length > 0;
    }
    
    get reverseOrderMoments() {
        // Return in reverse chronological order (most recent first)
        return [...this.filteredMoments].reverse();
    }
}

