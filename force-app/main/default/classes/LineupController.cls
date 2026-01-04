/**
 * LineupController
 * 
 * Apex controller for Lineup Builder LWC component
 * Handles player data retrieval and lineup persistence
 * 
 * JAVASCRIPT DEVELOPER I EXAM RELEVANCE:
 * - Server-Side JavaScript (8% of exam)
 * - Understanding Apex-JavaScript integration
 * - Data serialization between Apex and JavaScript
 */
public with sharing class LineupController {
    
    /**
     * Get teams participating in a match
     * 
     * @param matchId Match record ID
     * @return List of Account (Team) records
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getMatchTeams(String matchId) {
        try {
            // Query match to get home and away teams
            List<Match__c> matches = [
                SELECT Id, Home_Team__c, Away_Team__c,
                       Home_Team__r.Name, Away_Team__r.Name
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            if (matches.isEmpty()) {
                return new List<Account>();
            }
            
            Match__c match = matches[0];
            Set<Id> teamIds = new Set<Id>();
            
            if (match.Home_Team__c != null) {
                teamIds.add(match.Home_Team__c);
            }
            if (match.Away_Team__c != null) {
                teamIds.add(match.Away_Team__c);
            }
            
            // Return full team records
            return [
                SELECT Id, Name, Sport_Type__c
                FROM Account
                WHERE Id IN :teamIds
                ORDER BY Name
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching match teams: ' + e.getMessage());
        }
    }
    
    /**
     * Get all players for a team
     * 
     * @param teamId Account (Team) record ID
     * @return List of Contact (Player) records
     * 
     * EXAM CONCEPT: SOQL queries and relationships
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getTeamPlayers(String teamId) {
        try {
            // Query players (Contacts) for the team
            // Uses Team_Membership__c junction object for current team
            
            // First, get active team memberships
            List<Team_Membership__c> memberships = [
                SELECT Player__c
                FROM Team_Membership__c
                WHERE Team__c = :teamId
                AND Status__c = 'Active'
            ];
            
            Set<Id> playerIds = new Set<Id>();
            for (Team_Membership__c membership : memberships) {
                playerIds.add(membership.Player__c);
            }
            
            // Query full player details
            return [
                SELECT Id, Name, FirstName, LastName, 
                       Position__c, Jersey_Number__c,
                       Profile_Image_URL__c
                FROM Contact
                WHERE Id IN :playerIds
                ORDER BY Jersey_Number__c NULLS LAST, Name
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching team players: ' + e.getMessage());
        }
    }
    
    /**
     * Save lineup to Salesforce
     * 
     * @param lineupData Map containing lineup information
     * @return String Lineup record ID
     * 
     * EXAM CONCEPT: DML operations, JSON handling
     */
    @AuraEnabled
    public static String saveLineup(Map<String, Object> lineupData) {
        try {
            // Extract parameters
            String matchId = (String) lineupData.get('matchId');
            String teamId = (String) lineupData.get('teamId');
            String formation = (String) lineupData.get('formation');
            String captainId = (String) lineupData.get('captainId');
            String lineupJSON = (String) lineupData.get('lineupJSON');
            
            // Check if lineup already exists for this match/team
            List<Lineup__c> existingLineups = [
                SELECT Id
                FROM Lineup__c
                WHERE Match__c = :matchId
                AND Team__c = :teamId
                LIMIT 1
            ];
            
            Lineup__c lineup;
            
            if (!existingLineups.isEmpty()) {
                // Update existing lineup
                lineup = existingLineups[0];
            } else {
                // Create new lineup
                lineup = new Lineup__c();
                lineup.Match__c = matchId;
                lineup.Team__c = teamId;
            }
            
            // Set fields
            lineup.Formation__c = formation;
            lineup.Captain__c = captainId;
            lineup.Lineup_JSON__c = lineupJSON;
            
            // Extract starting XI count from JSON
            Map<String, Object> parsedLineup = (Map<String, Object>) JSON.deserializeUntyped(lineupJSON);
            Integer startingCount = countStartingXI(parsedLineup);
            lineup.Starting_XI_Count__c = startingCount;
            
            // Save lineup
            upsert lineup;
            
            // Create Match_Participation__c records for each player
            createMatchParticipations(lineup.Id, matchId, teamId, parsedLineup);
            
            return lineup.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving lineup: ' + e.getMessage());
        }
    }
    
    /**
     * Count players in starting XI
     */
    private static Integer countStartingXI(Map<String, Object> lineupData) {
        Integer count = 0;
        
        // Count goalkeeper
        if (lineupData.get('goalkeeper') != null) {
            count++;
        }
        
        // Count players in formation lines
        List<Object> lines = (List<Object>) lineupData.get('lines');
        if (lines != null) {
            for (Object lineObj : lines) {
                Map<String, Object> line = (Map<String, Object>) lineObj;
                List<Object> players = (List<Object>) line.get('players');
                if (players != null) {
                    count += players.size();
                }
            }
        }
        
        return count;
    }
    
    /**
     * Create Match_Participation__c records
     */
    private static void createMatchParticipations(String lineupId, String matchId, 
                                                  String teamId, Map<String, Object> lineupData) {
        // Delete existing participations for this match/team
        List<Match_Participation__c> existingParticipations = [
            SELECT Id
            FROM Match_Participation__c
            WHERE Match__c = :matchId
            AND Team__c = :teamId
        ];
        
        if (!existingParticipations.isEmpty()) {
            delete existingParticipations;
        }
        
        List<Match_Participation__c> participations = new List<Match_Participation__c>();
        
        // Add goalkeeper
        Map<String, Object> gkData = (Map<String, Object>) lineupData.get('goalkeeper');
        if (gkData != null) {
            Match_Participation__c gkParticipation = new Match_Participation__c();
            gkParticipation.Match__c = matchId;
            gkParticipation.Team__c = teamId;
            gkParticipation.Player__c = (String) gkData.get('playerId');
            gkParticipation.Position__c = 'GK';
            gkParticipation.Role__c = 'Player';
            gkParticipation.Starting_Lineup__c = true;
            // Jersey_Number__c is on Contact, not Match_Participation__c
            participations.add(gkParticipation);
        }
        
        // Add players from formation lines
        List<Object> lines = (List<Object>) lineupData.get('lines');
        if (lines != null) {
            for (Object lineObj : lines) {
                Map<String, Object> line = (Map<String, Object>) lineObj;
                List<Object> players = (List<Object>) line.get('players');
                
                if (players != null) {
                    for (Object playerObj : players) {
                        Map<String, Object> player = (Map<String, Object>) playerObj;
                        
                        Match_Participation__c participation = new Match_Participation__c();
                        participation.Match__c = matchId;
                        participation.Team__c = teamId;
                        participation.Player__c = (String) player.get('playerId');
                        participation.Position__c = (String) player.get('position');
                        participation.Role__c = 'Player';
                        participation.Starting_Lineup__c = true;
                        // Jersey_Number__c is on Contact, not Match_Participation__c
                        participations.add(participation);
                    }
                }
            }
        }
        
        // Add bench players
        List<Object> bench = (List<Object>) lineupData.get('bench');
        if (bench != null) {
            for (Object playerObj : bench) {
                Map<String, Object> player = (Map<String, Object>) playerObj;
                
                Match_Participation__c participation = new Match_Participation__c();
                participation.Match__c = matchId;
                participation.Team__c = teamId;
                participation.Player__c = (String) player.get('playerId');
                participation.Position__c = (String) player.get('position');
                participation.Role__c = 'Player';
                participation.Substitute__c = true;
                // Jersey_Number__c is on Contact, not Match_Participation__c
                participations.add(participation);
            }
        }
        
        if (!participations.isEmpty()) {
            insert participations;
        }
    }
    
    /**
     * Get existing lineup for a match
     * 
     * @param matchId Match record ID
     * @param teamId Team record ID
     * @return Lineup__c record or null
     */
    @AuraEnabled(cacheable=true)
    public static Lineup__c getExistingLineup(String matchId, String teamId) {
        try {
            List<Lineup__c> lineups = [
                SELECT Id, Formation__c, Captain__c, Lineup_JSON__c,
                       Starting_XI_Count__c
                FROM Lineup__c
                WHERE Match__c = :matchId
                AND Team__c = :teamId
                LIMIT 1
            ];
            
            return lineups.isEmpty() ? null : lineups[0];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching lineup: ' + e.getMessage());
        }
    }
}