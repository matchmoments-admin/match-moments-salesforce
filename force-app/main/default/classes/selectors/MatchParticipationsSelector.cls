/**
 * @description Selector for Match_Participation__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchParticipationsSelector extends fflib_SObjectSelector {
    
    public static MatchParticipationsSelector newInstance() {
        return (MatchParticipationsSelector) Application.Selector.newInstance(Match_Participation__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Match_Participation__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Match_Participation__c.Id,
            Match_Participation__c.Name,
            Match_Participation__c.Match__c,
            Match_Participation__c.Player__c,
            Match_Participation__c.Team__c
        };
    }
    
    public List<Match_Participation__c> selectById(Set<Id> ids) {
        return (List<Match_Participation__c>) selectSObjectsById(ids);
    }
    
    /**
     * @description Select participations by match IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Match_Participation__c records
     */
    public List<Match_Participation__c> selectByMatchIds(Set<Id> matchIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match__c IN :matchIds');
        return (List<Match_Participation__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select participations by match and team IDs
     * @param matchIds Set of Match__c record IDs
     * @param teamIds Set of Account (Team) record IDs
     * @return List of Match_Participation__c records
     */
    public List<Match_Participation__c> selectByMatchAndTeamIds(Set<Id> matchIds, Set<Id> teamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Match__c IN :matchIds AND Team__c IN :teamIds');
        return (List<Match_Participation__c>) Database.query(query.toSOQL());
    }
}

