/**
 * @description Selector for Fixture_Period__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class FixturePeriodsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Fixture_Period__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Fixture_Period__c.Id,
            Fixture_Period__c.Name,
            Fixture_Period__c.Fixture__c,
            Fixture_Period__c.Period_Type__c,
            Fixture_Period__c.Period_Number__c,
            Fixture_Period__c.Home_Score_Period__c,
            Fixture_Period__c.Away_Score_Period__c,
            Fixture_Period__c.Status__c
        };
    }
    
    public List<Fixture_Period__c> selectById(Set<Id> ids) {
        return (List<Fixture_Period__c>) selectSObjectsById(ids);
    }
    
    public List<Fixture_Period__c> selectByFixtureId(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Fixture__c IN :fixtureIds')
            .setOrdering('Period_Number__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Fixture_Period__c>) Database.query(query.toSOQL());
    }
}

