/**
 * @description Main service class for syncing ESPN data to Salesforce
 * Orchestrates HTTP calls, parsing, and DML operations
 * @author Brendan Milton
 * @date 2025-12-20
 */
public with sharing class ESPNSyncService {
    
    /**
     * @description Sync all teams for a league
     * Call this FIRST to populate teams before syncing fixtures
     * @param sport Sport type (e.g., 'soccer', 'basketball')
     * @param leagueCode ESPN league code (e.g., 'eng.wsl', 'usa.nwsl', 'wnba')
     * @return Integer Number of teams synced
     */
    public static Integer syncLeagueTeams(String sport, String leagueCode) {
        System.debug('=== ESPNSyncService: Starting team sync for ' + leagueCode + ' ===');
        
        try {
            // Fetch teams from ESPN
            ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(sport, leagueCode);
            
            if (!response.success || response.teams == null || response.teams.isEmpty()) {
                System.debug('No teams found or API error: ' + response.errorMessage);
                return 0;
            }
            
            // Parse to Account records
            List<Account> accounts = ESPNDataParser.parseTeamsToAccounts(response, leagueCode);
            
            if (accounts.isEmpty()) {
                System.debug('No accounts to sync');
                return 0;
            }
            
            // Upsert by ESPN_Team_ID__c
            Database.UpsertResult[] results = Database.upsert(
                accounts, 
                Account.ESPN_Team_ID__c, 
                false
            );
            
            // Count successes
            Integer successCount = 0;
            Integer errorCount = 0;
            
            for (Database.UpsertResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for (Database.Error err : result.getErrors()) {
                        System.debug('ERROR: ' + err.getMessage());
                    }
                }
            }
            
            System.debug('=== Team sync complete: ' + successCount + ' success, ' + errorCount + ' errors ===');
            return successCount;
            
        } catch (Exception e) {
            System.debug('EXCEPTION syncing teams: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @description Sync roster for a specific team
     * @param sport Sport type
     * @param leagueCode ESPN league code
     * @param espnTeamId ESPN team ID (from Account.ESPN_Team_ID__c)
     * @return Integer Number of players synced
     */
    public static Integer syncTeamRoster(String sport, String leagueCode, String espnTeamId) {
        System.debug('=== ESPNSyncService: Syncing roster for team ' + espnTeamId + ' ===');
        
        try {
            // Find Salesforce team
            List<Account> teams = [SELECT Id FROM Account WHERE ESPN_Team_ID__c = :espnTeamId LIMIT 1];
            
            if (teams.isEmpty()) {
                System.debug('Team not found in Salesforce with ESPN ID: ' + espnTeamId);
                return 0;
            }
            
            Id teamId = teams[0].Id;
            
            // Fetch roster from ESPN
            ESPNHttpService.ESPNRosterResponse response = ESPNHttpService.getTeamRoster(sport, leagueCode, espnTeamId);
            
            if (!response.success || response.athletes == null || response.athletes.isEmpty()) {
                System.debug('No athletes found or API error: ' + response.errorMessage);
                return 0;
            }
            
            // Parse to Contact records
            List<Contact> contacts = ESPNDataParser.parseRosterToContacts(response, teamId);
            
            if (contacts.isEmpty()) {
                System.debug('No contacts to sync');
                return 0;
            }
            
            // Upsert by ESPN_Player_ID__c
            Database.UpsertResult[] results = Database.upsert(
                contacts, 
                Contact.ESPN_Player_ID__c, 
                false
            );
            
            // Count successes
            Integer successCount = 0;
            Integer errorCount = 0;
            
            for (Database.UpsertResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for (Database.Error err : result.getErrors()) {
                        System.debug('ERROR: ' + err.getMessage());
                    }
                }
            }
            
            System.debug('=== Roster sync complete: ' + successCount + ' success, ' + errorCount + ' errors ===');
            return successCount;
            
        } catch (Exception e) {
            System.debug('EXCEPTION syncing roster: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @description Sync fixtures for a specific date
     * @param sport Sport type
     * @param leagueCode ESPN league code
     * @param fixtureDate Date to sync fixtures for
     * @param competitionId Salesforce Competition__c ID
     * @return Integer Number of fixtures synced
     */
    public static Integer syncFixturesForDate(String sport, String leagueCode, Date fixtureDate, Id competitionId) {
        String dateStr = ESPNHttpService.formatDateForESPN(fixtureDate);
        System.debug('=== ESPNSyncService: Syncing fixtures for ' + dateStr + ' ===');
        
        try {
            // Fetch fixtures from ESPN
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(sport, leagueCode, dateStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                System.debug('No fixtures found or API error: ' + response.errorMessage);
                return 0;
            }
            
            // Parse to Match__c records
            List<Match__c> fixtures = ESPNDataParser.parseScoreboardToFixtures(response, competitionId);
            
            if (fixtures.isEmpty()) {
                System.debug('No fixtures to sync');
                return 0;
            }
            
            // Upsert by ESPN_Event_ID__c
            Database.UpsertResult[] results = Database.upsert(
                fixtures, 
                Match__c.ESPN_Event_ID__c, 
                false
            );
            
            // Count successes
            Integer successCount = 0;
            Integer errorCount = 0;
            
            for (Database.UpsertResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for (Database.Error err : result.getErrors()) {
                        System.debug('ERROR: ' + err.getMessage());
                    }
                }
            }
            
            System.debug('=== Fixture sync complete: ' + successCount + ' success, ' + errorCount + ' errors ===');
            return successCount;
            
        } catch (Exception e) {
            System.debug('EXCEPTION syncing fixtures: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @description Sync fixtures for a date range
     * @param sport Sport type
     * @param leagueCode ESPN league code
     * @param startDate Start date (inclusive)
     * @param endDate End date (inclusive)
     * @param competitionId Salesforce Competition__c ID
     * @return Integer Number of fixtures synced
     */
    public static Integer syncFixturesForDateRange(String sport, String leagueCode, Date startDate, Date endDate, Id competitionId) {
        String startStr = ESPNHttpService.formatDateForESPN(startDate);
        String endStr = ESPNHttpService.formatDateForESPN(endDate);
        System.debug('=== ESPNSyncService: Syncing fixtures from ' + startStr + ' to ' + endStr + ' ===');
        
        try {
            // Fetch fixtures from ESPN
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixturesForDateRange(sport, leagueCode, startStr, endStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                System.debug('No fixtures found or API error: ' + response.errorMessage);
                return 0;
            }
            
            // Parse to Match__c records
            List<Match__c> fixtures = ESPNDataParser.parseScoreboardToFixtures(response, competitionId);
            
            if (fixtures.isEmpty()) {
                System.debug('No fixtures to sync');
                return 0;
            }
            
            // Upsert by ESPN_Event_ID__c
            Database.UpsertResult[] results = Database.upsert(
                fixtures, 
                Match__c.ESPN_Event_ID__c, 
                false
            );
            
            // Count successes
            Integer successCount = 0;
            Integer errorCount = 0;
            
            for (Database.UpsertResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for (Database.Error err : result.getErrors()) {
                        System.debug('ERROR: ' + err.getMessage());
                    }
                }
            }
            
            System.debug('=== Fixture sync complete: ' + successCount + ' success, ' + errorCount + ' errors ===');
            return successCount;
            
        } catch (Exception e) {
            System.debug('EXCEPTION syncing fixtures: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @description Sync all rosters for all teams in a league
     * Fetches the team list from ESPN API first to ensure we only sync teams that belong to this league
     * @param sport Sport type
     * @param leagueCode ESPN league code
     * @return Integer Total number of players synced
     */
    public static Integer syncAllRostersForLeague(String sport, String leagueCode) {
        System.debug('=== ESPNSyncService: Syncing all rosters for ' + leagueCode + ' ===');
        
        Integer totalPlayers = 0;
        
        try {
            // Step 1: Fetch teams from ESPN API to get the correct team list for this league
            ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(sport, leagueCode);
            
            if (!response.success || response.teams == null || response.teams.isEmpty()) {
                System.debug('Failed to fetch teams from ESPN API: ' + response.errorMessage);
                return 0;
            }
            
            // Step 2: Build set of ESPN team IDs that belong to this league
            Set<String> espnTeamIds = new Set<String>();
            for (ESPNHttpService.ESPNTeam team : response.teams) {
                espnTeamIds.add(team.id);
            }
            
            System.debug('Found ' + espnTeamIds.size() + ' teams in league ' + leagueCode + ' from ESPN API');
            
            // Step 3: Query only Accounts that match these ESPN team IDs
            List<Account> teams = [SELECT Id, Name, ESPN_Team_ID__c 
                                   FROM Account 
                                   WHERE ESPN_Team_ID__c IN :espnTeamIds 
                                   ORDER BY Name];
            
            System.debug('Found ' + teams.size() + ' matching teams in Salesforce to sync rosters for');
            
            // Step 4: Sync roster for each team
            for (Account team : teams) {
                try {
                    Integer playersForTeam = syncTeamRoster(sport, leagueCode, team.ESPN_Team_ID__c);
                    totalPlayers += playersForTeam;
                    System.debug('✓ Synced ' + playersForTeam + ' players for ' + team.Name);
                } catch (Exception e) {
                    System.debug('✗ ERROR syncing roster for ' + team.Name + ': ' + e.getMessage());
                    // Continue with next team
                }
            }
            
            System.debug('=== All rosters sync complete: ' + totalPlayers + ' total players ===');
            return totalPlayers;
            
        } catch (Exception e) {
            System.debug('EXCEPTION in syncAllRostersForLeague: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @description Get or create Competition record for a league
     * @param leagueCode ESPN league code
     * @param leagueName Display name for the competition
     * @param sportType Sport type (e.g., 'Soccer', 'Basketball')
     * @param seasonYear Season year (e.g., '2024-25')
     * @return Id Competition__c record ID
     */
    public static Id getOrCreateCompetition(String leagueCode, String leagueName, String sportType, String seasonYear) {
        // Try to find existing
        List<Competition__c> existing = [SELECT Id FROM Competition__c WHERE ESPN_League_ID__c = :leagueCode LIMIT 1];
        
        if (!existing.isEmpty()) {
            System.debug('Found existing competition: ' + existing[0].Id);
            return existing[0].Id;
        }
        
            // Create new
        Competition__c comp = new Competition__c(
            ESPN_League_ID__c = leagueCode,
            Sport__c = sportType,
            Season_Year__c = seasonYear,
            Status__c = 'Active'
        );
        
        insert comp;
        System.debug('Created new competition: ' + comp.Id);
        return comp.Id;
    }
}

