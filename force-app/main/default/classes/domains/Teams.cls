/**
 * @description Domain class for Account (Teams) business logic
 * NO SOQL, NO DML, NO UOW - operates on in-memory records only
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class Teams extends fflib_SObjectDomain implements ITeams {
    
    public static final String TYPE_TEAM = 'Team';
    
    public Teams(List<Account> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Teams((List<Account>) records);
        }
    }
    
    public static ITeams newInstance(List<Account> records) {
        return (ITeams) Application.Domain.newInstance(records);
    }
    
    public List<Account> getTeams() {
        return (List<Account>) getRecords();
    }
    
    /**
     * @description Update team data from ESPN response
     * @param espnTeamData Map of ESPN team data
     */
    public void updateFromESPNData(Map<String, Object> espnTeamData) {
        for (Account team : getTeams()) {
            if (espnTeamData.containsKey('id')) {
                team.ESPN_Team_ID__c = String.valueOf(espnTeamData.get('id'));
                team.ESPN_ID__c = String.valueOf(espnTeamData.get('id'));
            }
            if (espnTeamData.containsKey('abbreviation')) {
                team.Abbreviation__c = String.valueOf(espnTeamData.get('abbreviation'));
            }
            if (espnTeamData.containsKey('shortDisplayName')) {
                team.Team_Short_Name__c = String.valueOf(espnTeamData.get('shortDisplayName'));
            }
            if (espnTeamData.containsKey('logoUrl')) {
                team.Logo_Url__c = String.valueOf(espnTeamData.get('logoUrl'));
            }
            if (espnTeamData.containsKey('venue')) {
                Map<String, Object> venue = (Map<String, Object>) espnTeamData.get('venue');
                if (venue != null && venue.containsKey('fullName')) {
                    team.Venue_Name__c = String.valueOf(venue.get('fullName'));
                }
            }
        }
    }
    
    /**
     * @description Validate that accounts have Type = 'Team'
     */
    public void validateTeamType() {
        for (Account team : getTeams()) {
            if (team.Type != TYPE_TEAM) {
                team.addError('Account must have Type = "Team" to sync with ESPN');
            }
        }
    }
    
    /**
     * @description Set logo URL for all teams
     * @param logoUrl The logo URL to set
     */
    public void setLogoUrl(String logoUrl) {
        for (Account team : getTeams()) {
            team.Logo_Url__c = logoUrl;
        }
    }
    
    /**
     * @description Set venue name for all teams
     * @param venueName The venue name to set
     */
    public void setVenue(String venueName) {
        for (Account team : getTeams()) {
            team.Venue_Name__c = venueName;
        }
    }
}

