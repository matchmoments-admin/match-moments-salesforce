/**
 * @description Selector implementation for Competition__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class CompetitionsSelector extends fflib_SObjectSelector implements ICompetitionsSelector {
    
    public static ICompetitionsSelector newInstance() {
        return (ICompetitionsSelector) Application.Selector.newInstance(Competition__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Competition__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Competition__c.Id,
            Competition__c.Name,
            Competition__c.ESPN_League_ID__c,
            Competition__c.Sport__c,
            Competition__c.Competition_Type__c,
            Competition__c.Country__c,
            Competition__c.Season_Year__c,
            Competition__c.Season_Start_Date__c,
            Competition__c.Season_End_Date__c,
            Competition__c.Status__c,
            Competition__c.Logo_URL__c,
            Competition__c.Number_of_Teams__c,
            Competition__c.RecordTypeId
        };
    }
    
    public List<Competition__c> selectById(Set<Id> competitionIds) {
        return (List<Competition__c>) selectSObjectsById(competitionIds);
    }
    
    public List<Competition__c> selectByESPNLeagueIds(Set<String> espnLeagueIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ESPN_League_ID__c IN :espnLeagueIds');
        return (List<Competition__c>) Database.query(query.toSOQL());
    }
    
    public List<Competition__c> selectBySport(String sport) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Sport__c = :sport')
            .setOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Competition__c>) Database.query(query.toSOQL());
    }
    
    public List<Competition__c> selectActiveCompetitions() {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Status__c = \'Active\'')
            .setOrdering('Sport__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Competition__c>) Database.query(query.toSOQL());
    }
    
    public List<Competition__c> selectByIdWithFixtures(Set<Id> competitionIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('RecordType.DeveloperName')
            .setCondition('Id IN :competitionIds');
        
        // Subquery for fixtures
        query.subselectQuery('Fixtures__r')
            .selectField('Id')
            .selectField('Name')
            .selectField('ESPN_Event_ID__c')
            .selectField('Match_Date_Time__c')
            .selectField('Status__c')
            .selectField('Home_Team__c')
            .selectField('Away_Team__c')
            .setOrdering('Match_Date_Time__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Competition__c>) Database.query(query.toSOQL());
    }
}

