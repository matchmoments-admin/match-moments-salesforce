/**
 * @description Interface contract that every sport integration must follow
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * This interface enables polymorphic behavior - the same data structures
 * (Account, Opportunity, Contact) behave differently based on sport type.
 */
public interface ISportDataHandler {
    
    /**
     * @description Returns the standardized Sport_Type__c value
     * @return String Sport type (e.g., 'Soccer', 'Cricket', 'AFL')
     */
    String getSportType();
    
    /**
     * @description Maps raw JSON from API to a Salesforce Opportunity (Fixture)
     * @param apiData Raw JSON data from ESPN API
     * @param leagueId Opportunity_Group__c record ID
     * @return Opportunity Mapped Opportunity record (not yet inserted)
     */
    Opportunity mapFixture(Map<String, Object> apiData, Id leagueId);
    
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

