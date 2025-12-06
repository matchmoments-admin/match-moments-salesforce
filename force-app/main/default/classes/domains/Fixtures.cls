/**
 * @description Domain class for Fixture__c business logic
 * NO SOQL, NO DML, NO UOW - operates on in-memory records only
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class Fixtures extends fflib_SObjectDomain implements IFixtures {
    
    // Status constants
    public static final String STATUS_SCHEDULED = 'Scheduled';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_POSTPONED = 'Postponed';
    public static final String STATUS_CANCELLED = 'Cancelled';
    
    /**
     * @description Constructor
     * @param records List of Fixture__c records
     */
    public Fixtures(List<Fixture__c> records) {
        super(records);
    }
    
    /**
     * @description Constructor class for fflib_Application.DomainFactory
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Fixtures((List<Fixture__c>) records);
        }
    }
    
    /**
     * @description Factory method to create new instance
     * @param records List of Fixture__c records
     * @return IFixtures domain instance
     */
    public static IFixtures newInstance(List<Fixture__c> records) {
        return (IFixtures) Application.Domain.newInstance(records);
    }
    
    /**
     * @description Factory method to create instance from record IDs
     * @param fixtureIds Set of Fixture__c record IDs
     * @return IFixtures domain instance
     */
    public static IFixtures newInstance(Set<Id> fixtureIds) {
        return (IFixtures) Application.Domain.newInstance(fixtureIds);
    }
    
    /**
     * @description Get records as List<Fixture__c>
     * @return List of Fixture__c records
     */
    public List<Fixture__c> getFixtures() {
        return (List<Fixture__c>) getRecords();
    }
    
    // =========================================================================
    // DOMAIN VALIDATION (onValidate)
    // =========================================================================
    
    /**
     * @description Validate records on insert
     */
    public override void onValidate() {
        for (Fixture__c fixture : getFixtures()) {
            // Home and Away teams are required
            if (fixture.Home_Team__c == null) {
                fixture.addError('Home Team is required');
            }
            if (fixture.Away_Team__c == null) {
                fixture.addError('Away Team is required');
            }
            // Teams must be different
            if (fixture.Home_Team__c != null && fixture.Home_Team__c == fixture.Away_Team__c) {
                fixture.addError('Home Team and Away Team cannot be the same');
            }
        }
    }
    
    /**
     * @description Validate records on update
     * @param existingRecords Map of existing record values
     */
    public override void onValidate(Map<Id, SObject> existingRecords) {
        for (Fixture__c fixture : getFixtures()) {
            Fixture__c oldFixture = (Fixture__c) existingRecords.get(fixture.Id);
            
            // Cannot change teams after fixture has started
            if (oldFixture.Status__c != STATUS_SCHEDULED) {
                if (fixture.Home_Team__c != oldFixture.Home_Team__c) {
                    fixture.addError('Cannot change Home Team after fixture has started');
                }
                if (fixture.Away_Team__c != oldFixture.Away_Team__c) {
                    fixture.addError('Cannot change Away Team after fixture has started');
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
        for (Fixture__c fixture : getFixtures()) {
            fixture.Home_Score_Final__c = homeScore;
            fixture.Away_Score_Final__c = awayScore;
        }
    }
    
    /**
     * @description Update sub-scores (AFL behinds, cricket wickets, etc.)
     * @param homeSubScore Home team sub-score
     * @param awaySubScore Away team sub-score
     */
    public void updateSubScores(Integer homeSubScore, Integer awaySubScore) {
        for (Fixture__c fixture : getFixtures()) {
            fixture.Home_Sub_Score__c = homeSubScore;
            fixture.Away_Sub_Score__c = awaySubScore;
        }
    }
    
    /**
     * @description Set fixture status
     * @param status New status value
     */
    public void setStatus(String status) {
        for (Fixture__c fixture : getFixtures()) {
            fixture.Status__c = status;
        }
    }
    
    /**
     * @description Mark fixtures as completed and determine winner
     */
    public void markAsCompleted() {
        for (Fixture__c fixture : getFixtures()) {
            fixture.Status__c = STATUS_COMPLETED;
            // Winner is calculated by formula field, no need to set here
        }
    }
    
    /**
     * @description Validate that required fields are present
     */
    public void validateRequiredFields() {
        for (Fixture__c fixture : getFixtures()) {
            if (fixture.Competition__c == null) {
                fixture.addError('Competition is required');
            }
            if (fixture.Fixture_Date_Time__c == null) {
                fixture.addError('Fixture Date/Time is required');
            }
        }
    }
    
    /**
     * @description Get records that have changed status
     * @param existingRecords Map of old record values
     * @return List of fixtures with status changes
     */
    public List<Fixture__c> getStatusChangedRecords(Map<Id, Fixture__c> existingRecords) {
        List<Fixture__c> changedRecords = new List<Fixture__c>();
        
        for (Fixture__c fixture : getFixtures()) {
            Fixture__c oldFixture = existingRecords.get(fixture.Id);
            if (oldFixture != null && fixture.Status__c != oldFixture.Status__c) {
                changedRecords.add(fixture);
            }
        }
        
        return changedRecords;
    }
    
    // =========================================================================
    // STATIC HELPER METHODS
    // =========================================================================
    
    /**
     * @description Map ESPN status string to Fixture__c Status picklist
     * @param espnStatus ESPN status string
     * @return Fixture__c Status value
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

