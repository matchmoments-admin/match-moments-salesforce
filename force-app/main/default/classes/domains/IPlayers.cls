/**
 * @description Interface for Players (Contact) Domain
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IPlayers extends fflib_ISObjectDomain {
    void updateFromESPNData(Map<String, Object> espnPlayerData);
    void linkToTeam(Id teamId);
    void validatePosition();
}

