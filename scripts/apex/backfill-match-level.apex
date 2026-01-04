/**
 * Backfill Match_Level__c on existing Match__c records
 * Sets Match_Level__c = 'Professional' for all existing matches
 * Run this script after deploying Match_Level__c field
 */

System.debug('=== BACKFILLING MATCH_LEVEL__C ===');
System.debug('Starting at: ' + System.now());

// Query all matches without Match_Level__c or with null value
List<Match__c> matchesToUpdate = [
    SELECT Id, Name, Match_Level__c, ESPN_Event_ID__c
    FROM Match__c
    WHERE Match_Level__c = null
    LIMIT 10000
];

System.debug('Found ' + matchesToUpdate.size() + ' matches to update');

if (matchesToUpdate.isEmpty()) {
    System.debug('No matches need updating. All matches already have Match_Level__c set.');
} else {
    Integer updatedCount = 0;
    Integer errorCount = 0;
    
    // Update in batches of 200
    for (Integer i = 0; i < matchesToUpdate.size(); i += 200) {
        List<Match__c> batch = new List<Match__c>();
        Integer endIndex = Math.min(i + 200, matchesToUpdate.size());
        
        for (Integer j = i; j < endIndex; j++) {
            Match__c match = matchesToUpdate[j];
            match.Match_Level__c = 'Professional'; // Default to Professional for ESPN-synced matches
            batch.add(match);
        }
        
        try {
            update batch;
            updatedCount += batch.size();
            System.debug('Updated batch: ' + batch.size() + ' matches (Total: ' + updatedCount + ')');
        } catch (Exception e) {
            errorCount += batch.size();
            System.debug(LoggingLevel.ERROR, 'Error updating batch: ' + e.getMessage());
        }
    }
    
    System.debug('');
    System.debug('=== BACKFILL COMPLETE ===');
    System.debug('Successfully updated: ' + updatedCount + ' matches');
    System.debug('Errors: ' + errorCount + ' matches');
    System.debug('Completed at: ' + System.now());
}

