/**
 * @description Anonymous Apex script to manually resolve ESPN Event ID for Match records
 * This script can be used to trigger Event ID resolution for existing matches that:
 * - Have blank ESPN_Event_ID__c
 * - Have Match_Date_Time__c set
 * - Have Competition__c set
 * - Have at least one team (Home_Team__c or Away_Team__c)
 * - Are Professional level matches
 * 
 * Usage: 
 * 1. For a specific match: Set matchId variable below
 * 2. For all qualifying matches: Set matchId to null
 * 3. Execute in Developer Console or VS Code
 * 
 * @author Brendan Milton
 * @date 2025-12-31
 */

// Set to specific match ID, or null to process all qualifying matches
Id matchId = 'a0PgL000000fTZ7UAM'; // Change this or set to null

try {
    // Build query
    String query = 'SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, Match_Level__c, ' +
                   'Competition__c, Competition__r.Sport__c, Competition__r.ESPN_League_ID__c, ' +
                   'Home_Team__c, Away_Team__c, ' +
                   'Home_Team__r.Name, Home_Team__r.ESPN_Team_ID__c, ' +
                   'Away_Team__r.Name, Away_Team__r.ESPN_Team_ID__c ' +
                   'FROM Match__c ' +
                   'WHERE ESPN_Event_ID__c = null ' +
                   'AND Match_Date_Time__c != null ' +
                   'AND Competition__c != null ' +
                   'AND (Home_Team__c != null OR Away_Team__c != null) ' +
                   'AND Match_Level__c = \'Professional\'';
    
    if (matchId != null) {
        query += ' AND Id = :matchId';
    }
    
    query += ' LIMIT 100'; // Safety limit
    
    List<Match__c> matches = Database.query(query);
    
    if (matches.isEmpty()) {
        System.debug('No matches found that need Event ID resolution.');
        if (matchId != null) {
            System.debug('Match ID: ' + matchId);
            System.debug('Check that the match has:');
            System.debug('  - Blank ESPN_Event_ID__c');
            System.debug('  - Match_Date_Time__c set');
            System.debug('  - Competition__c set');
            System.debug('  - At least one team (Home_Team__c or Away_Team__c)');
            System.debug('  - Match_Level__c = "Professional"');
        }
        return;
    }
    
    System.debug('Found ' + matches.size() + ' match(es) that need Event ID resolution');
    System.debug('');
    
    List<Match__c> matchesToUpdate = new List<Match__c>();
    Integer successCount = 0;
    Integer failureCount = 0;
    
    for (Match__c match : matches) {
        System.debug('Processing match: ' + match.Name + ' (ID: ' + match.Id + ')');
        System.debug('  Date: ' + match.Match_Date_Time__c);
        System.debug('  Competition: ' + (match.Competition__c != null ? match.Competition__r.Sport__c : 'N/A'));
        System.debug('  Home Team: ' + (match.Home_Team__c != null ? match.Home_Team__r.Name : 'N/A'));
        System.debug('  Away Team: ' + (match.Away_Team__c != null ? match.Away_Team__r.Name : 'N/A'));
        
        try {
            // Attempt to resolve Event ID
            String eventId = ESPNEventIdResolver.resolveEventId(match);
            
            if (String.isNotBlank(eventId)) {
                match.ESPN_Event_ID__c = eventId;
                matchesToUpdate.add(match);
                successCount++;
                System.debug('  ✅ Resolved Event ID: ' + eventId);
            } else {
                failureCount++;
                System.debug('  ❌ Could not resolve Event ID');
            }
        } catch (Exception e) {
            failureCount++;
            System.debug('  ❌ Error resolving Event ID: ' + e.getMessage());
        }
        System.debug('');
    }
    
    // Update matches with resolved Event IDs
    if (!matchesToUpdate.isEmpty()) {
        try {
            update matchesToUpdate;
            System.debug('SUCCESS: Updated ' + matchesToUpdate.size() + ' match(es) with ESPN Event IDs');
            
            // Verify updates
            for (Match__c updated : matchesToUpdate) {
                Match__c verify = [SELECT Id, Name, ESPN_Event_ID__c FROM Match__c WHERE Id = :updated.Id LIMIT 1];
                System.debug('  Verified: ' + verify.Name + ' -> ESPN_Event_ID__c = ' + verify.ESPN_Event_ID__c);
            }
        } catch (Exception e) {
            System.debug('ERROR: Failed to update matches: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    System.debug('');
    System.debug('Summary:');
    System.debug('  Successfully resolved: ' + successCount);
    System.debug('  Failed to resolve: ' + failureCount);
    System.debug('  Total processed: ' + matches.size());
    
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

