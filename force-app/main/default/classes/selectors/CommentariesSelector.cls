/**
 * @description Selector for Commentary__c
 * @deprecated This selector references the legacy Commentary__c object which has been superseded by Match_Moment__c.
 *             The Commentary__c.Fixture__c field should be updated to reference Match__c instead of the old Fixture__c object.
 *             Consider using MatchMomentsSelector for new development.
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

