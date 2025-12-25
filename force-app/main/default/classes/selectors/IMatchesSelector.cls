/**
 * @description Interface for Match__c Selector
 * Defines all query methods for Match__c data access
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IMatchesSelector extends fflib_ISObjectSelector {
    
    /**
     * @description Select matches by record IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Match__c records
     */
    List<Match__c> selectById(Set<Id> matchIds);
    
    /**
     * @description Select matches by ESPN Event IDs
     * @param espnEventIds Set of ESPN Event ID strings
     * @return List of Match__c records
     */
    List<Match__c> selectByESPNEventIds(Set<String> espnEventIds);
    
    /**
     * @description Select matches by Competition
     * @param competitionIds Set of Competition__c record IDs
     * @return List of Match__c records
     */
    List<Match__c> selectByCompetitionIds(Set<Id> competitionIds);
    
    /**
     * @description Select matches within a date range
     * @param startDate Start of date range
     * @param endDate End of date range
     * @return List of Match__c records
     */
    List<Match__c> selectByDateRange(Date startDate, Date endDate);
    
    /**
     * @description Select matches by team (home or away)
     * @param teamIds Set of Account (Team) record IDs
     * @return List of Match__c records
     */
    List<Match__c> selectByTeamIds(Set<Id> teamIds);
    
    /**
     * @description Select matches with full details including related records
     * @param matchIds Set of Match__c record IDs
     * @return List of Match__c records with related data
     */
    List<Match__c> selectByIdWithDetails(Set<Id> matchIds);
    
    /**
     * @description Select live/in-progress matches
     * @return List of in-progress Match__c records
     */
    List<Match__c> selectLiveMatches();
    
    /**
     * @description Select live fixtures (legacy method name for compatibility)
     * @return List of in-progress Match__c records
     */
    List<Match__c> selectLiveFixtures();
}

