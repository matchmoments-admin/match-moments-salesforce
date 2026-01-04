/**
 * @description Utility class for resolving ESPN Event IDs from Match records
 * Consolidates search logic to find ESPN Event IDs by matching teams, dates, and names
 * @author Brendan Milton
 * @date 2025-12-31
 */
public class ESPNEventIdResolver {
    
    /**
     * @description Resolve ESPN Event ID for a Match record
     * Attempts to find the ESPN Event ID by matching teams, dates, and names
     * @param match Match__c record (should have Competition__c, Match_Date_Time__c, Home_Team__c, Away_Team__c)
     * @return String ESPN Event ID if found, null otherwise
     */
    public static String resolveEventId(Match__c match) {
        if (match == null) {
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: Match record is null');
            return null;
        }
        
        // Determine sport and league
        String sportType = 'Soccer';
        String leagueCode = null;
        
        // Try to get from relationship field first
        if (match.Competition__r != null) {
            sportType = String.isNotBlank(match.Competition__r.Sport__c) 
                ? match.Competition__r.Sport__c : 'Soccer';
            leagueCode = match.Competition__r.ESPN_League_ID__c;
        } else if (match.Competition__c != null) {
            // Query if relationship not loaded
            try {
                Competition__c comp = [SELECT Sport__c, ESPN_League_ID__c FROM Competition__c WHERE Id = :match.Competition__c LIMIT 1];
                sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
                leagueCode = comp.ESPN_League_ID__c;
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: Could not query Competition: ' + e.getMessage());
            }
        }
        
        // Get default league code if not set
        if (String.isBlank(leagueCode)) {
            leagueCode = SportUtils.getDefaultLeagueCode(sportType);
        }
        
        // Normalize sport for ESPN API
        String espnSport = SportUtils.normalizeSportForESPN(sportType);
        
        // Special handling: If league code indicates soccer but sport is "Football", treat as "Soccer"
        if (espnSport == 'football' && String.isNotBlank(leagueCode)) {
            String leagueLower = leagueCode.toLowerCase();
            if (leagueLower.startsWith('eng.') || leagueLower.startsWith('uefa.') || 
                leagueLower.startsWith('esp.') || leagueLower.startsWith('ita.') ||
                leagueLower.startsWith('fra.') || leagueLower.startsWith('ger.') ||
                leagueLower.startsWith('usa.mls') || leagueLower.contains('champions') ||
                leagueLower.contains('europa') || leagueLower.startsWith('aus.')) {
                espnSport = 'soccer';
                System.debug(LoggingLevel.INFO, 'ESPNEventIdResolver: Detected soccer league code "' + leagueCode + '" - using "soccer" instead of "football"');
            }
        }
        
        return resolveEventId(match, espnSport, leagueCode);
    }
    
