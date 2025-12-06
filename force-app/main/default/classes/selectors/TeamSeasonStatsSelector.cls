/**
 * @description Selector for Team_Season_Stats__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class TeamSeasonStatsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Team_Season_Stats__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Team_Season_Stats__c.Id,
            Team_Season_Stats__c.Name,
            Team_Season_Stats__c.Team__c,
            Team_Season_Stats__c.Competition__c,
            Team_Season_Stats__c.Season_Year__c
        };
    }
    
    public List<Team_Season_Stats__c> selectById(Set<Id> ids) {
        return (List<Team_Season_Stats__c>) selectSObjectsById(ids);
    }
}

