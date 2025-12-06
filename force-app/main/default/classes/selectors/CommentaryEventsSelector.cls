/**
 * @description Selector for Commentary_Event__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class CommentaryEventsSelector extends fflib_SObjectSelector {
    
    public static CommentaryEventsSelector newInstance() {
        return (CommentaryEventsSelector) Application.Selector.newInstance(Commentary_Event__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Commentary_Event__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Commentary_Event__c.Id,
            Commentary_Event__c.Name,
            Commentary_Event__c.Commentary__c,
            Commentary_Event__c.Event_Type__c,
            Commentary_Event__c.Event_Time__c,
            Commentary_Event__c.Is_Shareable__c,
            Commentary_Event__c.Public_URL__c,
            Commentary_Event__c.Share_Count__c,
            Commentary_Event__c.View_Count__c,
            Commentary_Event__c.Viral_Score__c
        };
    }
    
    public List<Commentary_Event__c> selectById(Set<Id> ids) {
        return (List<Commentary_Event__c>) selectSObjectsById(ids);
    }
    
    public List<Commentary_Event__c> selectShareableByFixture(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Commentary__r.Fixture__c IN :fixtureIds AND Is_Shareable__c = true')
            .setOrdering('Event_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Commentary_Event__c>) Database.query(query.toSOQL());
    }
}

