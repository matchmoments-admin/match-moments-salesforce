/**
 * @description Selector for Match_Participation__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchParticipationsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Match_Participation__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Match_Participation__c.Id,
            Match_Participation__c.Name,
            Match_Participation__c.Match__c,
            Match_Participation__c.Player__c,
            Match_Participation__c.Team__c
        };
    }
    
    public List<Match_Participation__c> selectById(Set<Id> ids) {
        return (List<Match_Participation__c>) selectSObjectsById(ids);
    }
}

