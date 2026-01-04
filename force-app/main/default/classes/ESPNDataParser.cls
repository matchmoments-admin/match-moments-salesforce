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
            fixture.Match_Level__c = 'Professional'; // ESPN-synced matches are always Professional
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
    
    /**
     * @description Parse ESPN lineup data to Lineup__c and Match_Participation__c records
     * @param lineup ESPNLineup from ESPNMatchSummaryResponse
     * @param matchId Salesforce Match__c ID
     * @param teamId Salesforce Account (Team) ID
     * @return Map with 'lineup' (Lineup__c) and 'participations' (List<Match_Participation__c>)
     */
    public static Map<String, Object> parseLineupToLineup(
        ESPNHttpService.ESPNLineup lineup, 
        Id matchId, 
        Id teamId
    ) {
        Map<String, Object> result = new Map<String, Object>();
        List<Match_Participation__c> participations = new List<Match_Participation__c>();
        
        if (lineup == null || lineup.players == null) {
            System.debug('Invalid lineup data');
            result.put('lineup', null);
            result.put('participations', participations);
            return result;
        }
        
        // Build lineup JSON structure
        Map<String, Object> lineupJson = new Map<String, Object>();
        List<Object> lines = new List<Object>();
        Map<String, Object> goalkeeper = null;
        List<Object> bench = new List<Object>();
        
        // Group players by position to determine formation
        Map<String, List<ESPNHttpService.ESPNLineupPlayer>> playersByPosition = new Map<String, List<ESPNHttpService.ESPNLineupPlayer>>();
        
        for (ESPNHttpService.ESPNLineupPlayer player : lineup.players) {
            if (player.starter) {
                if (player.positionAbbreviation == 'G' || player.position == 'Goalkeeper') {
                    goalkeeper = new Map<String, Object>{
                        'playerId' => findOrCreatePlayer(player, teamId),
                        'jersey' => player.jersey,
                        'name' => player.displayName,
                        'position' => 'GK'
                    };
                } else {
                    String positionKey = player.positionAbbreviation != null ? player.positionAbbreviation : 'M';
                    if (!playersByPosition.containsKey(positionKey)) {
                        playersByPosition.put(positionKey, new List<ESPNHttpService.ESPNLineupPlayer>());
                    }
                    playersByPosition.get(positionKey).add(player);
                }
            } else {
                // Substitute
                Map<String, Object> benchPlayer = new Map<String, Object>{
                    'playerId' => findOrCreatePlayer(player, teamId),
                    'jersey' => player.jersey,
                    'name' => player.displayName,
                    'position' => player.positionAbbreviation != null ? player.positionAbbreviation : 'M'
                };
                bench.add(benchPlayer);
            }
        }
        
        // Build formation lines (simplified - assumes standard formations)
        // This is a basic implementation - could be enhanced to detect actual formation
        Integer defCount = 0, midCount = 0, fwdCount = 0;
        for (String posKey : playersByPosition.keySet()) {
            if (posKey.startsWith('D') || posKey.startsWith('CD') || posKey.startsWith('FB')) {
                defCount += playersByPosition.get(posKey).size();
            } else if (posKey.startsWith('M') || posKey.startsWith('CM') || posKey.startsWith('AM')) {
                midCount += playersByPosition.get(posKey).size();
            } else if (posKey.startsWith('F') || posKey.startsWith('FW') || posKey.startsWith('ST')) {
                fwdCount += playersByPosition.get(posKey).size();
            }
        }
        
        // Determine formation string
        String formation = defCount + '-' + midCount + '-' + fwdCount;
        if (defCount == 0 && midCount == 0 && fwdCount == 0) {
            formation = 'Unknown';
        }
        
        // Build lines for JSON (grouped by position type)
        if (defCount > 0) {
            List<Object> defLine = new List<Object>();
            for (String posKey : playersByPosition.keySet()) {
                if (posKey.startsWith('D') || posKey.startsWith('CD') || posKey.startsWith('FB')) {
                    for (ESPNHttpService.ESPNLineupPlayer player : playersByPosition.get(posKey)) {
                        defLine.add(new Map<String, Object>{
                            'playerId' => findOrCreatePlayer(player, teamId),
                            'jersey' => player.jersey,
                            'name' => player.displayName,
                            'position' => player.positionAbbreviation != null ? player.positionAbbreviation : 'D'
                        });
                    }
                }
            }
            lines.add(new Map<String, Object>{'players' => defLine});
        }
        
        if (midCount > 0) {
            List<Object> midLine = new List<Object>();
            for (String posKey : playersByPosition.keySet()) {
                if (posKey.startsWith('M') || posKey.startsWith('CM') || posKey.startsWith('AM')) {
                    for (ESPNHttpService.ESPNLineupPlayer player : playersByPosition.get(posKey)) {
                        midLine.add(new Map<String, Object>{
                            'playerId' => findOrCreatePlayer(player, teamId),
                            'jersey' => player.jersey,
                            'name' => player.displayName,
                            'position' => player.positionAbbreviation != null ? player.positionAbbreviation : 'M'
                        });
                    }
                }
            }
            lines.add(new Map<String, Object>{'players' => midLine});
        }
        
        if (fwdCount > 0) {
            List<Object> fwdLine = new List<Object>();
            for (String posKey : playersByPosition.keySet()) {
                if (posKey.startsWith('F') || posKey.startsWith('FW') || posKey.startsWith('ST')) {
                    for (ESPNHttpService.ESPNLineupPlayer player : playersByPosition.get(posKey)) {
                        fwdLine.add(new Map<String, Object>{
                            'playerId' => findOrCreatePlayer(player, teamId),
                            'jersey' => player.jersey,
                            'name' => player.displayName,
                            'position' => player.positionAbbreviation != null ? player.positionAbbreviation : 'F'
                        });
                    }
                }
            }
            lines.add(new Map<String, Object>{'players' => fwdLine});
        }
        
        lineupJson.put('goalkeeper', goalkeeper);
        lineupJson.put('lines', lines);
        lineupJson.put('bench', bench);
        
        // Create Lineup__c record
        Lineup__c lineupRecord = new Lineup__c();
        lineupRecord.Match__c = matchId;
        lineupRecord.Team__c = teamId;
        lineupRecord.Formation__c = formation;
        lineupRecord.Lineup_JSON__c = JSON.serialize(lineupJson);
        // Count starters
        Integer starterCount = 0;
        if (lineup.players != null) {
            for (ESPNHttpService.ESPNLineupPlayer p : lineup.players) {
                if (p.starter) {
                    starterCount++;
                }
            }
        }
        lineupRecord.Starting_XI_Count__c = starterCount;
        
        // Create Match_Participation__c records
        for (ESPNHttpService.ESPNLineupPlayer player : lineup.players) {
            Match_Participation__c participation = new Match_Participation__c();
            participation.Match__c = matchId;
            participation.Team__c = teamId;
            participation.Player__c = findOrCreatePlayer(player, teamId);
            participation.Position__c = player.positionAbbreviation != null ? player.positionAbbreviation : 
                (player.position != null ? player.position : 'Unknown');
            participation.Role__c = player.starter ? 'Starter' : 'Substitute';
            
            participations.add(participation);
        }
        
        result.put('lineup', lineupRecord);
        result.put('participations', participations);
        
        System.debug('Parsed lineup with ' + participations.size() + ' participations');
        return result;
    }
    
    /**
     * @description Parse ESPN commentary to Commentary__c and Match_Moment__c records
     * @param commentaryItems List of ESPNCommentaryItem from ESPNMatchSummaryResponse
     * @param matchId Salesforce Match__c ID
     * @return Map with 'commentary' (Commentary__c) and 'moments' (List<Match_Moment__c>)
     */
    public static Map<String, Object> parseCommentaryToMatchMoments(
        List<ESPNHttpService.ESPNCommentaryItem> commentaryItems,
        Id matchId
    ) {
        Map<String, Object> result = new Map<String, Object>();
        List<Match_Moment__c> moments = new List<Match_Moment__c>();
        
        if (commentaryItems == null || commentaryItems.isEmpty()) {
            System.debug('No commentary items to parse');
            result.put('commentary', null);
            result.put('moments', moments);
            return result;
        }
        
        // Create parent Commentary__c record (deprecated - uses Fixture__c, not Match__c)
        Commentary__c commentary = new Commentary__c();
        // Note: Commentary__c is deprecated and uses Fixture__c field, not Match__c
        // Since we're working with Match__c IDs, we'll leave Fixture__c unset for now
        commentary.Commentary_JSON__c = JSON.serialize(commentaryItems);
        
        // Parse commentary items into Match_Moment__c records
        for (ESPNHttpService.ESPNCommentaryItem item : commentaryItems) {
            if (String.isBlank(item.text)) {
                continue;
            }
            
            Match_Moment__c moment = new Match_Moment__c();
            moment.Match__c = matchId;
            moment.Description__c = item.text;
            // Event_Time__c is DateTime, timeValue is Decimal - will be set from parsed minute/second
            // moment.Event_Time__c = null; // Leave null, will be calculated if needed
            
            // Parse time display to extract minute/second
            if (String.isNotBlank(item.timeDisplay)) {
                parseTimeDisplay(item.timeDisplay, moment);
            }
            
            // Determine event type from text
            moment.Event_Type__c = determineEventType(item.text);
            moment.Event_Importance__c = determineEventImportance(item.text);
            moment.Is_Shareable__c = (moment.Event_Type__c == 'Goal' || 
                                      moment.Event_Type__c == 'Card' || 
                                      moment.Event_Type__c == 'Substitution');
            
            moments.add(moment);
        }
        
        result.put('commentary', commentary);
        result.put('moments', moments);
        
        System.debug('Parsed ' + moments.size() + ' match moments from commentary');
        return result;
    }
    
    /**
     * @description Parse ESPN periods to Match_Period__c records
     * @param periods List of ESPNPeriod from ESPNMatchSummaryResponse
     * @param matchId Salesforce Match__c ID
     * @return List<Match_Period__c> Period records ready for insert
     */
    public static List<Match_Period__c> parsePeriodsToMatchPeriods(
        List<ESPNHttpService.ESPNPeriod> periods,
        Id matchId
    ) {
        List<Match_Period__c> periodRecords = new List<Match_Period__c>();
        
        if (periods == null || periods.isEmpty()) {
            System.debug('No periods to parse');
            return periodRecords;
        }
        
        Decimal homeCumulative = 0;
        Decimal awayCumulative = 0;
        
        for (ESPNHttpService.ESPNPeriod period : periods) {
            Match_Period__c periodRecord = new Match_Period__c();
            periodRecord.Match__c = matchId;
            periodRecord.Period_Number__c = period.periodNumber;
            periodRecord.Period_Type__c = period.periodType;
            
            periodRecord.Home_Score_Period__c = period.homeScore != null ? period.homeScore : 0;
            periodRecord.Away_Score_Period__c = period.awayScore != null ? period.awayScore : 0;
            
            homeCumulative += periodRecord.Home_Score_Period__c;
            awayCumulative += periodRecord.Away_Score_Period__c;
            
            periodRecord.Home_Score_Cumulative__c = homeCumulative;
            periodRecord.Away_Score_Cumulative__c = awayCumulative;
            periodRecord.Status__c = 'Completed'; // Historical periods are completed
            
            periodRecords.add(periodRecord);
        }
        
        System.debug('Parsed ' + periodRecords.size() + ' match periods');
        return periodRecords;
    }
    
    // ========================================
    // PRIVATE HELPER METHODS FOR PARSERS
    // ========================================
    
    /**
     * @description Find or create a player Contact from ESPN lineup player data
     * @param player ESPNLineupPlayer
     * @param teamId Team Account ID
     * @return Contact ID
     */
    private static Id findOrCreatePlayer(ESPNHttpService.ESPNLineupPlayer player, Id teamId) {
        if (String.isBlank(player.athleteId)) {
            return null;
        }
        
        // Try to find existing player by ESPN ID
        List<Contact> existingPlayers = [
            SELECT Id 
            FROM Contact 
            WHERE ESPN_Player_ID__c = :player.athleteId 
            LIMIT 1
        ];
        
        if (!existingPlayers.isEmpty()) {
            return existingPlayers[0].Id;
        }
        
        // Create new player if not found
        Contact newPlayer = new Contact();
        newPlayer.AccountId = teamId;
        newPlayer.ESPN_Player_ID__c = player.athleteId;
        
        // Parse name
        if (String.isNotBlank(player.fullName)) {
            List<String> nameParts = player.fullName.split(' ', 2);
            newPlayer.FirstName = nameParts.size() > 0 ? nameParts[0] : player.displayName;
            newPlayer.LastName = nameParts.size() > 1 ? nameParts[1] : 'Player';
        } else if (String.isNotBlank(player.displayName)) {
            List<String> nameParts = player.displayName.split(' ', 2);
            newPlayer.FirstName = nameParts.size() > 0 ? nameParts[0] : player.displayName;
            newPlayer.LastName = nameParts.size() > 1 ? nameParts[1] : 'Player';
        }
        
        if (String.isNotBlank(player.jersey)) {
            try {
                newPlayer.Jersey_Number__c = Decimal.valueOf(player.jersey);
            } catch (Exception e) {
                System.debug('Failed to parse jersey: ' + player.jersey);
            }
        }
        
        newPlayer.Position__c = player.position;
        newPlayer.Profile_Image_URL__c = player.headshotUrl;
        
        // Note: This method should be called within a Unit of Work context
        // The caller is responsible for inserting the contact
        // For now, we'll insert it here but this should be refactored
        try {
            insert newPlayer;
            return newPlayer.Id;
        } catch (Exception e) {
            System.debug('Failed to create player: ' + e.getMessage());
            // Try to find again in case it was created concurrently
            List<Contact> retryPlayers = [
                SELECT Id 
                FROM Contact 
                WHERE ESPN_Player_ID__c = :player.athleteId 
                LIMIT 1
            ];
            if (!retryPlayers.isEmpty()) {
                return retryPlayers[0].Id;
            }
            return null;
        }
    }
    
    /**
     * @description Parse time display string to extract minute and second
     * @param timeDisplay Time display string (e.g., "10'", "45'+2", "90'+7")
     * @param moment Match_Moment__c to populate
     */
    private static void parseTimeDisplay(String timeDisplay, Match_Moment__c moment) {
        if (String.isBlank(timeDisplay)) {
            return;
        }
        
        try {
            // Handle formats like "10'", "45'+2", "90'+7"
            if (timeDisplay.contains('\'')) {
                String[] parts = timeDisplay.split('\'');
                if (parts.size() > 0) {
                    String minuteStr = parts[0].trim();
                    moment.Event_Minute__c = Decimal.valueOf(minuteStr);
                }
                
                // Check for added time (e.g., "+2")
                if (parts.size() > 1 && parts[1].contains('+')) {
                    String addedTime = parts[1].replace('+', '').trim();
                    if (String.isNotBlank(addedTime)) {
                        moment.Event_Second__c = Decimal.valueOf(addedTime);
                    }
                }
            } else {
                // Try to parse as decimal
                moment.Event_Minute__c = Decimal.valueOf(timeDisplay);
            }
        } catch (Exception e) {
            System.debug('Failed to parse time display: ' + timeDisplay);
        }
    }
    
    /**
     * @description Determine event type from commentary text
     * @param text Commentary text
     * @return String Event type
     */
    private static String determineEventType(String text) {
        if (String.isBlank(text)) {
            return 'Other';
        }
        
        String lowerText = text.toLowerCase();
        
        if (lowerText.contains('goal') || lowerText.contains('scores')) {
            return 'Goal';
        } else if (lowerText.contains('yellow card')) {
            return 'Yellow Card';
        } else if (lowerText.contains('red card')) {
            return 'Red Card';
        } else if (lowerText.contains('substitution') || lowerText.contains('subbed')) {
            return 'Substitution';
        } else if (lowerText.contains('penalty')) {
            return 'Penalty';
        } else if (lowerText.contains('corner')) {
            return 'Corner';
        } else if (lowerText.contains('foul')) {
            return 'Foul';
        } else if (lowerText.contains('offside')) {
            return 'Offside';
        } else {
            return 'Other';
        }
    }
    
    /**
     * @description Determine event importance from commentary text
     * @param text Commentary text
     * @return String Event importance
     */
    private static String determineEventImportance(String text) {
        if (String.isBlank(text)) {
            return 'Low';
        }
        
        String lowerText = text.toLowerCase();
        
        if (lowerText.contains('goal') || lowerText.contains('red card')) {
            return 'High';
        } else if (lowerText.contains('yellow card') || lowerText.contains('penalty')) {
            return 'Medium';
        } else {
            return 'Low';
        }
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
    public static DateTime parseESPNDateTime(String espnDate) {
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

