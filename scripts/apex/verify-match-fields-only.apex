/**
 * Verify Match__c Fields Only
 * Test that all 20 Match__c fields are accessible
 */

System.debug('=== VERIFYING MATCH__C FIELDS ===');
System.debug('');

// Test SOQL Query with All 20 Fields
System.debug('--- Testing SOQL Query with All 20 Fields ---');

try {
    // Query all Match__c fields (will fail if any are missing)
    List<Match__c> matches = [
        SELECT Id, Name, ESPN_Event_ID__c,
               Home_Team__c, Away_Team__c, Competition__c,
               Match_Date_Time__c, Status__c,
               Home_Score_Final__c, Away_Score_Final__c, Display_Score__c,
               Venue__c, Attendance__c, Referee__c,
               Current_Period__c, Broadcast_URL__c, Match_Stats_JSON__c,
               Home_Sub_Score__c, Away_Sub_Score__c, Neutral_Venue__c,
               Season__c, Winner__c
        FROM Match__c
        LIMIT 1
    ];
    
    System.debug('✅ SUCCESS: All 20 Match__c fields are queryable!');
    System.debug('   Query returned ' + matches.size() + ' records');
    System.debug('');
    System.debug('=== DEPLOYMENT VERIFIED ===');
    System.debug('✅ Ready to proceed with ESPN Premier League sync test');
    
} catch (Exception e) {
    System.debug('❌ FAILED: ' + e.getMessage());
    System.debug('   One or more fields are still missing from the org');
}

