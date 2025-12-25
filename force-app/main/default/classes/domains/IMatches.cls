/**
 * @description Interface for Matches Domain
 * Defines business operations on Match__c records
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IMatches extends fflib_ISObjectDomain {
    
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
     * @description Set match status
     * @param status New status value
     */
    void setStatus(String status);
    
    /**
     * @description Mark matches as completed and determine winner
     */
    void markAsCompleted();
    
    /**
     * @description Validate that required fields are present
     */
    void validateRequiredFields();
    
    /**
     * @description Get records that have changed status
     * @param existingRecords Map of old record values
     * @return List of matches with status changes
     */
    List<Match__c> getStatusChangedRecords(Map<Id, Match__c> existingRecords);
}

