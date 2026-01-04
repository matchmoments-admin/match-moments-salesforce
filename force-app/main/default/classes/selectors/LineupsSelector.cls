/**
 * @description Selector for Lineup__c
 * @author Brendan Milton
 * @date 2025-12-31
 */
public inherited sharing class LineupsSelector extends fflib_SObjectSelector {
    
    public static LineupsSelector newInstance() {
        return (LineupsSelector) Application.Selector.newInstance(Lineup__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Lineup__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Lineup__c.Id,
            Lineup__c.Name,
            Lineup__c.Match__c,
            Lineup__c.Team__c,
            Lineup__c.Formation__c,
            Lineup__c.Starting_XI_Count__c,
            Lineup__c.Captain__c,
            Lineup__c.Lineup_JSON__c
        };
    }
    
    public List<Lineup__c> selectById(Set<Id> ids) {
        return (List<Lineup__c>) selectSObjectsById(ids);
    }
    
    /**
     * @description Select lineups by match IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Lineup__c records
     */
    public List<Lineup__c> selectByMatchIds(Set<Id> matchIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match__c IN :matchIds');
        return (List<Lineup__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select lineups by match and team IDs
     * @param matchIds Set of Match__c record IDs
     * @param teamIds Set of Account (Team) record IDs
     * @return Map of Match__c Id -> Team__c Id -> Lineup__c
     */
    public Map<Id, Map<Id, Lineup__c>> selectByMatchAndTeamIds(Set<Id> matchIds, Set<Id> teamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match__c IN :matchIds AND Team__c IN :teamIds');
        
        List<Lineup__c> lineups = (List<Lineup__c>) Database.query(query.toSOQL());
        
        Map<Id, Map<Id, Lineup__c>> result = new Map<Id, Map<Id, Lineup__c>>();
        for (Lineup__c lineup : lineups) {
            if (!result.containsKey(lineup.Match__c)) {
                result.put(lineup.Match__c, new Map<Id, Lineup__c>());
            }
            result.get(lineup.Match__c).put(lineup.Team__c, lineup);
        }
        
        return result;
    }
}

