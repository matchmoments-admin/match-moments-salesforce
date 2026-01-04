/**
 * @description Game Information component - displays venue, date, attendance, referee
 * Uses SLDS 2.1 description list pattern
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

export default class GameInformation extends LightningElement {
    @api recordId;
    
    @track matchData = {};
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
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
                this.isLoading = false;
            })
            .catch(error => {
                this.hasError = true;
                this.errorMessage = error.body?.message || 'Error loading match information';
                this.isLoading = false;
                console.error('Error loading match summary:', error);
            });
    }
    
    // Getters
    get venue() {
        return this.matchData.venue || 'TBD';
    }
    
    get formattedDate() {
        if (!this.matchData.matchDateTime) return 'TBD';
        const date = new Date(this.matchData.matchDateTime);
        return date.toLocaleDateString('en-US', { 
            weekday: 'long',
            year: 'numeric', 
            month: 'long', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            timeZoneName: 'short'
        });
    }
    
    get formattedTime() {
        if (!this.matchData.matchDateTime) return '';
        const date = new Date(this.matchData.matchDateTime);
        return date.toLocaleTimeString('en-US', { 
            hour: '2-digit',
            minute: '2-digit',
            timeZoneName: 'short'
        });
    }
    
    get attendance() {
        return this.matchData.attendance || 'N/A';
    }
    
    get referee() {
        return this.matchData.referee || 'TBD';
    }
    
    get competition() {
        return this.matchData.competition || {};
    }
    
    get location() {
        // Could be enhanced to include city/country if available
        return this.venue;
    }
    
    get hasData() {
        return !this.isLoading && !this.hasError && this.matchData.id;
    }
}

