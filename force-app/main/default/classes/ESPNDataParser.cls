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
     * @param leagueCode ESPN league code (e.g., 'eng.1', 'usa.nwsl') to populate League__c field
     * @return List<Account> Team accounts ready for upsert
     */
    public static List<Account> parseTeamsToAccounts(ESPNHttpService.ESPNTeamsResponse response, String leagueCode) {
        List<Account> accounts = new List<Account>();
        
        if (response == null || response.teams == null || !response.success) {
            System.debug('Invalid teams response');
            return accounts;
        }
        
        for (ESPNHttpService.ESPNTeam team : response.teams) {
            Account acc = new Account();
            acc.Name = team.name;
            acc.ESPN_Team_ID__c = team.id;
            acc.Abbreviation__c = team.abbreviation;
            acc.Logo_Url__c = team.logoUrl;
            acc.Venue_Name__c = team.venueName;
            acc.League__c = leagueCode;
            
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
     * @description Parse scoreboard response into Match__c records
     * @param response ESPNScoreboardResponse from ESPNHttpService
     * @param competitionId Salesforce Competition__c ID
     * @return List<Match__c> Fixture records ready for upsert
     */
    public static List<Match__c> parseScoreboardToFixtures(ESPNHttpService.ESPNScoreboardResponse response, Id competitionId) {
        List<Match__c> fixtures = new List<Match__c>();
        
        if (response == null || response.events == null || !response.success) {
            System.debug('Invalid scoreboard response');
            return fixtures;
        }
        
        // Build team ID map (ESPN ID -> Salesforce ID)
        Map<String, Id> teamIdMap = buildTeamIdMap();
        
        for (ESPNHttpService.ESPNEvent event : response.events) {
            Match__c fixture = new Match__c();
            
            fixture.ESPN_Event_ID__c = event.id;
            // Name field is auto-generated, don't set it
            fixture.Competition__c = competitionId;
            fixture.Status__c = mapESPNStatusToSalesforce(event.status);
            fixture.Venue__c = event.venueName;
            
            // Parse date
            if (String.isNotBlank(event.eventDate)) {
                fixture.Match_Date_Time__c = parseESPNDateTime(event.eventDate);
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
        
        System.debug('Parsed ' + fixtures.size() + ' fixtures into Match__c records');
        return fixtures;
    }
    
    /**
     * @description Parse live feed response to extract periods
     * @param response ESPNLiveFeedResponse from ESPNHttpService
     * @param fixtureId Salesforce Match__c ID
     * @return List<Match_Period__c> Period records ready for insert
     */
    public static List<Match_Period__c> parseLiveFeedToPeriods(ESPNHttpService.ESPNLiveFeedResponse response, Id fixtureId) {
        List<Match_Period__c> periods = new List<Match_Period__c>();
        
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
            // ESPN format: 2025-12-21T16:30Z or 2025-12-21T16:30:00Z
            // Salesforce DateTime.valueOf() requires: YYYY-MM-DD HH:MM:SS
            String dateStr = espnDate;
            
            // Remove the Z timezone indicator
            dateStr = dateStr.replace('Z', '');
            
            // Check if seconds are missing (format HH:MM instead of HH:MM:SS)
            // Count colons in the time part only (after the T)
            Integer colonCount = dateStr.length() - dateStr.replace(':', '').length();
            if (colonCount == 1) {
                // Has YYYY-MM-DDTHH:MM format (only 1 colon), add :00 for seconds
                dateStr = dateStr + ':00';
            }
            
            // Replace T with space to get Salesforce format
            dateStr = dateStr.replace('T', ' ');
            
            return DateTime.valueOf(dateStr);
        } catch (Exception e) {
            System.debug('Failed to parse ESPN date: ' + espnDate + ' - ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Map ESPN status values to Salesforce picklist values
     * ESPN returns: FT (Full Time), Scheduled, Live, etc.
     * Salesforce expects: Scheduled, Live, Completed, Postponed, Cancelled
     * @param espnStatus ESPN status string
     * @return String Salesforce Status__c picklist value
     */
    private static String mapESPNStatusToSalesforce(String espnStatus) {
        if (String.isBlank(espnStatus)) {
            return 'Scheduled';
        }
        
        String status = espnStatus.toLowerCase();
        
        // Map ESPN status codes to Salesforce picklist
        if (status == 'ft' || status == 'final' || status == 'completed') {
            return 'Completed';
        } else if (status.contains('live') || status == 'in progress') {
            return 'Live';
        } else if (status.contains('postponed')) {
            return 'Postponed';
        } else if (status.contains('cancel')) {
            return 'Cancelled';
        } else if (status.contains('scheduled') || status.contains('pre')) {
            return 'Scheduled';
        }
        
        // If status looks like a date/time string (e.g., "Sun, December 28th at 9:00 AM EST")
        // it's a scheduled match
        if (status.contains(',') || status.contains('at') || status.contains('am') || status.contains('pm')) {
            return 'Scheduled';
        }
        
        // Default to Scheduled for unknown statuses
        System.debug('Unknown ESPN status "' + espnStatus + '", defaulting to Scheduled');
        return 'Scheduled';
    }
}

