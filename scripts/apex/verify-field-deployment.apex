/**
 * Verify Field Deployment
 * Test that all 20 Match__c fields + Account.League__c are accessible
 */

System.debug('=== VERIFYING FIELD DEPLOYMENT ===');
System.debug('');

// ========================================
// 1. Test Match__c Fields with Describe
// ========================================
System.debug('--- Verifying Match__c Fields ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> fieldMap = matchType.getDescribe().fields.getMap();

List<String> allFields = new List<String>{
    'ESPN_Event_ID__c',
    'Home_Score_Final__c',
    'Away_Score_Final__c',
    'Venue__c',
    'Attendance__c',
    'Broadcast_URL__c',
    'Current_Period__c',
    'Match_Stats_JSON__c',
    'Referee__c',
    'Home_Sub_Score__c',
    'Away_Sub_Score__c',
    'Neutral_Venue__c',
    'Season__c',
    'Winner__c',
    'Display_Score__c',
    'Home_Team__c',
    'Away_Team__c',
    'Competition__c',
    'Match_Date_Time__c',
    'Status__c'
};

Integer successCount = 0;
Integer failCount = 0;

for (String fieldName : allFields) {
    if (fieldMap.containsKey(fieldName.toLowerCase())) {
        System.debug('  ✅ ' + fieldName);
        successCount++;
    } else {
        System.debug('  ❌ ' + fieldName + ' - STILL MISSING');
        failCount++;
    }
}

System.debug('');
System.debug('Match__c Fields: ' + successCount + '/20 deployed successfully');

// ========================================
// 2. Test Account.League__c Field
// ========================================
System.debug('');
System.debug('--- Verifying Account.League__c ---');

Schema.SObjectType accountType = Schema.getGlobalDescribe().get('Account');
Map<String, Schema.SObjectField> accountFields = accountType.getDescribe().fields.getMap();

if (accountFields.containsKey('league__c')) {
    System.debug('  ✅ League__c field deployed successfully');
} else {
    System.debug('  ❌ League__c field still missing');
}

// ========================================
// 3. Test SOQL Query with All Fields
// ========================================
System.debug('');
System.debug('--- Testing SOQL Query ---');

try {
    // Try to query all Match__c fields (will fail if any are missing)
    String soql = 'SELECT Id, Name, ESPN_Event_ID__c, ' +
                  'Home_Team__c, Away_Team__c, Competition__c, ' +
                  'Match_Date_Time__c, Status__c, ' +
                  'Home_Score_Final__c, Away_Score_Final__c, Display_Score__c, ' +
                  'Venue__c, Attendance__c, Referee__c, ' +
                  'Current_Period__c, Broadcast_URL__c, Match_Stats_JSON__c, ' +
                  'Home_Sub_Score__c, Away_Sub_Score__c, Neutral_Venue__c, ' +
                  'Season__c, Winner__c ' +
                  'FROM Match__c LIMIT 1';
    
    List<Match__c> matches = Database.query(soql);
    System.debug('✅ SUCCESS: All 20 Match__c fields are queryable!');
    System.debug('   Query returned ' + matches.size() + ' records (expected 0 for new deployment)');
} catch (Exception e) {
    System.debug('❌ FAILED: SOQL query error - ' + e.getMessage());
}

// ========================================
// 4. Test Account.League__c Query
// ========================================
System.debug('');
System.debug('--- Testing Account.League__c Query ---');

try {
    List<Account> teams = [SELECT Id, Name, ESPN_Team_ID__c, League__c 
                           FROM Account 
                           WHERE ESPN_Team_ID__c != null 
                           LIMIT 1];
    System.debug('✅ SUCCESS: Account.League__c is queryable!');
    System.debug('   Found ' + teams.size() + ' team(s) with ESPN_Team_ID__c');
} catch (Exception e) {
    System.debug('❌ FAILED: Account.League__c query error - ' + e.getMessage());
}

// ========================================
// Summary
// ========================================
System.debug('');
System.debug('=== VERIFICATION COMPLETE ===');
if (successCount == 20 && failCount == 0) {
    System.debug('✅ ALL FIELDS DEPLOYED SUCCESSFULLY!');
    System.debug('   Ready to proceed with ESPN sync testing');
} else {
    System.debug('⚠️ DEPLOYMENT INCOMPLETE: ' + failCount + ' fields still missing');
}

