/**
 * @description Selector for Social_Engagement__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class SocialEngagementsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Social_Engagement__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Social_Engagement__c.Id,
            Social_Engagement__c.Name,
            Social_Engagement__c.Commentary_Event__c,
            Social_Engagement__c.Platform__c,
            Social_Engagement__c.Engagement_Type__c
        };
    }
    
    public List<Social_Engagement__c> selectById(Set<Id> ids) {
        return (List<Social_Engagement__c>) selectSObjectsById(ids);
    }
}

