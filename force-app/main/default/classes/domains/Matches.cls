/**
 * @description Domain class for Match__c business logic
 * NO SOQL, NO DML, NO UOW - operates on in-memory records only
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class Matches extends fflib_SObjectDomain implements IMatches {
    
    // Status constants
    public static final String STATUS_SCHEDULED = 'Scheduled';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_POSTPONED = 'Postponed';
    public static final String STATUS_CANCELLED = 'Cancelled';
    
    /**
     * @description Constructor
     * @param records List of Match__c records
     */
    public Matches(List<Match__c> records) {
        super(records);
    }
    
    /**
     * @description Constructor class for fflib_Application.DomainFactory
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Matches((List<Match__c>) records);
        }
    }
    
    /**
     * @description Factory method to create new instance
     * @param records List of Match__c records
     * @return IMatches domain instance
     */
    public static IMatches newInstance(List<Match__c> records) {
        return (IMatches) Application.Domain.newInstance(records);
    }
    
    /**
     * @description Factory method to create instance from record IDs
     * @param matchIds Set of Match__c record IDs
     * @return IMatches domain instance
     */
    public static IMatches newInstance(Set<Id> matchIds) {
        return (IMatches) Application.Domain.newInstance(matchIds);
    }
    
    /**
     * @description Get records as List<Match__c>
     * @return List of Match__c records
     */
    public List<Match__c> getMatches() {
        return (List<Match__c>) getRecords();
    }
    
    // =========================================================================
    // DOMAIN VALIDATION (onValidate)
    // =========================================================================
    
    /**
     * @description Validate records on insert
     */
    public override void onValidate() {
        for (Match__c match : getMatches()) {
            // Home and Away teams are required
            if (match.Home_Team__c == null) {
                match.addError('Home Team is required');
            }
            if (match.Away_Team__c == null) {
                match.addError('Away Team is required');
            }
            // Teams must be different
            if (match.Home_Team__c != null && match.Home_Team__c == match.Away_Team__c) {
                match.addError('Home Team and Away Team cannot be the same');
            }
        }
    }
    
    /**
     * @description Validate records on update
     * @param existingRecords Map of existing record values
     */
    public override void onValidate(Map<Id, SObject> existingRecords) {
        for (Match__c match : getMatches()) {
            Match__c oldFixture = (Match__c) existingRecords.get(match.Id);
            
            // Cannot change teams after match has started
            if (oldFixture.Status__c != STATUS_SCHEDULED) {
                if (match.Home_Team__c != oldFixture.Home_Team__c) {
                    match.addError('Cannot change Home Team after match has started');
                }
                if (match.Away_Team__c != oldFixture.Away_Team__c) {
                    match.addError('Cannot change Away Team after match has started');
                }
            }
        }
    }
    
    // =========================================================================
    // DOMAIN BEHAVIOR (Business Logic)
    // =========================================================================
    
    /**
     * @description Update scores from ESPN data
     * @param homeScore Home team score
     * @param awayScore Away team score
     */
    public void updateScores(Integer homeScore, Integer awayScore) {
        for (Match__c match : getMatches()) {
            match.Home_Score_Final__c = homeScore;
            match.Away_Score_Final__c = awayScore;
        }
    }
    
    /**
     * @description Update sub-scores (AFL behinds, cricket wickets, etc.)
     * @param homeSubScore Home team sub-score
     * @param awaySubScore Away team sub-score
     */
    public void updateSubScores(Integer homeSubScore, Integer awaySubScore) {
        for (Match__c match : getMatches()) {
            match.Home_Sub_Score__c = homeSubScore;
            match.Away_Sub_Score__c = awaySubScore;
        }
    }
    
    /**
     * @description Set match status
     * @param status New status value
     */
    public void setStatus(String status) {
        for (Match__c match : getMatches()) {
            match.Status__c = status;
        }
    }
    
    /**
     * @description Mark matches as completed and determine winner
     */
    public void markAsCompleted() {
        for (Match__c match : getMatches()) {
            match.Status__c = STATUS_COMPLETED;
            // Winner is calculated by formula field, no need to set here
        }
    }
    
    /**
     * @description Validate that required fields are present
     */
    public void validateRequiredFields() {
        for (Match__c match : getMatches()) {
            if (match.Competition__c == null) {
                match.addError('Competition is required');
            }
            if (match.Match_Date_Time__c == null) {
                match.addError('Fixture Date/Time is required');
            }
        }
    }
    
    /**
     * @description Get records that have changed status
     * @param existingRecords Map of old record values
     * @return List of matches with status changes
     */
    public List<Match__c> getStatusChangedRecords(Map<Id, Match__c> existingRecords) {
        List<Match__c> changedRecords = new List<Match__c>();
        
        for (Match__c match : getMatches()) {
            Match__c oldFixture = existingRecords.get(match.Id);
            if (oldFixture != null && match.Status__c != oldFixture.Status__c) {
                changedRecords.add(match);
            }
        }
        
        return changedRecords;
    }
    
    // =========================================================================
    // STATIC HELPER METHODS
    // =========================================================================
    
    /**
     * @description Map ESPN status string to Match__c Status picklist
     * @param espnStatus ESPN status string
     * @return Match__c Status value
     */
    public static String mapESPNStatus(String espnStatus) {
        if (String.isBlank(espnStatus)) {
            return STATUS_SCHEDULED;
        }
        
        String status = espnStatus.toLowerCase();
        
        if (status.contains('final') || status.contains('ft') || status.contains('completed')) {
            return STATUS_COMPLETED;
        } else if (status.contains('live') || status.contains('in progress') || 
                   status.contains('1h') || status.contains('2h') || status.contains('halftime')) {
            return STATUS_IN_PROGRESS;
        } else if (status.contains('postponed')) {
            return STATUS_POSTPONED;
        } else if (status.contains('cancelled') || status.contains('canceled')) {
            return STATUS_CANCELLED;
        } else {
            return STATUS_SCHEDULED;
        }
    }
    
    /**
     * @description Parse ESPN date string to Datetime
     * @param espnDate ESPN date string (ISO 8601 format)
     * @return Datetime Parsed datetime or null
     */
    public static Datetime parseESPNDate(String espnDate) {
        if (String.isBlank(espnDate)) {
            return null;
        }
        
        try {
            // ESPN uses ISO 8601 format: 2025-01-15T19:45:00Z
            return (Datetime) JSON.deserialize('"' + espnDate + '"', Datetime.class);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse ESPN date: ' + espnDate);
            return null;
        }
    }
}

