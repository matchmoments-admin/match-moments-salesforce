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
            
            // Query lineups
            List<Lineup__c> lineups = LineupsSelector.newInstance().selectByMatchIds(new Set<Id>{matchId});
            
            // Query teams for additional data
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
            Map<Id, Lineup__c> lineupMap = new Map<Id, Lineup__c>();
            
            for (Lineup__c lineup : lineups) {
                lineupMap.put(lineup.Team__c, lineup);
            }
            
            // Build home team lineup
            if (match.Home_Team__c != null && lineupMap.containsKey(match.Home_Team__c)) {
                Lineup__c homeLineup = lineupMap.get(match.Home_Team__c);
                Account homeTeam = teamMap.get(match.Home_Team__c);
                result.put('homeLineup', buildLineupData(homeLineup, homeTeam));
            }
            
            // Build away team lineup
            if (match.Away_Team__c != null && lineupMap.containsKey(match.Away_Team__c)) {
                Lineup__c awayLineup = lineupMap.get(match.Away_Team__c);
                Account awayTeam = teamMap.get(match.Away_Team__c);
                result.put('awayLineup', buildLineupData(awayLineup, awayTeam));
            }
            
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
}

