public with sharing class AgentActionHelper {
    
    @InvocableMethod(label='Opportunity Stage'
                    description='Returns the current stage of an Opportunity when user asks for it. For example, user can say "what is the stage of opportunity with order number 12345?" or "get opportunity stage for order 12345"')
    public static List<String> getOpportunityStage(List<String> orderNumber) {
        
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE OrderNumber__c = :orderNumber[0] LIMIT 1];
        return new List<String> { opp.StageName };
    }
}