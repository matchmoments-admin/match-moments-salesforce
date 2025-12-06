/**
 * @description Interface for Contact (Players) Selector
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IPlayersSelector extends fflib_ISObjectSelector {
    List<Contact> selectById(Set<Id> contactIds);
    List<Contact> selectByTeamIds(Set<Id> teamIds);
    List<Contact> selectByESPNPlayerIds(Set<String> espnPlayerIds);
    List<Contact> selectByIdWithTeam(Set<Id> contactIds);
}

