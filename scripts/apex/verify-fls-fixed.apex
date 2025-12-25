/**
 * Verify FLS Update for Match__c Fields
 * Run after updating permission sets to confirm FLS is working
 */

System.debug('=== VERIFYING FLS UPDATE ===');
System.debug('Running as: ' + UserInfo.getName());
System.debug('');

// ========================================
// Test 1: Check field count and accessibility
// ========================================
System.debug('--- Test 1: Field Visibility Check ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> fields = matchType.getDescribe().fields.getMap();

System.debug('Fields visible to current user: ' + fields.size());
System.debug('Expected: 29+ fields (20 custom + 9 system)');

if (fields.size() >= 29) {
    System.debug('✅ Field count looks good!');
} else {
    System.debug('⚠️ Still missing fields. Current: ' + fields.size());
}
System.debug('');

// ========================================
// Test 2: Check all ESPN critical fields
// ========================================
System.debug('--- Test 2: ESPN Field Accessibility ---');

List<String> espnFields = new List<String>{
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

Integer accessibleCount = 0;
Integer notAccessibleCount = 0;

for (String fieldName : espnFields) {
    if (fields.containsKey(fieldName.toLowerCase())) {
        Schema.DescribeFieldResult field = fields.get(fieldName.toLowerCase()).getDescribe();
        if (field.isAccessible()) {
            System.debug('  ✅ ' + fieldName + ' (Readable: ' + field.isAccessible() + 
                        ', Writable: ' + field.isUpdateable() + ')');
            accessibleCount++;
        } else {
            System.debug('  ⚠️ ' + fieldName + ' - Visible but not accessible');
            notAccessibleCount++;
        }
    } else {
        System.debug('  ❌ ' + fieldName + ' - Not visible');
        notAccessibleCount++;
    }
}

System.debug('');
System.debug('Summary: ' + accessibleCount + ' accessible, ' + notAccessibleCount + ' not accessible');
System.debug('');

// ========================================
// Test 3: SOQL Query Test
// ========================================
System.debug('--- Test 3: SOQL Query Test ---');

try {
    String soql = 'SELECT Id, Name, ESPN_Event_ID__c, ' +
                  'Home_Team__c, Away_Team__c, Competition__c, ' +
                  'Match_Date_Time__c, Status__c, ' +
                  'Home_Score_Final__c, Away_Score_Final__c, ' +
                  'Venue__c, Attendance__c, Referee__c ' +
                  'FROM Match__c LIMIT 1';
    
    List<Match__c> matches = Database.query(soql);
    System.debug('✅ SOQL query successful!');
    System.debug('   Records found: ' + matches.size());
    System.debug('   All critical fields queryable');
} catch (Exception e) {
    System.debug('❌ SOQL query failed: ' + e.getMessage());
    System.debug('   This means FLS still needs to be updated');
}
System.debug('');

// ========================================
// Test 4: Create Permission Test
// ========================================
System.debug('--- Test 4: Create Permission Test ---');

try {
    // Test if we can create a Match__c record with ESPN fields
    Match__c testMatch = new Match__c(
        // Don't actually insert, just check if fields are writable
    );
    
    Schema.DescribeSObjectResult matchDescribe = Match__c.SObjectType.getDescribe();
    if (matchDescribe.isCreateable() && matchDescribe.isUpdateable()) {
        System.debug('✅ Create/Update permissions granted');
    } else {
        System.debug('⚠️ Limited permissions - Read-only access?');
    }
} catch (Exception e) {
    System.debug('⚠️ Permission test inconclusive: ' + e.getMessage());
}
System.debug('');

// ========================================
// Final Assessment
// ========================================
System.debug('=== FINAL ASSESSMENT ===');
System.debug('');

if (accessibleCount == 15) {
    System.debug('🎉 SUCCESS! All 15 ESPN fields are accessible');
    System.debug('✅ FLS permissions correctly configured');
    System.debug('✅ Ready to proceed with ESPN sync testing');
    System.debug('');
    System.debug('NEXT STEPS:');
    System.debug('1. Update ESPN sync services to use Match__c');
    System.debug('2. Run Premier League 2025/26 sync test');
    System.debug('3. Verify data populates in Match__c records');
} else if (accessibleCount > 0) {
    System.debug('⚠️ PARTIAL SUCCESS');
    System.debug('   ' + accessibleCount + ' of 15 fields accessible');
    System.debug('   ' + notAccessibleCount + ' fields still need FLS');
    System.debug('');
    System.debug('ACTION REQUIRED:');
    System.debug('- Review permission set field permissions');
    System.debug('- Ensure all Match__c fields have Read/Edit access');
    System.debug('- Re-run this verification script');
} else {
    System.debug('❌ FLS UPDATE NOT COMPLETE');
    System.debug('   No ESPN fields accessible yet');
    System.debug('');
    System.debug('ACTION REQUIRED:');
    System.debug('1. Go to Setup → Permission Sets');
    System.debug('2. Update ESPN Internal Users permission set');
    System.debug('3. Add Match object permissions (Read, Create, Edit)');
    System.debug('4. Add field-level security for all Match__c fields');
    System.debug('5. Save and re-run this script');
}
System.debug('');
System.debug('=== VERIFICATION COMPLETE ===');

