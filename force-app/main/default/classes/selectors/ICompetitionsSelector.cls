/**
 * @description Interface for Competition__c Selector
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ICompetitionsSelector extends fflib_ISObjectSelector {
    List<Competition__c> selectById(Set<Id> competitionIds);
    List<Competition__c> selectByESPNLeagueIds(Set<String> espnLeagueIds);
    List<Competition__c> selectBySport(String sport);
    List<Competition__c> selectActiveCompetitions();
    List<Competition__c> selectByIdWithFixtures(Set<Id> competitionIds);
}

