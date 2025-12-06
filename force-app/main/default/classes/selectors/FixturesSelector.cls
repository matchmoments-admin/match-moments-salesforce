/**
 * @description Selector implementation for Fixture__c
 * Data access layer - queries only, no business logic, no DML
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class FixturesSelector extends fflib_SObjectSelector implements IFixturesSelector {
    
    /**
     * @description Factory method to create new instance
     * @return IFixturesSelector New selector instance
     */
    public static IFixturesSelector newInstance() {
        return (IFixturesSelector) Application.Selector.newInstance(Fixture__c.SObjectType);
    }
    
    /**
     * @description Define the SObject type for this selector
     * @return SObjectType for Fixture__c
     */
    public Schema.SObjectType getSObjectType() {
        return Fixture__c.SObjectType;
    }
    
    /**
     * @description Define the default fields to query
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Fixture__c.Id,
            Fixture__c.Name,
            Fixture__c.ESPN_Event_ID__c,
            Fixture__c.Competition__c,
            Fixture__c.Home_Team__c,
            Fixture__c.Away_Team__c,
            Fixture__c.Home_Score_Final__c,
            Fixture__c.Away_Score_Final__c,
            Fixture__c.Home_Sub_Score__c,
            Fixture__c.Away_Sub_Score__c,
            Fixture__c.Fixture_Date_Time__c,
            Fixture__c.Status__c,
            Fixture__c.Venue__c,
            Fixture__c.Attendance__c,
            Fixture__c.Broadcast_URL__c,
            Fixture__c.Current_Period__c,
            Fixture__c.Referee__c,
            Fixture__c.Fixture_Stats_JSON__c,
            Fixture__c.RecordTypeId
        };
    }
    
    /**
     * @description Select fixtures by record IDs
     * @param fixtureIds Set of Fixture__c record IDs
     * @return List of Fixture__c records
     */
    public List<Fixture__c> selectById(Set<Id> fixtureIds) {
        return (List<Fixture__c>) selectSObjectsById(fixtureIds);
    }
    
    /**
     * @description Select fixtures by ESPN Event IDs
     * @param espnEventIds Set of ESPN Event ID strings
     * @return List of Fixture__c records
     */
    public List<Fixture__c> selectByESPNEventIds(Set<String> espnEventIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ESPN_Event_ID__c IN :espnEventIds');
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select fixtures by Competition
     * @param competitionIds Set of Competition__c record IDs
     * @return List of Fixture__c records
     */
    public List<Fixture__c> selectByCompetitionIds(Set<Id> competitionIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Competition__c IN :competitionIds')
            .setOrdering('Fixture_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select fixtures within a date range
     * @param startDate Start of date range
     * @param endDate End of date range
     * @return List of Fixture__c records
     */
    public List<Fixture__c> selectByDateRange(Date startDate, Date endDate) {
        Datetime startDateTime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateTime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));
        
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Fixture_Date_Time__c >= :startDateTime AND Fixture_Date_Time__c <= :endDateTime')
            .setOrdering('Fixture_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select fixtures by team (home or away)
     * @param teamIds Set of Account (Team) record IDs
     * @return List of Fixture__c records
     */
    public List<Fixture__c> selectByTeamIds(Set<Id> teamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Home_Team__c IN :teamIds OR Away_Team__c IN :teamIds')
            .setOrdering('Fixture_Date_Time__c', fflib_QueryFactory.SortOrder.DESCENDING);
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select fixtures with full details including related records
     * @param fixtureIds Set of Fixture__c record IDs
     * @return List of Fixture__c records with related data
     */
    public List<Fixture__c> selectByIdWithDetails(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Competition__r.Name')
            .selectField('Competition__r.Sport__c')
            .selectField('Competition__r.ESPN_League_ID__c')
            .selectField('Home_Team__r.Name')
            .selectField('Home_Team__r.ESPN_Team_ID__c')
            .selectField('Home_Team__r.Logo_Url__c')
            .selectField('Away_Team__r.Name')
            .selectField('Away_Team__r.ESPN_Team_ID__c')
            .selectField('Away_Team__r.Logo_Url__c')
            .selectField('Current_Period__r.Name')
            .selectField('Current_Period__r.Period_Type__c')
            .selectField('Referee__r.Name')
            .selectField('RecordType.DeveloperName')
            .setCondition('Id IN :fixtureIds');
        
        // Add subquery for Fixture Periods
        fflib_QueryFactory periodsSubquery = query.subselectQuery('Fixture_Periods__r')
            .selectField('Id')
            .selectField('Name')
            .selectField('Period_Type__c')
            .selectField('Period_Number__c')
            .selectField('Home_Score_Period__c')
            .selectField('Away_Score_Period__c')
            .selectField('Status__c')
            .setOrdering('Period_Number__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select live/in-progress fixtures
     * @return List of in-progress Fixture__c records
     */
    public List<Fixture__c> selectLiveFixtures() {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Competition__r.Name')
            .selectField('Competition__r.Sport__c')
            .selectField('Home_Team__r.Name')
            .selectField('Away_Team__r.Name')
            .setCondition('Status__c = \'In Progress\'')
            .setOrdering('Fixture_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Fixture__c>) Database.query(query.toSOQL());
    }
}

