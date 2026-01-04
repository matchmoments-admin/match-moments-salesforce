/**
 * @description Apex controller for Match Summary page components
 * Provides centralized data retrieval for match summary, lineups, moments, league table, and stats
 * @author Brendan Milton
 * @date 2026-01-04
 */
public with sharing class MatchSummaryController {
    
    /**
     * @description Get complete match summary data with related records
     * @param matchId Match__c record ID
     * @return Map containing match data, teams, competition, and goal scorers
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMatchSummary(String matchId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            // Query match with related data
            List<Match__c> matches = MatchesSelector.newInstance().selectById(new Set<Id>{matchId});
            if (matches.isEmpty()) {
                throw new AuraHandledException('Match not found');
            }
            
            Match__c match = matches[0];
            
            // Build match data map
            Map<String, Object> matchData = new Map<String, Object>();
            matchData.put('id', match.Id);
            matchData.put('name', match.Name);
            matchData.put('matchDateTime', match.Match_Date_Time__c);
            matchData.put('status', match.Status__c);
            matchData.put('venue', match.Venue__c);
            matchData.put('attendance', match.Attendance__c);
            matchData.put('referee', match.Referee__c);
            matchData.put('homeScore', match.Home_Score_Final__c);
            matchData.put('awayScore', match.Away_Score_Final__c);
            matchData.put('matchStatsJSON', match.Match_Stats_JSON__c);
            
            // Query teams with logos
            // Using direct SOQL for fields not in TeamsSelector defaults (Team_Logo_URL__c, Team_Primary_Color__c)
            // This is acceptable for read-only controllers when selectors don't include all needed fields
            Set<Id> teamIds = new Set<Id>();
            if (match.Home_Team__c != null) teamIds.add(match.Home_Team__c);
            if (match.Away_Team__c != null) teamIds.add(match.Away_Team__c);
            
            List<Account> teams = [
                SELECT Id, Name, Team_Logo_URL__c, Team_Primary_Color__c, Logo_Url__c
                FROM Account
                WHERE Id IN :teamIds
            ];
            
            Map<Id, Account> teamMap = new Map<Id, Account>(teams);
            
            // Build home team data
            if (match.Home_Team__c != null && teamMap.containsKey(match.Home_Team__c)) {
                Account homeTeam = teamMap.get(match.Home_Team__c);
                matchData.put('homeTeam', new Map<String, Object>{
                    'id' => homeTeam.Id,
                    'name' => homeTeam.Name,
                    'logoUrl' => homeTeam.Team_Logo_URL__c != null ? homeTeam.Team_Logo_URL__c : homeTeam.Logo_Url__c,
                    'primaryColor' => homeTeam.Team_Primary_Color__c
                });
            }
            
            // Build away team data
            if (match.Away_Team__c != null && teamMap.containsKey(match.Away_Team__c)) {
                Account awayTeam = teamMap.get(match.Away_Team__c);
                matchData.put('awayTeam', new Map<String, Object>{
                    'id' => awayTeam.Id,
                    'name' => awayTeam.Name,
                    'logoUrl' => awayTeam.Team_Logo_URL__c != null ? awayTeam.Team_Logo_URL__c : awayTeam.Logo_Url__c,
                    'primaryColor' => awayTeam.Team_Primary_Color__c
                });
            }
            
            // Query competition using selector
            if (match.Competition__c != null) {
                List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{match.Competition__c});
                if (!competitions.isEmpty()) {
                    Competition__c comp = competitions[0];
                    matchData.put('competition', new Map<String, Object>{
                        'id' => comp.Id,
                        'name' => comp.Name,
                        'espnLeagueId' => comp.ESPN_League_ID__c,
                        'sport' => comp.Sport__c,
                        'seasonYear' => comp.Season_Year__c
                    });
                }
            }
            
            result.put('match', matchData);
            
            // Get goal scorers from Match_Moment__c
            List<Map<String, Object>> goalScorers = getGoalScorers(matchId);
            result.put('goalScorers', goalScorers);
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching match summary: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get goal scorers for the match
     * @param matchId Match__c record ID
     * @return List of goal scorer maps with player name, minute, and team
     */
    private static List<Map<String, Object>> getGoalScorers(String matchId) {
        List<Map<String, Object>> goalScorers = new List<Map<String, Object>>();
        
        List<Match_Moment__c> goals = [
            SELECT Id, Event_Minute__c, Event_Second__c, Description__c,
                   Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                   Team__r.Id, Team__r.Name
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            AND Event_Type__c = 'Goal'
            ORDER BY Event_Minute__c ASC, Event_Second__c ASC
        ];
        
        for (Match_Moment__c goal : goals) {
            Map<String, Object> scorer = new Map<String, Object>();
            scorer.put('minute', goal.Event_Minute__c);
            scorer.put('second', goal.Event_Second__c);
            scorer.put('description', goal.Description__c);
            if (goal.Primary_Player__r != null) {
                scorer.put('playerName', goal.Primary_Player__r.Name);
                scorer.put('jerseyNumber', goal.Primary_Player__r.Jersey_Number__c);
            }
            if (goal.Team__r != null) {
                scorer.put('teamId', goal.Team__r.Id);
                scorer.put('teamName', goal.Team__r.Name);
            }
            goalScorers.add(scorer);
        }
        
        return goalScorers;
    }
    
    /**
     * @description Get match lineups for both teams
     * @param matchId Match__c record ID
     * @return Map containing home and away team lineups
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMatchLineups(String matchId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            // Get match to identify home/away teams
            List<Match__c> matches = [
                SELECT Id, Home_Team__c, Away_Team__c
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                throw new AuraHandledException('Match not found');
            }
            
            Match__c match = matches[0];
            
            // Query teams for additional data (always query teams, even if no lineups)
            // Using direct SOQL for Team_Logo_URL__c field not in TeamsSelector defaults
            Set<Id> teamIds = new Set<Id>();
            if (match.Home_Team__c != null) teamIds.add(match.Home_Team__c);
            if (match.Away_Team__c != null) teamIds.add(match.Away_Team__c);
            
            List<Account> teams = [
                SELECT Id, Name, Team_Logo_URL__c, Logo_Url__c
                FROM Account
                WHERE Id IN :teamIds
            ];
            
            Map<Id, Account> teamMap = new Map<Id, Account>(teams);
            
            // Query lineups with fallback if selector fails
            List<Lineup__c> lineups = new List<Lineup__c>();
            try {
                lineups = LineupsSelector.newInstance().selectByMatchIds(new Set<Id>{matchId});
            } catch (Exception selectorError) {
                // Fallback to direct SOQL if selector not available
                System.debug('LineupsSelector not available, using direct SOQL: ' + selectorError.getMessage());
                try {
                    lineups = [
                        SELECT Id, Match__c, Team__c, Formation__c, Lineup_JSON__c, Captain__c
                        FROM Lineup__c
                        WHERE Match__c = :matchId
                    ];
                } catch (Exception soqlError) {
                    // If SOQL also fails, just continue with empty list
                    System.debug('Direct SOQL also failed: ' + soqlError.getMessage());
                    lineups = new List<Lineup__c>();
                }
            }
            
            Map<Id, Lineup__c> lineupMap = new Map<Id, Lineup__c>();
            for (Lineup__c lineup : lineups) {
                lineupMap.put(lineup.Team__c, lineup);
            }
            
            // Build home team lineup (return team info even if no lineup exists)
            if (match.Home_Team__c != null) {
                Account homeTeam = teamMap.get(match.Home_Team__c);
                if (lineupMap.containsKey(match.Home_Team__c)) {
                    Lineup__c homeLineup = lineupMap.get(match.Home_Team__c);
                    result.put('homeLineup', buildLineupData(homeLineup, homeTeam));
                } else if (homeTeam != null) {
                    // Return team info even when lineup doesn't exist
                    result.put('homeLineup', new Map<String, Object>{
                        'team' => new Map<String, Object>{
                            'id' => homeTeam.Id,
                            'name' => homeTeam.Name,
                            'logoUrl' => homeTeam.Team_Logo_URL__c != null ? homeTeam.Team_Logo_URL__c : homeTeam.Logo_Url__c
                        },
                        'hasLineup' => false
                    });
                }
            }
            
            // Build away team lineup (return team info even if no lineup exists)
            if (match.Away_Team__c != null) {
                Account awayTeam = teamMap.get(match.Away_Team__c);
                if (lineupMap.containsKey(match.Away_Team__c)) {
                    Lineup__c awayLineup = lineupMap.get(match.Away_Team__c);
                    result.put('awayLineup', buildLineupData(awayLineup, awayTeam));
                } else if (awayTeam != null) {
                    // Return team info even when lineup doesn't exist
                    result.put('awayLineup', new Map<String, Object>{
                        'team' => new Map<String, Object>{
                            'id' => awayTeam.Id,
                            'name' => awayTeam.Name,
                            'logoUrl' => awayTeam.Team_Logo_URL__c != null ? awayTeam.Team_Logo_URL__c : awayTeam.Logo_Url__c
                        },
                        'hasLineup' => false
                    });
                }
            }
            
            // Add hasLineups flag for UI
            result.put('hasLineups', !lineups.isEmpty());
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching match lineups: ' + e.getMessage());
        }
    }
    
    /**
     * @description Build lineup data structure from Lineup__c record
     * @param lineup Lineup__c record
     * @param team Account (Team) record
     * @return Map containing lineup data
     */
    private static Map<String, Object> buildLineupData(Lineup__c lineup, Account team) {
        Map<String, Object> lineupData = new Map<String, Object>();
        lineupData.put('id', lineup.Id);
        lineupData.put('formation', lineup.Formation__c);
        lineupData.put('lineupJSON', lineup.Lineup_JSON__c);
        lineupData.put('captainId', lineup.Captain__c);
        lineupData.put('hasLineup', true);
        
        if (team != null) {
            lineupData.put('team', new Map<String, Object>{
                'id' => team.Id,
                'name' => team.Name,
                'logoUrl' => team.Team_Logo_URL__c != null ? team.Team_Logo_URL__c : team.Logo_Url__c
            });
        }
        
        // Parse lineup JSON to get players
        if (String.isNotBlank(lineup.Lineup_JSON__c)) {
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(lineup.Lineup_JSON__c);
                lineupData.put('players', parsed);
            } catch (Exception e) {
                System.debug('Error parsing lineup JSON: ' + e.getMessage());
            }
        }
        
        return lineupData;
    }
    
    /**
     * @description Get all match moments (commentary/events)
     * @param matchId Match__c record ID
     * @return List of match moment maps
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getMatchMoments(String matchId) {
        try {
            List<Map<String, Object>> moments = new List<Map<String, Object>>();
            
            List<Match_Moment__c> matchMoments = [
                SELECT Id, Event_Minute__c, Event_Second__c, Event_Type__c, Event_Sub_Type__c,
                       Description__c, Event_Importance__c, Is_Shareable__c,
                       Primary_Player__r.Id, Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                       Secondary_Player__r.Id, Secondary_Player__r.Name,
                       Team__r.Id, Team__r.Name, Team__r.Team_Logo_URL__c,
                       Match_Period__r.Period_Type__c
                FROM Match_Moment__c
                WHERE Match__c = :matchId
                ORDER BY Event_Minute__c ASC, Event_Second__c ASC NULLS LAST
            ];
            
            for (Match_Moment__c moment : matchMoments) {
                Map<String, Object> momentData = new Map<String, Object>();
                momentData.put('id', moment.Id);
                momentData.put('minute', moment.Event_Minute__c);
                momentData.put('second', moment.Event_Second__c);
                momentData.put('eventType', moment.Event_Type__c);
                momentData.put('eventSubType', moment.Event_Sub_Type__c);
                momentData.put('description', moment.Description__c);
                momentData.put('importance', moment.Event_Importance__c);
                momentData.put('isShareable', moment.Is_Shareable__c);
                
                if (moment.Primary_Player__r != null) {
                    momentData.put('primaryPlayer', new Map<String, Object>{
                        'id' => moment.Primary_Player__r.Id,
                        'name' => moment.Primary_Player__r.Name,
                        'jerseyNumber' => moment.Primary_Player__r.Jersey_Number__c
                    });
                }
                
                if (moment.Secondary_Player__r != null) {
                    momentData.put('secondaryPlayer', new Map<String, Object>{
                        'id' => moment.Secondary_Player__r.Id,
                        'name' => moment.Secondary_Player__r.Name
                    });
                }
                
                if (moment.Team__r != null) {
                    momentData.put('team', new Map<String, Object>{
                        'id' => moment.Team__r.Id,
                        'name' => moment.Team__r.Name,
                        'logoUrl' => moment.Team__r.Team_Logo_URL__c
                    });
                }
                
                if (moment.Match_Period__r != null) {
                    momentData.put('periodType', moment.Match_Period__r.Period_Type__c);
                }
                
                moments.add(momentData);
            }
            
            return moments;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching match moments: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get league table/standings for the competition
     * @param competitionId Competition__c record ID
     * @param seasonYear Season year string (optional, uses current if not provided)
     * @return List of team season stats maps
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getLeagueTable(String competitionId, String seasonYear) {
        try {
            List<Map<String, Object>> table = new List<Map<String, Object>>();
            
            String whereClause = 'Competition__c = :competitionId';
            if (String.isNotBlank(seasonYear)) {
                whereClause += ' AND Season_Year__c = :seasonYear';
            }
            
            String soqlQuery = 'SELECT Id, Team__r.Id, Team__r.Name, Team__r.Team_Logo_URL__c, ' +
                               'League_Position__c, Points__c, Wins__c, Draws__c, Losses__c, ' +
                               'Goals_For__c, Goals_Against__c, Goal_Difference__c, Matches_Played__c, ' +
                               'Home_Wins__c, Home_Draws__c, Home_Losses__c, ' +
                               'Away_Wins__c, Away_Draws__c, Away_Losses__c ' +
                               'FROM Team_Season_Stats__c ' +
                               'WHERE Competition__c = :competitionId';
            
            if (String.isNotBlank(seasonYear)) {
                soqlQuery += ' AND Season_Year__c = :seasonYear';
            }
            
            soqlQuery += ' ORDER BY League_Position__c ASC NULLS LAST, Points__c DESC, Goal_Difference__c DESC';
            
            List<Team_Season_Stats__c> teamStats = Database.query(soqlQuery);
            
            for (Team_Season_Stats__c stat : teamStats) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('id', stat.Id);
                row.put('position', stat.League_Position__c);
                row.put('points', stat.Points__c);
                row.put('wins', stat.Wins__c);
                row.put('draws', stat.Draws__c);
                row.put('losses', stat.Losses__c);
                row.put('goalsFor', stat.Goals_For__c);
                row.put('goalsAgainst', stat.Goals_Against__c);
                row.put('goalDifference', stat.Goal_Difference__c);
                row.put('matchesPlayed', stat.Matches_Played__c);
                
                if (stat.Team__r != null) {
                    row.put('team', new Map<String, Object>{
                        'id' => stat.Team__r.Id,
                        'name' => stat.Team__r.Name,
                        'logoUrl' => stat.Team__r.Team_Logo_URL__c
                    });
                }
                
                table.add(row);
            }
            
            return table;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching league table: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get match statistics (possession, shots, cards, etc.)
     * @param matchId Match__c record ID
     * @return Map containing match statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMatchStats(String matchId) {
        try {
            Map<String, Object> stats = new Map<String, Object>();
            
            // Get match with stats JSON
            List<Match__c> matches = [
                SELECT Id, Match_Stats_JSON__c, Home_Team__c, Away_Team__c
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                throw new AuraHandledException('Match not found');
            }
            
            Match__c match = matches[0];
            
            // Parse JSON stats if available
            if (String.isNotBlank(match.Match_Stats_JSON__c)) {
                try {
                    Map<String, Object> jsonStats = (Map<String, Object>) JSON.deserializeUntyped(match.Match_Stats_JSON__c);
                    stats.putAll(jsonStats);
                } catch (Exception e) {
                    System.debug('Error parsing match stats JSON: ' + e.getMessage());
                }
            }
            
            // Aggregate stats from Match_Moment__c if JSON not available
            if (stats.isEmpty()) {
                stats = aggregateStatsFromMoments(matchId, match.Home_Team__c, match.Away_Team__c);
            }
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching match stats: ' + e.getMessage());
        }
    }
    
    /**
     * @description Aggregate statistics from Match_Moment__c records
     * @param matchId Match__c record ID
     * @param homeTeamId Home team Account ID
     * @param awayTeamId Away team Account ID
     * @return Map containing aggregated statistics
     */
    private static Map<String, Object> aggregateStatsFromMoments(String matchId, Id homeTeamId, Id awayTeamId) {
        Map<String, Object> stats = new Map<String, Object>();
        
        // Count cards by team
        List<Match_Moment__c> cards = [
            SELECT Team__c, Event_Type__c
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            AND (Event_Type__c = 'Yellow Card' OR Event_Type__c = 'Red Card')
        ];
        
        Integer homeYellowCards = 0;
        Integer awayYellowCards = 0;
        Integer homeRedCards = 0;
        Integer awayRedCards = 0;
        
        for (Match_Moment__c card : cards) {
            if (card.Team__c == homeTeamId) {
                if (card.Event_Type__c == 'Yellow Card') homeYellowCards++;
                else if (card.Event_Type__c == 'Red Card') homeRedCards++;
            } else if (card.Team__c == awayTeamId) {
                if (card.Event_Type__c == 'Yellow Card') awayYellowCards++;
                else if (card.Event_Type__c == 'Red Card') awayRedCards++;
            }
        }
        
        stats.put('homeYellowCards', homeYellowCards);
        stats.put('awayYellowCards', awayYellowCards);
        stats.put('homeRedCards', homeRedCards);
        stats.put('awayRedCards', awayRedCards);
        
        // Default possession (50/50 if not available)
        stats.put('homePossession', 50);
        stats.put('awayPossession', 50);
        
        return stats;
    }
    
    /**
     * @description Create a basic lineup from team players when no lineup exists
     * @param matchId Match__c record ID
     * @param teamId Account (Team) record ID
     * @return Map containing created lineup data
     */
    @AuraEnabled
    public static Map<String, Object> createLineupFromTeam(String matchId, String teamId) {
        try {
            // Verify match exists
            List<Match__c> matches = [
                SELECT Id, Home_Team__c, Away_Team__c
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                throw new AuraHandledException('Match not found');
            }
            
            Match__c match = matches[0];
            
            // Verify team is part of this match
            if (match.Home_Team__c != teamId && match.Away_Team__c != teamId) {
                throw new AuraHandledException('Team is not part of this match');
            }
            
            // Check if lineup already exists
            List<Lineup__c> existingLineups = [
                SELECT Id
                FROM Lineup__c
                WHERE Match__c = :matchId
                AND Team__c = :teamId
                LIMIT 1
            ];
            
            if (!existingLineups.isEmpty()) {
                throw new AuraHandledException('Lineup already exists for this team');
            }
            
            // Get team players - try both Current_Team__c and Team_Membership__c
            List<Contact> players = new List<Contact>();
            
            // First try Current_Team__c lookup
            players = [
                SELECT Id, Name, FirstName, LastName, Position__c, Jersey_Number__c
                FROM Contact
                WHERE Current_Team__c = :teamId
                ORDER BY Jersey_Number__c NULLS LAST, Name
                LIMIT 25
            ];
            
            // If no players found via Current_Team__c, try Team_Membership__c
            if (players.isEmpty()) {
                List<Team_Membership__c> memberships = [
                    SELECT Player__c
                    FROM Team_Membership__c
                    WHERE Team__c = :teamId
                    AND Status__c = 'Active'
                    LIMIT 25
                ];
                
                Set<Id> playerIds = new Set<Id>();
                for (Team_Membership__c membership : memberships) {
                    playerIds.add(membership.Player__c);
                }
                
                if (!playerIds.isEmpty()) {
                    players = [
                        SELECT Id, Name, FirstName, LastName, Position__c, Jersey_Number__c
                        FROM Contact
                        WHERE Id IN :playerIds
                        ORDER BY Jersey_Number__c NULLS LAST, Name
                    ];
                }
            }
            
            if (players.isEmpty()) {
                throw new AuraHandledException('No players found for this team. Please add players to the team first.');
            }
            
            // Build basic lineup structure
            Map<String, Object> lineupJson = new Map<String, Object>();
            List<Object> lines = new List<Object>();
            List<Object> bench = new List<Object>();
            Map<String, Object> goalkeeper = null;
            
            // Separate players by position
            List<Contact> goalkeepers = new List<Contact>();
            List<Contact> defenders = new List<Contact>();
            List<Contact> midfielders = new List<Contact>();
            List<Contact> forwards = new List<Contact>();
            List<Contact> others = new List<Contact>();
            
            for (Contact player : players) {
                String position = player.Position__c != null ? player.Position__c.toUpperCase() : '';
                if (position.contains('GK') || position.contains('GOALKEEPER')) {
                    goalkeepers.add(player);
                } else if (position.contains('D') || position.contains('DEFENDER') || position.contains('CB') || position.contains('LB') || position.contains('RB')) {
                    defenders.add(player);
                } else if (position.contains('M') || position.contains('MIDFIELDER') || position.contains('CM') || position.contains('AM')) {
                    midfielders.add(player);
                } else if (position.contains('F') || position.contains('FORWARD') || position.contains('ST') || position.contains('FW')) {
                    forwards.add(player);
                } else {
                    others.add(player);
                }
            }
            
            // Select starting XI (1 GK, 4-5 defenders, 3-4 midfielders, 1-2 forwards)
            Integer selectedCount = 0;
            Integer maxStarting = 11;
            
            // Goalkeeper
            if (!goalkeepers.isEmpty() && selectedCount < maxStarting) {
                Contact gk = goalkeepers[0];
                goalkeeper = new Map<String, Object>{
                    'playerId' => gk.Id,
                    'playerName' => gk.Name,
                    'jersey' => gk.Jersey_Number__c,
                    'position' => 'GK'
                };
                selectedCount++;
            }
            
            // Defenders (up to 5)
            List<Object> defLine = new List<Object>();
            Integer defCount = Math.min(defenders.size(), Math.min(5, maxStarting - selectedCount));
            for (Integer i = 0; i < defCount; i++) {
                Contact def = defenders[i];
                defLine.add(new Map<String, Object>{
                    'playerId' => def.Id,
                    'playerName' => def.Name,
                    'jersey' => def.Jersey_Number__c,
                    'position' => def.Position__c != null ? def.Position__c : 'D'
                });
                selectedCount++;
            }
            if (!defLine.isEmpty()) {
                lines.add(new Map<String, Object>{'players' => defLine});
            }
            
            // Midfielders (up to 4)
            List<Object> midLine = new List<Object>();
            Integer midCount = Math.min(midfielders.size(), Math.min(4, maxStarting - selectedCount));
            for (Integer i = 0; i < midCount; i++) {
                Contact mid = midfielders[i];
                midLine.add(new Map<String, Object>{
                    'playerId' => mid.Id,
                    'playerName' => mid.Name,
                    'jersey' => mid.Jersey_Number__c,
                    'position' => mid.Position__c != null ? mid.Position__c : 'M'
                });
                selectedCount++;
            }
            if (!midLine.isEmpty()) {
                lines.add(new Map<String, Object>{'players' => midLine});
            }
            
            // Forwards (up to 2)
            List<Object> fwdLine = new List<Object>();
            Integer fwdCount = Math.min(forwards.size(), Math.min(2, maxStarting - selectedCount));
            for (Integer i = 0; i < fwdCount; i++) {
                Contact fwd = forwards[i];
                fwdLine.add(new Map<String, Object>{
                    'playerId' => fwd.Id,
                    'playerName' => fwd.Name,
                    'jersey' => fwd.Jersey_Number__c,
                    'position' => fwd.Position__c != null ? fwd.Position__c : 'F'
                });
                selectedCount++;
            }
            if (!fwdLine.isEmpty()) {
                lines.add(new Map<String, Object>{'players' => fwdLine});
            }
            
            // Fill remaining spots with others if needed
            if (selectedCount < maxStarting && !others.isEmpty()) {
                List<Object> otherLine = new List<Object>();
                Integer otherCount = Math.min(others.size(), maxStarting - selectedCount);
                for (Integer i = 0; i < otherCount; i++) {
                    Contact other = others[i];
                    otherLine.add(new Map<String, Object>{
                        'playerId' => other.Id,
                        'playerName' => other.Name,
                        'jersey' => other.Jersey_Number__c,
                        'position' => other.Position__c != null ? other.Position__c : 'M'
                    });
                    selectedCount++;
                }
                if (!otherLine.isEmpty()) {
                    lines.add(new Map<String, Object>{'players' => otherLine});
                }
            }
            
            // Add remaining players to bench
            Integer benchStart = selectedCount;
            for (Integer i = benchStart; i < players.size(); i++) {
                Contact player = players[i];
                bench.add(new Map<String, Object>{
                    'playerId' => player.Id,
                    'playerName' => player.Name,
                    'jersey' => player.Jersey_Number__c,
                    'position' => player.Position__c != null ? player.Position__c : 'SUB'
                });
            }
            
            // Build lineup JSON
            lineupJson.put('goalkeeper', goalkeeper);
            lineupJson.put('lines', lines);
            lineupJson.put('bench', bench);
            
            // Determine formation (e.g., 4-4-2)
            String formation = determineFormation(defLine.size(), midLine.size(), fwdLine.size());
            
            // Create Lineup__c record
            Lineup__c lineup = new Lineup__c();
            lineup.Match__c = matchId;
            lineup.Team__c = teamId;
            lineup.Formation__c = formation;
            lineup.Lineup_JSON__c = JSON.serialize(lineupJson);
            lineup.Starting_XI_Count__c = selectedCount;
            
            insert lineup;
            
            // Get team info for response
            Account team = [
                SELECT Id, Name, Team_Logo_URL__c, Logo_Url__c
                FROM Account
                WHERE Id = :teamId
                LIMIT 1
            ];
            
            // Return lineup data in same format as getMatchLineups
            Map<String, Object> result = new Map<String, Object>();
            result.put('lineup', buildLineupData(lineup, team));
            result.put('success', true);
            result.put('message', 'Lineup created successfully');
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating lineup: ' + e.getMessage());
        }
    }
    
    /**
     * @description Determine formation string based on player counts
     * @param defenders Number of defenders
     * @param midfielders Number of midfielders
     * @param forwards Number of forwards
     * @return Formation string (e.g., "4-4-2")
     */
    private static String determineFormation(Integer defenders, Integer midfielders, Integer forwards) {
        // Common formations
        if (defenders == 4 && midfielders == 4 && forwards == 2) return '4-4-2';
        if (defenders == 4 && midfielders == 3 && forwards == 3) return '4-3-3';
        if (defenders == 4 && midfielders == 5 && forwards == 1) return '4-5-1';
        if (defenders == 3 && midfielders == 5 && forwards == 2) return '3-5-2';
        if (defenders == 5 && midfielders == 3 && forwards == 2) return '5-3-2';
        if (defenders == 3 && midfielders == 4 && forwards == 3) return '3-4-3';
        
        // Default: return actual counts
        return defenders + '-' + midfielders + '-' + forwards;
    }
    
    /**
     * @description Sync lineups from ESPN API for a match
     * @param matchId Match__c record ID
     * @return Map containing sync result
     */
    @AuraEnabled
    public static Map<String, Object> syncLineupsFromESPN(String matchId) {
        fflib_ISObjectUnitOfWork uow = null;
        
        try {
            // Validate matchId parameter
            if (String.isBlank(matchId)) {
                throw new AuraHandledException('Match ID is required. Please provide a valid match record ID.');
            }
            
            // Get match with ESPN Event ID and related data
            List<Match__c> matches = [
                SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, Competition__c, Competition__r.Sport__c, 
                       Competition__r.ESPN_League_ID__c, Home_Team__c, Away_Team__c,
                       Home_Team__r.Name, Away_Team__r.Name
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                throw new AuraHandledException('Match not found with ID: ' + matchId + '. Please verify the match exists.');
            }
            
            Match__c match = matches[0];
            
            // Validate Competition and Sport data
            if (match.Competition__c == null) {
                throw new AuraHandledException('This match is not linked to a Competition. Please set the Competition__c field before syncing lineups.');
            }
            
            String sportType = (match.Competition__r != null && match.Competition__r.Sport__c != null)
                ? match.Competition__r.Sport__c : 'Soccer';
            String leagueCode = (match.Competition__r != null && match.Competition__r.ESPN_League_ID__c != null)
                ? match.Competition__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // Normalize sport for ESPN API
            // Special handling: If league code indicates soccer (e.g., eng.1, uefa.champions) 
            // but sport is "Football", it should be treated as "Soccer" for ESPN API
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            if (espnSport == 'football' && String.isNotBlank(leagueCode)) {
                // Check if league code is a soccer league (not NFL)
                String leagueLower = leagueCode.toLowerCase();
                if (leagueLower.startsWith('eng.') || leagueLower.startsWith('uefa.') || 
                    leagueLower.startsWith('esp.') || leagueLower.startsWith('ita.') ||
                    leagueLower.startsWith('fra.') || leagueLower.startsWith('ger.') ||
                    leagueLower.startsWith('usa.mls') || leagueLower.contains('champions') ||
                    leagueLower.contains('europa') || leagueLower.startsWith('aus.')) {
                    espnSport = 'soccer';
                    System.debug(LoggingLevel.INFO, 'Detected soccer league code "' + leagueCode + '" - using "soccer" instead of "football" for ESPN API');
                }
            }
            
            // Validate teams are present
            if (match.Home_Team__c == null && match.Away_Team__c == null) {
                throw new AuraHandledException('This match does not have home or away teams assigned. Please set Home_Team__c and Away_Team__c before syncing lineups.');
            }
            
            // Try to find ESPN Event ID if missing
            String eventId = match.ESPN_Event_ID__c;
            if (String.isBlank(eventId)) {
                System.debug(LoggingLevel.INFO, 'ESPN_Event_ID__c is blank, attempting to search for Event ID by date and teams');
                eventId = searchESPNEventId(match, espnSport, leagueCode);
                
                if (String.isNotBlank(eventId)) {
                    // Update the match record with the found Event ID
                    try {
                        match.ESPN_Event_ID__c = eventId;
                        update match;
                        System.debug(LoggingLevel.INFO, 'Successfully found and set ESPN_Event_ID__c: ' + eventId);
                    } catch (Exception updateEx) {
                        System.debug(LoggingLevel.WARN, 'Found Event ID but failed to update match record: ' + updateEx.getMessage());
                        // Continue with the found Event ID even if update fails
                    }
                } else {
                    throw new AuraHandledException('ESPN Event ID is required to sync lineups. Could not automatically find the Event ID. Please set the ESPN_Event_ID__c field on this match record, or ensure the match has a valid Match_Date_Time__c and teams with ESPN_Team_ID__c set.');
                }
            }
            
            System.debug('MatchSummaryController: SportType=' + sportType + ', ESPN Sport=' + espnSport + ', LeagueCode=' + leagueCode + ', EventId=' + eventId);
            
            // Get match summary from ESPN with error handling
            ESPNHttpService.ESPNMatchSummaryResponse response;
            try {
                response = ESPNHttpService.getMatchSummaryDetailed(espnSport, leagueCode, eventId);
            } catch (ESPNHttpService.ESPNException espnEx) {
                String errorMsg = 'Failed to fetch lineup data from ESPN API. ';
                if (espnEx.getMessage().contains('timeout') || espnEx.getMessage().contains('Timeout')) {
                    errorMsg += 'The request timed out. Please try again in a moment.';
                } else if (espnEx.getMessage().contains('404') || espnEx.getMessage().contains('Not Found')) {
                    errorMsg += 'The ESPN Event ID "' + eventId + '" was not found. ';
                    errorMsg += 'Please verify: (1) ESPN_Event_ID__c is correct, (2) Sport__c is set correctly (use "Soccer" not "Football" for soccer matches), (3) ESPN_League_ID__c matches the league.';
                } else if (espnEx.getMessage().contains('500') || espnEx.getMessage().contains('Server Error') || espnEx.getMessage().contains('502') || espnEx.getMessage().contains('503')) {
                    errorMsg += 'ESPN API returned a server error. ';
                    errorMsg += 'This may indicate: (1) Wrong sport/league combination (e.g., "Football" with soccer league code), (2) ESPN API temporarily unavailable. ';
                    errorMsg += 'Please verify Sport__c and ESPN_League_ID__c are correct for this match.';
                } else {
                    errorMsg += espnEx.getMessage();
                }
                System.debug(LoggingLevel.ERROR, 'ESPN API Error: ' + espnEx.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + espnEx.getStackTraceString());
                System.debug(LoggingLevel.ERROR, 'Match Sport=' + sportType + ', ESPN Sport=' + espnSport + ', League=' + leagueCode);
                throw new AuraHandledException(errorMsg);
            }
            
            // Validate response
            if (response == null) {
                throw new AuraHandledException('Received null response from ESPN API. Please try again.');
            }
            
            if (!response.success) {
                String errorMsg = 'ESPN API returned an error. ';
                if (String.isNotBlank(response.errorMessage)) {
                    errorMsg += response.errorMessage;
                } else {
                    errorMsg += 'Please verify the ESPN Event ID is correct and try again.';
                }
                throw new AuraHandledException(errorMsg);
            }
            
            if (response.lineups == null || response.lineups.isEmpty()) {
                throw new AuraHandledException('No lineup data is available from ESPN for this match (Event ID: ' + eventId + '). The match may not have started or lineups may not be published yet.');
            }
            
            // Map ESPN team IDs to Salesforce team IDs with validation
            Map<String, Id> teamIdMap = new Map<String, Id>();
            List<String> missingTeamMappings = new List<String>();
            
            if (match.Home_Team__c != null && String.isNotBlank(response.homeTeamId)) {
                teamIdMap.put(response.homeTeamId, match.Home_Team__c);
            } else if (String.isNotBlank(response.homeTeamId)) {
                missingTeamMappings.add('Home team (ESPN ID: ' + response.homeTeamId + ')');
            }
            
            if (match.Away_Team__c != null && String.isNotBlank(response.awayTeamId)) {
                teamIdMap.put(response.awayTeamId, match.Away_Team__c);
            } else if (String.isNotBlank(response.awayTeamId)) {
                missingTeamMappings.add('Away team (ESPN ID: ' + response.awayTeamId + ')');
            }
            
            if (teamIdMap.isEmpty()) {
                throw new AuraHandledException('Unable to map ESPN teams to Salesforce teams. Please ensure Home_Team__c and Away_Team__c are set correctly on the match record.');
            }
            
            if (!missingTeamMappings.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'Some teams could not be mapped: ' + String.join(missingTeamMappings, ', '));
            }
            
            // Create UOW for bulk operations
            uow = Application.UnitOfWork.newInstance();
            Integer lineupCount = 0;
            Integer participationCount = 0;
            List<String> processingErrors = new List<String>();
            
            // Query existing lineups and participations to avoid duplicates
            Map<Id, Lineup__c> existingLineupsMap = new Map<Id, Lineup__c>();
            List<Lineup__c> existingLineups = [
                SELECT Id, Team__c
                FROM Lineup__c
                WHERE Match__c = :matchId
            ];
            for (Lineup__c existing : existingLineups) {
                existingLineupsMap.put(existing.Team__c, existing);
            }
            
            // Query existing participations to delete before creating new ones
            Map<Id, List<Match_Participation__c>> existingParticipationsMap = new Map<Id, List<Match_Participation__c>>();
            List<Match_Participation__c> existingParticipations = [
                SELECT Id, Team__c
                FROM Match_Participation__c
                WHERE Match__c = :matchId
            ];
            for (Match_Participation__c existing : existingParticipations) {
                if (!existingParticipationsMap.containsKey(existing.Team__c)) {
                    existingParticipationsMap.put(existing.Team__c, new List<Match_Participation__c>());
                }
                existingParticipationsMap.get(existing.Team__c).add(existing);
            }
            
            // Process each lineup from ESPN
            for (ESPNHttpService.ESPNLineup espnLineup : response.lineups) {
                try {
                    Id teamId = teamIdMap.get(espnLineup.teamId);
                    if (teamId == null) {
                        String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                        System.debug(LoggingLevel.WARN, 'Team ID not found for ESPN team: ' + teamName + ' (ESPN ID: ' + espnLineup.teamId + ')');
                        processingErrors.add('Could not sync lineup for ' + teamName + ' - team not found in Salesforce');
                        continue;
                    }
                    
                // Parse lineup data (players are created immediately if needed)
                Map<String, Object> lineupData;
                try {
                    lineupData = ESPNDataParser.parseLineupToLineup(espnLineup, matchId, teamId, uow);
                    
                    // Check for errors and warnings from parser
                    List<String> parserErrors = (List<String>) lineupData.get('errors');
                    List<String> parserWarnings = (List<String>) lineupData.get('warnings');
                    
                    if (parserErrors != null && !parserErrors.isEmpty()) {
                        String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                        processingErrors.add('Error parsing lineup for ' + teamName + ': ' + String.join(parserErrors, '; '));
                    }
                    
                    if (parserWarnings != null && !parserWarnings.isEmpty()) {
                        String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                        for (String warning : parserWarnings) {
                            System.debug(LoggingLevel.WARN, 'Lineup parser warning for ' + teamName + ': ' + warning);
                        }
                    }
                    
                } catch (Exception parseEx) {
                    String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                    System.debug(LoggingLevel.ERROR, 'Error parsing lineup for team ' + teamName + ': ' + parseEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + parseEx.getStackTraceString());
                    processingErrors.add('Error parsing lineup for ' + teamName + ': ' + parseEx.getMessage());
                    continue;
                }
                
                // Null safety check for lineupData
                if (lineupData == null) {
                    String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                    System.debug(LoggingLevel.ERROR, 'Lineup data is null for team: ' + teamName);
                    processingErrors.add('Failed to parse lineup data for ' + teamName + ' - parser returned null');
                    continue;
                }
                
                Lineup__c lineupRecord = (Lineup__c) lineupData.get('lineup');
                    
                    if (lineupRecord != null) {
                        // Check if lineup already exists
                        if (existingLineupsMap.containsKey(teamId)) {
                            lineupRecord.Id = existingLineupsMap.get(teamId).Id;
                            uow.registerDirty(lineupRecord);
                        } else {
                            uow.registerNew(lineupRecord);
                        }
                        
                        // Handle Match_Participation__c records
                        List<Match_Participation__c> participations = 
                            (List<Match_Participation__c>) lineupData.get('participations');
                        
                        if (participations != null && !participations.isEmpty()) {
                            // Delete existing participations for this team
                            if (existingParticipationsMap.containsKey(teamId)) {
                                uow.registerDeleted(existingParticipationsMap.get(teamId));
                            }
                            
                            // Register new participations with validation
                            for (Match_Participation__c participation : participations) {
                                if (participation.Player__c != null) {
                                    uow.registerNew(participation);
                                    participationCount++;
                                } else {
                                    System.debug(LoggingLevel.WARN, 'Skipping participation with null player ID for team: ' + teamId);
                                }
                            }
                        }
                        
                        lineupCount++;
                    }
                } catch (Exception lineupEx) {
                    String teamName = String.isNotBlank(espnLineup.teamName) ? espnLineup.teamName : espnLineup.teamId;
                    System.debug(LoggingLevel.ERROR, 'Error processing lineup for team ' + teamName + ': ' + lineupEx.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + lineupEx.getStackTraceString());
                    processingErrors.add('Error processing lineup for ' + teamName + ': ' + lineupEx.getMessage());
                }
            }
            
            if (lineupCount == 0) {
                String errorMsg = 'No lineups were successfully processed. ';
                if (!processingErrors.isEmpty()) {
                    errorMsg += String.join(processingErrors, '; ');
                } else {
                    errorMsg += 'Please check that teams are properly mapped and try again.';
                }
                throw new AuraHandledException(errorMsg);
            }
            
            // Commit all changes with detailed error handling
            try {
                uow.commitWork();
            } catch (DmlException dmlEx) {
                // Extract detailed DML error information
                String errorMsg = 'Error saving lineup data to Salesforce. ';
                
                if (dmlEx.getNumDml() > 0) {
                    List<String> dmlErrors = new List<String>();
                    for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                        String recordError = dmlEx.getDmlMessage(i);
                        if (dmlEx.getDmlFieldNames(i) != null && !dmlEx.getDmlFieldNames(i).isEmpty()) {
                            recordError += ' (Fields: ' + String.join(dmlEx.getDmlFieldNames(i), ', ') + ')';
                        }
                        dmlErrors.add('Record ' + (i + 1) + ': ' + recordError);
                    }
                    errorMsg += String.join(dmlErrors, '; ');
                } else {
                    errorMsg += dmlEx.getMessage();
                }
                
                System.debug(LoggingLevel.ERROR, 'DML Error: ' + errorMsg);
                System.debug(LoggingLevel.ERROR, 'DML Type: ' + dmlEx.getDmlType(0));
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + dmlEx.getStackTraceString());
                
                throw new AuraHandledException(errorMsg);
            } catch (Exception commitEx) {
                System.debug(LoggingLevel.ERROR, 'Error committing changes: ' + commitEx.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + commitEx.getStackTraceString());
                throw new AuraHandledException('Error saving lineup data: ' + commitEx.getMessage());
            }
            
            // Reload lineups after sync
            Map<String, Object> lineupData = getMatchLineups(matchId);
            
            // Build success message
            String successMessage = 'Successfully synced ' + lineupCount + ' lineup' + (lineupCount != 1 ? 's' : '') + 
                                   ' with ' + participationCount + ' player participation' + (participationCount != 1 ? 's' : '') + '.';
            
            if (!processingErrors.isEmpty()) {
                successMessage += ' Note: Some lineups had issues: ' + String.join(processingErrors, '; ');
            }
            
            return new Map<String, Object>{
                'success' => true,
                'message' => successMessage,
                'lineups' => lineupData,
                'lineupCount' => lineupCount,
                'participationCount' => participationCount,
                'warnings' => processingErrors
            };
            
        } catch (AuraHandledException e) {
            // Re-throw AuraHandledException as-is (already user-friendly)
            throw e;
        } catch (DmlException e) {
            // Handle DML errors with detailed field information
            String errorMsg = 'Error saving lineup data: ' + e.getMessage();
            if (e.getNumDml() > 0 && e.getDmlFieldNames(0) != null && !e.getDmlFieldNames(0).isEmpty()) {
                errorMsg += ' (Fields: ' + String.join(e.getDmlFieldNames(0), ', ') + ')';
            }
            System.debug(LoggingLevel.ERROR, 'DML Error: ' + errorMsg);
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException(errorMsg);
        } catch (Exception e) {
            // Log full exception for debugging
            System.debug(LoggingLevel.ERROR, 'Unexpected error syncing lineups from ESPN: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Provide user-friendly error message
            String errorMsg = 'An unexpected error occurred while syncing lineups. ';
            if (e.getMessage().contains('null pointer') || e.getMessage().contains('NullPointerException')) {
                errorMsg += 'A required field may be missing. Please verify all match data is complete.';
            } else if (e.getMessage().contains('governor') || e.getMessage().contains('limit')) {
                errorMsg += 'Salesforce governor limits were exceeded. Please try syncing fewer lineups at once.';
            } else {
                errorMsg += 'Please contact your administrator if this issue persists.';
            }
            
            throw new AuraHandledException(errorMsg);
        }
    }
    
    /**
     * @description Search for ESPN Event ID by matching date and teams
     * @param match Match__c record to search for
     * @param espnSport ESPN sport code
     * @param leagueCode ESPN league code
     * @return ESPN Event ID if found, null otherwise
     */
    private static String searchESPNEventId(Match__c match, String espnSport, String leagueCode) {
        try {
            // Get match date
            Date matchDate = match.Match_Date_Time__c != null 
                ? match.Match_Date_Time__c.date() : Date.today();
            String dateStr = matchDate.year() + 
                String.valueOf(matchDate.month()).leftPad(2, '0') + 
                String.valueOf(matchDate.day()).leftPad(2, '0');
            
            // Get team ESPN IDs if available
            Set<Id> teamIds = new Set<Id>();
            if (match.Home_Team__c != null) teamIds.add(match.Home_Team__c);
            if (match.Away_Team__c != null) teamIds.add(match.Away_Team__c);
            
            Map<Id, String> teamEspnIdMap = new Map<Id, String>();
            Map<Id, String> teamNameMap = new Map<Id, String>();
            
            if (!teamIds.isEmpty()) {
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
            
            // Search ESPN scoreboard for the date
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'No events found in ESPN scoreboard for date: ' + dateStr);
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
                        System.debug(LoggingLevel.INFO, 'Matched event by team ESPN IDs: ' + event.id + ' (' + event.name + ')');
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
                            System.debug(LoggingLevel.INFO, 'Matched event by team names: ' + event.id + ' (' + event.name + ')');
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
                            System.debug(LoggingLevel.INFO, 'Matched event by individual team names: ' + event.id + ' (' + event.name + ')');
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
                            System.debug(LoggingLevel.INFO, 'Matched event by match name: ' + event.id + ' (' + event.name + ')');
                            return event.id;
                        }
                    }
                }
            }
            
            System.debug(LoggingLevel.WARN, 'Could not find matching ESPN event for match: ' + match.Name);
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error searching for ESPN Event ID: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
}

