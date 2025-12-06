/**
 * @description Interface for Fixture__c Selector
 * Defines all query methods for Fixture__c data access
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IFixturesSelector extends fflib_ISObjectSelector {
    
    /**
     * @description Select fixtures by record IDs
     * @param fixtureIds Set of Fixture__c record IDs
     * @return List of Fixture__c records
     */
    List<Fixture__c> selectById(Set<Id> fixtureIds);
    
    /**
     * @description Select fixtures by ESPN Event IDs
     * @param espnEventIds Set of ESPN Event ID strings
     * @return List of Fixture__c records
     */
    List<Fixture__c> selectByESPNEventIds(Set<String> espnEventIds);
    
    /**
     * @description Select fixtures by Competition
     * @param competitionIds Set of Competition__c record IDs
     * @return List of Fixture__c records
     */
    List<Fixture__c> selectByCompetitionIds(Set<Id> competitionIds);
    
    /**
     * @description Select fixtures within a date range
     * @param startDate Start of date range
     * @param endDate End of date range
     * @return List of Fixture__c records
     */
    List<Fixture__c> selectByDateRange(Date startDate, Date endDate);
    
    /**
     * @description Select fixtures by team (home or away)
     * @param teamIds Set of Account (Team) record IDs
     * @return List of Fixture__c records
     */
    List<Fixture__c> selectByTeamIds(Set<Id> teamIds);
    
    /**
     * @description Select fixtures with full details including related records
     * @param fixtureIds Set of Fixture__c record IDs
     * @return List of Fixture__c records with related data
     */
    List<Fixture__c> selectByIdWithDetails(Set<Id> fixtureIds);
    
    /**
     * @description Select live/in-progress fixtures
     * @return List of in-progress Fixture__c records
     */
    List<Fixture__c> selectLiveFixtures();
}

