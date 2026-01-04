/**
 * @description Anonymous Apex script to fix Match record ESPN Event ID
 * Fixes the specific match record (a0PgL000000fTZ7UAM) by setting ESPN_Event_ID__c to '740776'
 * Based on ESPN URL: https://www.espn.com.au/football/commentary/_/gameId/740776
 * 
 * Usage: Execute this script in Developer Console or VS Code
 * @author Brendan Milton
 * @date 2025-12-31
 */

// Match record ID from the error
Id matchId = 'a0PgL000000fTZ7UAM';
String eventId = '740776';

try {
    // Query the match record
    List<Match__c> matches = [
        SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, 
               Competition__c, Competition__r.Sport__c, Competition__r.ESPN_League_ID__c,
               Home_Team__c, Away_Team__c,
               Home_Team__r.Name, Home_Team__r.ESPN_Team_ID__c,
               Away_Team__r.Name, Away_Team__r.ESPN_Team_ID__c
        FROM Match__c
        WHERE Id = :matchId
        LIMIT 1
    ];
    
    if (matches.isEmpty()) {
        System.debug('ERROR: Match record not found with ID: ' + matchId);
        return;
    }
    
    Match__c match = matches[0];
    
    System.debug('Found match: ' + match.Name);
    System.debug('Current ESPN_Event_ID__c: ' + match.ESPN_Event_ID__c);
    System.debug('Match Date: ' + match.Match_Date_Time__c);
    System.debug('Competition: ' + (match.Competition__c != null ? match.Competition__r.Sport__c : 'N/A'));
    System.debug('Home Team: ' + (match.Home_Team__c != null ? match.Home_Team__r.Name : 'N/A'));
    System.debug('Away Team: ' + (match.Away_Team__c != null ? match.Away_Team__r.Name : 'N/A'));
    
    // Set the ESPN Event ID
    match.ESPN_Event_ID__c = eventId;
    
    // Update the record
    update match;
    
    System.debug('SUCCESS: Updated match ' + match.Id + ' with ESPN_Event_ID__c = ' + eventId);
    
    // Verify the update
    Match__c updatedMatch = [SELECT Id, Name, ESPN_Event_ID__c FROM Match__c WHERE Id = :matchId LIMIT 1];
    System.debug('Verification - ESPN_Event_ID__c: ' + updatedMatch.ESPN_Event_ID__c);
    
    // Check related records count (simplified queries to avoid FLS issues)
    Integer lineupCount = [SELECT COUNT() FROM Lineup__c WHERE Match__c = :matchId];
    System.debug('Related Lineup__c records: ' + lineupCount);
    
    Integer participationCount = [SELECT COUNT() FROM Match_Participation__c WHERE Match__c = :matchId];
    System.debug('Related Match_Participation__c records: ' + participationCount);
    
    System.debug('Fix complete! The match record now has ESPN_Event_ID__c set to ' + eventId);
    System.debug('You can now sync lineups from ESPN using the match record page.');
    
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

