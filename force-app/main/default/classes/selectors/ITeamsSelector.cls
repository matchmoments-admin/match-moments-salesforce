/**
 * @description Interface for Account (Teams) Selector
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ITeamsSelector extends fflib_ISObjectSelector {
    List<Account> selectById(Set<Id> accountIds);
    List<Account> selectByESPNTeamIds(Set<String> espnTeamIds);
    List<Account> selectBySport(String sport);
    List<Account> selectTeamsWithType();
    Map<String, Id> selectESPNIdToAccountIdMap(Set<String> espnTeamIds);
}

