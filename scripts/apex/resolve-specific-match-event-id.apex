/**
 * @description Quick script to resolve ESPN Event ID for a specific match
 * Usage: Update the matchId variable below and execute in Developer Console
 * @author Brendan Milton
 * @date 2025-12-31
 */

Id matchId = 'a0PgL000000fTZ7UAM'; // Update this with your match ID

try {
    // Query the match with all required fields
    List<Match__c> matches = [
        SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, Match_Level__c,
               Competition__c, Competition__r.Sport__c, Competition__r.ESPN_League_ID__c,
               Home_Team__c, Away_Team__c,
               Home_Team__r.Name, Home_Team__r.ESPN_Team_ID__c,
               Away_Team__r.Name, Away_Team__r.ESPN_Team_ID__c
        FROM Match__c
        WHERE Id = :matchId
        LIMIT 1
    ];
    
    if (matches.isEmpty()) {
        System.debug('ERROR: Match not found with ID: ' + matchId);
        return;
    }
    
    Match__c match = matches[0];
    
    System.debug('=== Match Details ===');
    System.debug('Name: ' + match.Name);
    System.debug('Current ESPN_Event_ID__c: ' + (String.isBlank(match.ESPN_Event_ID__c) ? '(blank)' : match.ESPN_Event_ID__c));
    System.debug('Match_Date_Time__c: ' + match.Match_Date_Time__c);
    System.debug('Match_Level__c: ' + match.Match_Level__c);
    System.debug('Competition: ' + (match.Competition__c != null ? match.Competition__r.Sport__c : 'N/A'));
    System.debug('Home Team: ' + (match.Home_Team__c != null ? match.Home_Team__r.Name + ' (ESPN ID: ' + match.Home_Team__r.ESPN_Team_ID__c + ')' : 'N/A'));
    System.debug('Away Team: ' + (match.Away_Team__c != null ? match.Away_Team__r.Name + ' (ESPN ID: ' + match.Away_Team__r.ESPN_Team_ID__c + ')' : 'N/A'));
    System.debug('');
    
    // Check prerequisites
    if (String.isNotBlank(match.ESPN_Event_ID__c)) {
        System.debug('INFO: Match already has ESPN_Event_ID__c = ' + match.ESPN_Event_ID__c);
        return;
    }
    
    if (match.Match_Date_Time__c == null) {
        System.debug('ERROR: Match_Date_Time__c is required but is null');
        return;
    }
    
    if (match.Competition__c == null) {
        System.debug('ERROR: Competition__c is required but is null');
        return;
    }
    
    if (match.Home_Team__c == null && match.Away_Team__c == null) {
        System.debug('ERROR: At least one team (Home_Team__c or Away_Team__c) is required');
        return;
    }
    
    if (match.Match_Level__c != 'Professional') {
        System.debug('WARNING: Match_Level__c is "' + match.Match_Level__c + '". Auto-resolution only works for Professional matches.');
        System.debug('Attempting resolution anyway...');
    }
    
    System.debug('=== Attempting to Resolve Event ID ===');
    
    // Attempt to resolve Event ID
    String eventId = ESPNEventIdResolver.resolveEventId(match);
    
    if (String.isNotBlank(eventId)) {
        match.ESPN_Event_ID__c = eventId;
        update match;
        
        System.debug('✅ SUCCESS: Resolved and set ESPN_Event_ID__c = ' + eventId);
        
        // Verify
        Match__c verify = [SELECT Id, Name, ESPN_Event_ID__c FROM Match__c WHERE Id = :matchId LIMIT 1];
        System.debug('Verification: ESPN_Event_ID__c = ' + verify.ESPN_Event_ID__c);
    } else {
        System.debug('❌ FAILED: Could not resolve Event ID');
        System.debug('');
        System.debug('Possible reasons:');
        System.debug('  1. No matching event found in ESPN API for the given date and teams');
        System.debug('  2. Teams do not have ESPN_Team_ID__c set');
        System.debug('  3. Competition does not have ESPN_League_ID__c set');
        System.debug('  4. Match date is too far in the future or past');
        System.debug('');
        System.debug('You can manually set ESPN_Event_ID__c if you know the ESPN event ID.');
    }
    
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

