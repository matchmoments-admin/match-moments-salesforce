/**
 * @description Selector for Commentary__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class CommentariesSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Commentary__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Commentary__c.Id,
            Commentary__c.Name,
            Commentary__c.Fixture__c,
            Commentary__c.Goals_Home__c,
            Commentary__c.Goals_Away__c
        };
    }
    
    public List<Commentary__c> selectById(Set<Id> ids) {
        return (List<Commentary__c>) selectSObjectsById(ids);
    }
}

