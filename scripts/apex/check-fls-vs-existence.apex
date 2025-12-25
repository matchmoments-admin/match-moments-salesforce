/**
 * Check if Match__c fields exist but lack FLS vs truly don't exist
 * Schema.describe() returns ALL fields regardless of FLS
 * SOQL errors differ: "insufficient privileges" (FLS) vs "No such column" (doesn't exist)
 */

System.debug('=== CHECKING: FLS Issue vs Missing Fields ===');
System.debug('');

// ========================================
// Test 1: Schema.describe() - Shows ALL fields (even without FLS)
// ========================================
System.debug('--- Test 1: Schema.describe() (ignores FLS) ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Schema.DescribeSObjectResult matchDescribe = matchType.getDescribe();
Map<String, Schema.SObjectField> allFields = matchDescribe.fields.getMap();

System.debug('Total fields via Schema.describe(): ' + allFields.size());
System.debug('');

// Check if ESPN_Event_ID__c exists in schema
if (allFields.containsKey('espn_event_id__c')) {
    Schema.DescribeFieldResult fieldDescribe = allFields.get('espn_event_id__c').getDescribe();
    System.debug('✅ ESPN_Event_ID__c EXISTS in schema');
    System.debug('   - Label: ' + fieldDescribe.getLabel());
    System.debug('   - Type: ' + fieldDescribe.getType());
    System.debug('   - Accessible: ' + fieldDescribe.isAccessible());
    System.debug('   - Createable: ' + fieldDescribe.isCreateable());
    System.debug('   - Updateable: ' + fieldDescribe.isUpdateable());
} else {
    System.debug('❌ ESPN_Event_ID__c DOES NOT EXIST in schema');
    System.debug('   This is NOT an FLS issue - field is not created');
}
System.debug('');

// ========================================
// Test 2: Dynamic SOQL - Won't compile if field missing
// ========================================
System.debug('--- Test 2: Attempting Dynamic SOQL ---');

if (allFields.containsKey('espn_event_id__c')) {
    try {
        String soql = 'SELECT Id, ESPN_Event_ID__c FROM Match__c LIMIT 1';
        List<SObject> results = Database.query(soql);
        System.debug('✅ Dynamic query succeeded - field exists and is accessible');
    } catch (Exception e) {
        System.debug('❌ Dynamic query failed: ' + e.getMessage());
        if (e.getMessage().contains('insufficient') || e.getMessage().contains('permission')) {
            System.debug('📋 DIAGNOSIS: Field EXISTS but lacks FLS permissions');
        }
    }
} else {
    System.debug('⚠️ Skipping SOQL test - field does not exist in schema');
    System.debug('   If field existed with FLS issue, it would show in Schema.describe()');
}
System.debug('');

// ========================================
// Test 3: Check ALL expected fields
// ========================================
System.debug('--- Test 3: Check All 15 Expected Fields ---');

List<String> expectedFields = new List<String>{
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
    'Display_Score__c'
};

Integer existCount = 0;
Integer missingCount = 0;
List<String> missingFields = new List<String>();

for (String fieldName : expectedFields) {
    if (allFields.containsKey(fieldName.toLowerCase())) {
        existCount++;
        Schema.DescribeFieldResult fd = allFields.get(fieldName.toLowerCase()).getDescribe();
        System.debug('  ✅ ' + fieldName + ' - EXISTS (Accessible: ' + fd.isAccessible() + ')');
    } else {
        missingCount++;
        missingFields.add(fieldName);
        System.debug('  ❌ ' + fieldName + ' - DOES NOT EXIST');
    }
}

System.debug('');
System.debug('Summary: ' + existCount + ' exist, ' + missingCount + ' missing');
System.debug('');

// ========================================
// Final Diagnosis
// ========================================
System.debug('=== FINAL DIAGNOSIS ===');
System.debug('');

if (missingCount > 0) {
    System.debug('❌ PROBLEM: Fields do NOT exist in org schema');
    System.debug('   This is NOT an FLS/Permission issue');
    System.debug('   Schema.describe() would show fields even without FLS');
    System.debug('');
    System.debug('ROOT CAUSE: Salesforce CLI deployment bug');
    System.debug('   - CLI reports "Success" or "Unchanged"');
    System.debug('   - But fields never get created in org');
    System.debug('   - Metadata tracking out of sync with actual org');
    System.debug('');
    System.debug('SOLUTION OPTIONS:');
    System.debug('   1. Manual field creation in Setup UI (15-20 min)');
    System.debug('   2. Use Workbench to deploy metadata');
    System.debug('   3. Delete Match__c and recreate (risky)');
    System.debug('   4. Continue using Fixture__c (works today)');
} else {
    System.debug('✅ All fields exist in schema');
    System.debug('   If queries still fail, check FLS/permissions');
}