    /**
     * @description Resolve ESPN Event ID with explicit sport and league
     * @param match Match__c record
     * @param espnSport ESPN sport code (e.g., 'soccer', 'basketball')
     * @param leagueCode ESPN league code (e.g., 'eng.1', 'nba')
     * @return String ESPN Event ID if found, null otherwise
     */
    public static String resolveEventId(Match__c match, String espnSport, String leagueCode) {
        if (match == null) {
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: Match record is null');
            return null;
        }
        
        // Validate required fields
        if (match.Match_Date_Time__c == null) {
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: Match_Date_Time__c is required');
            return null;
        }
        
        if (match.Home_Team__c == null && match.Away_Team__c == null) {
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: At least one team (Home_Team__c or Away_Team__c) is required');
            return null;
        }
        
        try {
            // Get match date
            Date matchDate = match.Match_Date_Time__c.date();
            String dateStr = matchDate.year() + 
                String.valueOf(matchDate.month()).leftPad(2, '0') + 
                String.valueOf(matchDate.day()).leftPad(2, '0');
            
            // Get team ESPN IDs and names
            Set<Id> teamIds = new Set<Id>();
            if (match.Home_Team__c != null) teamIds.add(match.Home_Team__c);
            if (match.Away_Team__c != null) teamIds.add(match.Away_Team__c);
            
            Map<Id, String> teamEspnIdMap = new Map<Id, String>();
            Map<Id, String> teamNameMap = new Map<Id, String>();
            
            if (!teamIds.isEmpty()) {
                // Try to get from relationship fields first
                if (match.Home_Team__r != null && match.Home_Team__r.ESPN_Team_ID__c != null) {
                    teamEspnIdMap.put(match.Home_Team__c, match.Home_Team__r.ESPN_Team_ID__c);
                }
                if (match.Home_Team__r != null && String.isNotBlank(match.Home_Team__r.Name)) {
                    teamNameMap.put(match.Home_Team__c, match.Home_Team__r.Name);
                }
                if (match.Away_Team__r != null && match.Away_Team__r.ESPN_Team_ID__c != null) {
                    teamEspnIdMap.put(match.Away_Team__c, match.Away_Team__r.ESPN_Team_ID__c);
                }
                if (match.Away_Team__r != null && String.isNotBlank(match.Away_Team__r.Name)) {
                    teamNameMap.put(match.Away_Team__c, match.Away_Team__r.Name);
                }
                
                // Query if relationship fields not loaded
                if (teamEspnIdMap.isEmpty() || teamNameMap.isEmpty()) {
                    List<Account> teams = [
                        SELECT Id, Name, ESPN_Team_ID__c
                        FROM Account
                        WHERE Id IN :teamIds
                    ];
                    
                    for (Account team : teams) {
                        if (String.isNotBlank(team.ESPN_Team_ID__c)) {
                            teamEspnIdMap.put(team.Id, team.ESPN_Team_ID__c);
                        }
                        if (String.isNotBlank(team.Name)) {
                            teamNameMap.put(team.Id, team.Name);
                        }
                    }
                }
            }
            
            // Search ESPN scoreboard for the date
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: No events found in ESPN scoreboard for date: ' + dateStr + ', sport: ' + espnSport + ', league: ' + leagueCode);
                return null;
            }
            
            // Try to match by team ESPN IDs first (most reliable)
            if (!teamEspnIdMap.isEmpty()) {
                String homeTeamEspnId = match.Home_Team__c != null ? teamEspnIdMap.get(match.Home_Team__c) : null;
                String awayTeamEspnId = match.Away_Team__c != null ? teamEspnIdMap.get(match.Away_Team__c) : null;
                
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    // Match both teams by ESPN ID
                    Boolean homeMatches = (homeTeamEspnId == null || event.homeTeamId == homeTeamEspnId);
                    Boolean awayMatches = (awayTeamEspnId == null || event.awayTeamId == awayTeamEspnId);
                    
                    if (homeMatches && awayMatches && (homeTeamEspnId != null || awayTeamEspnId != null)) {
                        System.debug(LoggingLevel.INFO, 'ESPNEventIdResolver: Matched event by team ESPN IDs: ' + event.id + ' (' + event.name + ')');
                        return event.id;
                    }
                }
            }
            
            // Fall back to matching by team names
            if (!teamNameMap.isEmpty()) {
                String homeTeamName = match.Home_Team__c != null ? teamNameMap.get(match.Home_Team__c) : null;
                String awayTeamName = match.Away_Team__c != null ? teamNameMap.get(match.Away_Team__c) : null;
                
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    // Match by team names in event name
                    if (String.isNotBlank(event.name)) {
                        Boolean homeMatches = (homeTeamName == null || 
                            event.name.containsIgnoreCase(homeTeamName) || 
                            homeTeamName.containsIgnoreCase(event.name));
                        Boolean awayMatches = (awayTeamName == null || 
                            event.name.containsIgnoreCase(awayTeamName) || 
                            awayTeamName.containsIgnoreCase(event.name));
                        
                        if (homeMatches && awayMatches && (homeTeamName != null || awayTeamName != null)) {
                            System.debug(LoggingLevel.INFO, 'ESPNEventIdResolver: Matched event by team names in event name: ' + event.id + ' (' + event.name + ')');
                            return event.id;
                        }
                    }
                    
                    // Also try matching by individual team names in event
                    if (String.isNotBlank(event.homeTeamName) && String.isNotBlank(event.awayTeamName)) {
                        Boolean homeMatches = (homeTeamName == null || 
                            event.homeTeamName.containsIgnoreCase(homeTeamName) || 
                            homeTeamName.containsIgnoreCase(event.homeTeamName));
                        Boolean awayMatches = (awayTeamName == null || 
                            event.awayTeamName.containsIgnoreCase(awayTeamName) || 
                            awayTeamName.containsIgnoreCase(event.awayTeamName));
                        
                        if (homeMatches && awayMatches && (homeTeamName != null || awayTeamName != null)) {
                            System.debug(LoggingLevel.INFO, 'ESPNEventIdResolver: Matched event by individual team names: ' + event.id + ' (' + event.name + ')');
                            return event.id;
                        }
                    }
                }
            }
            
            // Last resort: match by match name if available
            if (String.isNotBlank(match.Name)) {
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    if (event.name != null) {
                        if (event.name.containsIgnoreCase(match.Name) || 
                            match.Name.containsIgnoreCase(event.name)) {
                            System.debug(LoggingLevel.INFO, 'ESPNEventIdResolver: Matched event by match name: ' + event.id + ' (' + event.name + ')');
                            return event.id;
                        }
                    }
                }
            }
            
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolver: Could not find matching ESPN event for match: ' + match.Name + ' (ID: ' + match.Id + ')');
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolver: Error searching for ESPN Event ID: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolver: Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
}

