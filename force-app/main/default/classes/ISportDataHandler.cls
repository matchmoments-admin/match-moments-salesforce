/**
 * @description Interface contract that every sport integration must follow
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * This interface enables polymorphic behavior - the same data structures
 * (Account, Match__c, Contact) behave differently based on sport type.
 */
public interface ISportDataHandler {
    
    /**
     * @description Returns the standardized Sport_Type__c value
     * @return String Sport type (e.g., 'Soccer', 'Cricket', 'AFL')
     */
    String getSportType();
    
    /**
     * @description Maps raw JSON from API to a Salesforce Match__c record
     * @param apiData Raw JSON data from ESPN API
     * @param competitionId Competition__c record ID
     * @return Match__c Mapped Match__c record (not yet inserted)
     */
    Match__c mapFixture(Map<String, Object> apiData, Id competitionId);
    
    /**
     * @description Maps raw JSON from API to a Salesforce Contact (Player)
     * @param apiData Raw JSON data from ESPN API
     * @param teamId Account (Team) record ID
     * @return Contact Mapped Contact record (not yet inserted)
     */
    Contact mapPlayer(Map<String, Object> apiData, Id teamId);
    
    /**
     * @description Calculates the generic 'Total Score' based on sport-specific rules
     * @param scoreData Score data from API (format varies by sport)
     * @return Decimal Total score (goals, points, runs, etc.)
     */
    Decimal calculateTotalScore(Map<String, Object> scoreData);
}

