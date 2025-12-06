/**
 * @description Selector for Fixture_Participation__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class FixtureParticipationsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Fixture_Participation__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Fixture_Participation__c.Id,
            Fixture_Participation__c.Name,
            Fixture_Participation__c.Fixture__c,
            Fixture_Participation__c.Player__c,
            Fixture_Participation__c.Team__c
        };
    }
    
    public List<Fixture_Participation__c> selectById(Set<Id> ids) {
        return (List<Fixture_Participation__c>) selectSObjectsById(ids);
    }
}

