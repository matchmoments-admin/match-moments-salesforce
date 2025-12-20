/**
 * @description Parser class for ESPN API JSON responses
 * Transforms ESPN data into Salesforce records
 * @author Brendan Milton
 * @date 2025-12-20
 */
public with sharing class ESPNDataParser {
    
    /**
     * @description Parse teams response into Account records
     * @param response ESPNTeamsResponse from ESPNHttpService
     * @return List<Account> Team accounts ready for upsert
     */
    public static List<Account> parseTeamsToAccounts(ESPNHttpService.ESPNTeamsResponse response) {
        List<Account> accounts = new List<Account>();
        
        if (response == null || response.teams == null || !response.success) {
            System.debug('Invalid teams response');
            return accounts;
        }
        
        for (ESPNHttpService.ESPNTeam team : response.teams) {
            Account acc = new Account();
            acc.Name = team.name;
            acc.ESPN_Team_ID__c = team.id;
            acc.Team_Short_Name__c = team.abbreviation;
            acc.Team_Logo_URL__c = team.logoUrl;
            acc.Stadium_Name__c = team.venueName;
            acc.Abbreviation__c = team.abbreviation;
            
            accounts.add(acc);
        }
        
        System.debug('Parsed ' + accounts.size() + ' teams into Account records');
        return accounts;
    }
    
    /**
     * @description Parse roster response into Contact records
     * @param response ESPNRosterResponse from ESPNHttpService
     * @param teamId Salesforce Account ID of the team
     * @return List<Contact> Player contacts ready for upsert
     */
    public static List<Contact> parseRosterToContacts(ESPNHttpService.ESPNRosterResponse response, Id teamId) {
        List<Contact> contacts = new List<Contact>();
        
        if (response == null || response.athletes == null || !response.success) {
            System.debug('Invalid roster response');
            return contacts;
        }
        
        for (ESPNHttpService.ESPNAthlete athlete : response.athletes) {
            Contact con = new Contact();
            con.AccountId = teamId;
            con.ESPN_Player_ID__c = athlete.id;
            
            // Parse name
            if (String.isNotBlank(athlete.firstName)) {
                con.FirstName = athlete.firstName;
            }
            if (String.isNotBlank(athlete.lastName)) {
                con.LastName = athlete.lastName;
            }
            
            // If firstName/lastName not available, parse from displayName
            if (String.isBlank(con.LastName) && String.isNotBlank(athlete.displayName)) {
                List<String> nameParts = athlete.displayName.split(' ', 2);
                con.FirstName = nameParts.size() > 0 ? nameParts[0] : athlete.displayName;
                con.LastName = nameParts.size() > 1 ? nameParts[1] : 'Player';
            }
            
            // Jersey and position
            if (String.isNotBlank(athlete.jersey)) {
                try {
                    con.Jersey_Number__c = Decimal.valueOf(athlete.jersey);
                } catch (Exception e) {
                    System.debug('Failed to parse jersey number: ' + athlete.jersey);
                }
            }
            con.Position__c = athlete.position;
            con.Profile_Image_URL__c = athlete.headshotUrl;
            
            contacts.add(con);
        }
        
        System.debug('Parsed ' + contacts.size() + ' players into Contact records');
        return contacts;
    }
    
    /**
     * @description Parse scoreboard response into Fixture__c records
     * @param response ESPNScoreboardResponse from ESPNHttpService
     * @param competitionId Salesforce Competition__c ID
     * @return List<Fixture__c> Fixture records ready for upsert
     */
    public static List<Fixture__c> parseScoreboardToFixtures(ESPNHttpService.ESPNScoreboardResponse response, Id competitionId) {
        List<Fixture__c> fixtures = new List<Fixture__c>();
        
        if (response == null || response.events == null || !response.success) {
            System.debug('Invalid scoreboard response');
            return fixtures;
        }
        
        // Build team ID map (ESPN ID -> Salesforce ID)
        Map<String, Id> teamIdMap = buildTeamIdMap();
        
        for (ESPNHttpService.ESPNEvent event : response.events) {
            Fixture__c fixture = new Fixture__c();
            
            fixture.ESPN_Event_ID__c = event.id;
            // Name field is auto-generated, don't set it
            fixture.Competition__c = competitionId;
            fixture.Status__c = event.status;
            fixture.Venue__c = event.venueName;
            
            // Parse date
            if (String.isNotBlank(event.eventDate)) {
                fixture.Fixture_Date_Time__c = parseESPNDateTime(event.eventDate);
            }
            
            // Map teams
            if (teamIdMap.containsKey(event.homeTeamId)) {
                fixture.Home_Team__c = teamIdMap.get(event.homeTeamId);
            }
            if (teamIdMap.containsKey(event.awayTeamId)) {
                fixture.Away_Team__c = teamIdMap.get(event.awayTeamId);
            }
            
            // Parse scores
            if (String.isNotBlank(event.homeScore)) {
                try {
                    fixture.Home_Score_Final__c = Decimal.valueOf(event.homeScore);
                } catch (Exception e) {
                    System.debug('Failed to parse home score: ' + event.homeScore);
                }
            }
            if (String.isNotBlank(event.awayScore)) {
                try {
                    fixture.Away_Score_Final__c = Decimal.valueOf(event.awayScore);
                } catch (Exception e) {
                    System.debug('Failed to parse away score: ' + event.awayScore);
                }
            }
            
            fixtures.add(fixture);
        }
        
        System.debug('Parsed ' + fixtures.size() + ' fixtures into Fixture__c records');
        return fixtures;
    }
    
    /**
     * @description Parse live feed response to extract periods
     * @param response ESPNLiveFeedResponse from ESPNHttpService
     * @param fixtureId Salesforce Fixture__c ID
     * @return List<Fixture_Period__c> Period records ready for insert
     */
    public static List<Fixture_Period__c> parseLiveFeedToPeriods(ESPNHttpService.ESPNLiveFeedResponse response, Id fixtureId) {
        List<Fixture_Period__c> periods = new List<Fixture_Period__c>();
        
        if (response == null || !response.success) {
            System.debug('Invalid live feed response');
            return periods;
        }
        
        // Note: ESPN live feed doesn't always provide period-by-period scores
        // This would need to be enhanced based on actual API response structure
        // For now, we'll create a placeholder implementation
        
        System.debug('Period parsing not fully implemented - requires actual ESPN period data structure');
        return periods;
    }
    
    // ========================================
    // HELPER METHODS
    // ========================================
    
    /**
     * @description Build map of ESPN Team ID to Salesforce Account ID
     * @return Map<String, Id> ESPN Team ID -> Salesforce Account ID
     */
    private static Map<String, Id> buildTeamIdMap() {
        Map<String, Id> teamMap = new Map<String, Id>();
        
        for (Account team : [SELECT Id, ESPN_Team_ID__c 
                             FROM Account 
                             WHERE ESPN_Team_ID__c != null]) {
            teamMap.put(team.ESPN_Team_ID__c, team.Id);
        }
        
        System.debug('Built team ID map with ' + teamMap.size() + ' teams');
        return teamMap;
    }
    
    /**
     * @description Parse ESPN datetime string to Salesforce DateTime
     * @param espnDate ESPN date string (ISO 8601 format)
     * @return DateTime Salesforce DateTime object
     */
    private static DateTime parseESPNDateTime(String espnDate) {
        if (String.isBlank(espnDate)) {
            return null;
        }
        
        try {
            // ESPN format: 2024-12-20T19:00Z or 2024-12-20T19:00:00Z
            String cleaned = espnDate.replace('T', ' ').replace('Z', '');
            return DateTime.valueOf(cleaned);
        } catch (Exception e) {
            System.debug('Failed to parse ESPN date: ' + espnDate + ' - ' + e.getMessage());
            return null;
        }
    }
}

