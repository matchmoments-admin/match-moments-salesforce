/**
 * @description Selector for Match_Moment__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchMomentsSelector extends fflib_SObjectSelector {
    
    public static MatchMomentsSelector newInstance() {
        return (MatchMomentsSelector) Application.Selector.newInstance(Match_Moment__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Match_Moment__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Match_Moment__c.Id,
            Match_Moment__c.Name,
            Match_Moment__c.Commentary__c,
            Match_Moment__c.Event_Type__c,
            Match_Moment__c.Event_Time__c,
            Match_Moment__c.Is_Shareable__c,
            Match_Moment__c.Public_URL__c,
            Match_Moment__c.Share_Count__c,
            Match_Moment__c.View_Count__c,
            Match_Moment__c.Viral_Score__c
        };
    }
    
    public List<Match_Moment__c> selectById(Set<Id> ids) {
        return (List<Match_Moment__c>) selectSObjectsById(ids);
    }
    
    public List<Match_Moment__c> selectShareableByFixture(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Commentary__r.Match__c IN :fixtureIds AND Is_Shareable__c = true')
            .setOrdering('Event_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Match_Moment__c>) Database.query(query.toSOQL());
    }
}

