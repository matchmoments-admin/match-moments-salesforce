/**
 * @description Selector for Player_Season_Stats__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class PlayerSeasonStatsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Player_Season_Stats__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Player_Season_Stats__c.Id,
            Player_Season_Stats__c.Name,
            Player_Season_Stats__c.Player__c,
            Player_Season_Stats__c.Competition__c,
            Player_Season_Stats__c.Season_Year__c
        };
    }
    
    public List<Player_Season_Stats__c> selectById(Set<Id> ids) {
        return (List<Player_Season_Stats__c>) selectSObjectsById(ids);
    }
}

