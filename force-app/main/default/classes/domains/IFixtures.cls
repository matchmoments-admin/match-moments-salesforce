/**
 * @description Interface for Fixtures Domain
 * Defines business operations on Fixture__c records
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IFixtures extends fflib_ISObjectDomain {
    
    /**
     * @description Update scores from ESPN data
     * @param homeScore Home team score
     * @param awayScore Away team score
     */
    void updateScores(Integer homeScore, Integer awayScore);
    
    /**
     * @description Update sub-scores (AFL behinds, cricket wickets, etc.)
     * @param homeSubScore Home team sub-score
     * @param awaySubScore Away team sub-score
     */
    void updateSubScores(Integer homeSubScore, Integer awaySubScore);
    
    /**
     * @description Set fixture status
     * @param status New status value
     */
    void setStatus(String status);
    
    /**
     * @description Mark fixtures as completed and determine winner
     */
    void markAsCompleted();
    
    /**
     * @description Validate that required fields are present
     */
    void validateRequiredFields();
    
    /**
     * @description Get records that have changed status
     * @param existingRecords Map of old record values
     * @return List of fixtures with status changes
     */
    List<Fixture__c> getStatusChangedRecords(Map<Id, Fixture__c> existingRecords);
}

