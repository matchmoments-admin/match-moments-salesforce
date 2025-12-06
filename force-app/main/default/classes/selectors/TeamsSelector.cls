/**
 * @description Selector implementation for Account (Teams)
 * Filters to Type = 'Team' records only
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class TeamsSelector extends fflib_SObjectSelector implements ITeamsSelector {
    
    public static ITeamsSelector newInstance() {
        return (ITeamsSelector) Application.Selector.newInstance(Account.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Account.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Name,
            Account.Type,
            Account.Sport__c,
            Account.ESPN_ID__c,
            Account.ESPN_Team_ID__c,
            Account.Abbreviation__c,
            Account.Logo_Url__c,
            Account.Venue_Name__c,
            Account.Team_Short_Name__c,
            Account.Team_Primary_Color__c,
            Account.Stadium_Name__c,
            Account.Founded_Year__c,
            Account.Current_League_Rank__c
        };
    }
    
    public List<Account> selectById(Set<Id> accountIds) {
        return (List<Account>) selectSObjectsById(accountIds);
    }
    
    public List<Account> selectByESPNTeamIds(Set<String> espnTeamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ESPN_Team_ID__c IN :espnTeamIds AND Type = \'Team\'');
        return (List<Account>) Database.query(query.toSOQL());
    }
    
    public List<Account> selectBySport(String sport) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Sport__c = :sport AND Type = \'Team\'')
            .setOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Account>) Database.query(query.toSOQL());
    }
    
    public List<Account> selectTeamsWithType() {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Type = \'Team\'')
            .setOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Account>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Build a map of ESPN Team ID to Salesforce Account ID
     * Useful for bulk operations when linking fixtures to teams
     * @param espnTeamIds Set of ESPN Team ID strings
     * @return Map of ESPN Team ID to Salesforce Account ID
     */
    public Map<String, Id> selectESPNIdToAccountIdMap(Set<String> espnTeamIds) {
        Map<String, Id> resultMap = new Map<String, Id>();
        
        List<Account> teams = selectByESPNTeamIds(espnTeamIds);
        for (Account team : teams) {
            if (String.isNotBlank(team.ESPN_Team_ID__c)) {
                resultMap.put(team.ESPN_Team_ID__c, team.Id);
            }
        }
        
        return resultMap;
    }
}

