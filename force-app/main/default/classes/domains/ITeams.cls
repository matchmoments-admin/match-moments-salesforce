/**
 * @description Interface for Teams (Account) Domain
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ITeams extends fflib_ISObjectDomain {
    void updateFromESPNData(Map<String, Object> espnTeamData);
    void validateTeamType();
    void setLogoUrl(String logoUrl);
    void setVenue(String venueName);
}

