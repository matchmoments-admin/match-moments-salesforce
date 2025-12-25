/**
 * @description Selector for Match_Period__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchPeriodsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Match_Period__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Match_Period__c.Id,
            Match_Period__c.Name,
            Match_Period__c.Match__c,
            Match_Period__c.Period_Type__c,
            Match_Period__c.Period_Number__c,
            Match_Period__c.Home_Score_Period__c,
            Match_Period__c.Away_Score_Period__c,
            Match_Period__c.Status__c
        };
    }
    
    public List<Match_Period__c> selectById(Set<Id> ids) {
        return (List<Match_Period__c>) selectSObjectsById(ids);
    }
    
    public List<Match_Period__c> selectByFixtureId(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match__c IN :fixtureIds')
            .setOrdering('Period_Number__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Match_Period__c>) Database.query(query.toSOQL());
    }
}

