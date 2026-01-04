/**
 * @description League Table component - sortable standings table from Team_Season_Stats__c
 * Uses SLDS 2.1 design patterns
 * @author Brendan Milton
 * @date 2026-01-04
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMatchSummary from '@salesforce/apex/MatchSummaryController.getMatchSummary';
import getLeagueTable from '@salesforce/apex/MatchSummaryController.getLeagueTable';
import MATCH_COMPETITION_FIELD from '@salesforce/schema/Match__c.Competition__c';

const FIELDS = [
    'Match__c.Id',
    'Match__c.Competition__c'
];

export default class LeagueTable extends LightningElement {
    @api recordId;
    
    @track matchData = {};
    @track tableData = [];
    @track sortedTableData = [];
    @track sortColumn = 'position';
    @track sortDirection = 'asc';
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track recordData;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.recordData = data;
            this.loadData();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading match';
            this.isLoading = false;
        }
    }
    
    loadData() {
        const compId = this.getCompetitionId();
        Promise.all([
            getMatchSummary({ matchId: this.recordId }),
            compId ? getLeagueTable({ 
                competitionId: compId,
                seasonYear: null // Will use current season
            }) : Promise.resolve([])
        ])
        .then(([summary, table]) => {
            this.matchData = summary.match || {};
            // Add formatted goal difference and current match team class to each row
            const processedTable = (table || []).map(row => ({
                ...row,
                formattedGoalDifference: this.formatGoalDifference(row.goalDifference),
                teamClass: this.isCurrentMatchTeam(row.team?.id) ? 'slds-text-bold' : ''
            }));
            this.tableData = processedTable;
            this.sortedTableData = [...this.tableData];
            this.applySorting();
            this.isLoading = false;
        })
        .catch(error => {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading league table';
            this.isLoading = false;
            console.error('Error loading league table:', error);
        });
    }
    
    getCompetitionId() {
        return getFieldValue(this.recordData, MATCH_COMPETITION_FIELD);
    }
    
    handleSort(event) {
        const column = event.currentTarget.dataset.column;
        if (this.sortColumn === column) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortColumn = column;
            this.sortDirection = 'asc';
        }
        this.applySorting();
    }
    
    applySorting() {
        this.sortedTableData = [...this.tableData].sort((a, b) => {
            let aValue = a[this.sortColumn];
            let bValue = b[this.sortColumn];
            
            // Handle null values
            if (aValue == null) aValue = 0;
            if (bValue == null) bValue = 0;
            
            // Numeric comparison
            if (typeof aValue === 'number' && typeof bValue === 'number') {
                return this.sortDirection === 'asc' ? aValue - bValue : bValue - aValue;
            }
            
            // String comparison
            const aStr = String(aValue).toLowerCase();
            const bStr = String(bValue).toLowerCase();
            if (this.sortDirection === 'asc') {
                return aStr < bStr ? -1 : aStr > bStr ? 1 : 0;
            } else {
                return aStr > bStr ? -1 : aStr < bStr ? 1 : 0;
            }
        });
    }
    
    // Getters
    get homeTeamId() {
        return this.matchData.homeTeam?.id;
    }
    
    get awayTeamId() {
        return this.matchData.awayTeam?.id;
    }
    
    isCurrentMatchTeam(teamId) {
        return teamId === this.homeTeamId || teamId === this.awayTeamId;
    }
    
    get sortIcon() {
        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }
    
    formatGoalDifference(gd) {
        if (gd == null) return '0';
        return gd > 0 ? `+${gd}` : String(gd);
    }
    
    get hasTableData() {
        return this.sortedTableData.length > 0;
    }
    
    get isPositionSort() {
        return this.sortColumn === 'position';
    }
    
    get isTeamSort() {
        return this.sortColumn === 'team';
    }
    
    get isMatchesPlayedSort() {
        return this.sortColumn === 'matchesPlayed';
    }
    
    get isWinsSort() {
        return this.sortColumn === 'wins';
    }
    
    get isDrawsSort() {
        return this.sortColumn === 'draws';
    }
    
    get isLossesSort() {
        return this.sortColumn === 'losses';
    }
    
    get isGoalDifferenceSort() {
        return this.sortColumn === 'goalDifference';
    }
    
    get isPointsSort() {
        return this.sortColumn === 'points';
    }
}

