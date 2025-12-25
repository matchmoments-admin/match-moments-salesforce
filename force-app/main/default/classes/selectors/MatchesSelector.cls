/**
 * @description Selector implementation for Match__c
 * Data access layer - queries only, no business logic, no DML
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchesSelector extends fflib_SObjectSelector implements IMatchesSelector {
    
    /**
     * @description Factory method to create new instance
     * @return IMatchesSelector New selector instance
     */
    public static IMatchesSelector newInstance() {
        return (IMatchesSelector) Application.Selector.newInstance(Match__c.SObjectType);
    }
    
    /**
     * @description Define the SObject type for this selector
     * @return SObjectType for Match__c
     */
    public Schema.SObjectType getSObjectType() {
        return Match__c.SObjectType;
    }
    
    /**
     * @description Define the default fields to query
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Match__c.Id,
            Match__c.Name,
            Match__c.ESPN_Event_ID__c,
            Match__c.Competition__c,
            Match__c.Home_Team__c,
            Match__c.Away_Team__c,
            Match__c.Home_Score_Final__c,
            Match__c.Away_Score_Final__c,
            Match__c.Home_Sub_Score__c,
            Match__c.Away_Sub_Score__c,
            Match__c.Match_Date_Time__c,
            Match__c.Status__c,
            Match__c.Venue__c,
            Match__c.Attendance__c,
            Match__c.Broadcast_URL__c,
            Match__c.Current_Period__c,
            Match__c.Referee__c,
            Match__c.Match_Stats_JSON__c
        };
    }
    
    /**
     * @description Select matches by record IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Match__c records
     */
    public List<Match__c> selectById(Set<Id> matchIds) {
        return (List<Match__c>) selectSObjectsById(matchIds);
    }
    
    /**
     * @description Select matches by ESPN Event IDs
     * @param espnEventIds Set of ESPN Event ID strings
     * @return List of Match__c records
     */
    public List<Match__c> selectByESPNEventIds(Set<String> espnEventIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ESPN_Event_ID__c IN :espnEventIds');
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select matches by Competition
     * @param competitionIds Set of Competition__c record IDs
     * @return List of Match__c records
     */
    public List<Match__c> selectByCompetitionIds(Set<Id> competitionIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Competition__c IN :competitionIds')
            .setOrdering('Match_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select matches within a date range
     * @param startDate Start of date range
     * @param endDate End of date range
     * @return List of Match__c records
     */
    public List<Match__c> selectByDateRange(Date startDate, Date endDate) {
        Datetime startDateTime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateTime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));
        
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match_Date_Time__c >= :startDateTime AND Match_Date_Time__c <= :endDateTime')
            .setOrdering('Match_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select matches by team (home or away)
     * @param teamIds Set of Account (Team) record IDs
     * @return List of Match__c records
     */
    public List<Match__c> selectByTeamIds(Set<Id> teamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Home_Team__c IN :teamIds OR Away_Team__c IN :teamIds')
            .setOrdering('Match_Date_Time__c', fflib_QueryFactory.SortOrder.DESCENDING);
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select matches with full details including related records
     * @param matchIds Set of Match__c record IDs
     * @return List of Match__c records with related data
     */
    public List<Match__c> selectByIdWithDetails(Set<Id> matchIds) {
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
            .setCondition('Id IN :matchIds');
        
        // Add subquery for Match Periods
        fflib_QueryFactory periodsSubquery = query.subselectQuery('Match_Periods__r')
            .selectField('Id')
            .selectField('Name')
            .selectField('Period_Type__c')
            .selectField('Period_Number__c')
            .selectField('Home_Score_Period__c')
            .selectField('Away_Score_Period__c')
            .selectField('Status__c')
            .setOrdering('Period_Number__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select live/in-progress matches
     * @return List of in-progress Match__c records
     */
    public List<Match__c> selectLiveMatches() {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Competition__r.Name')
            .selectField('Competition__r.Sport__c')
            .selectField('Home_Team__r.Name')
            .selectField('Away_Team__r.Name')
            .setCondition('Status__c = \'In Progress\'')
            .setOrdering('Match_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Match__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select live fixtures (legacy method name for compatibility)
     * @return List of in-progress Match__c records
     */
    public List<Match__c> selectLiveFixtures() {
        return selectLiveMatches();
    }
}

