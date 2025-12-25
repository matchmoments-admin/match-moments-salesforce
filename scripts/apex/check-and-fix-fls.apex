/**
 * Check Match__c Field-Level Security and identify which permission sets need updating
 * USER CORRECTION: Fields DO exist in org (visible in Setup)
 * Issue: FLS permissions not granted to current user
 */

System.debug('=== CHECKING MATCH__C FLS PERMISSIONS ===');
System.debug('Running as: ' + UserInfo.getName());
System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);
System.debug('');

// ========================================
// Test 1: Check what describe() shows for current user
// ========================================
System.debug('--- Test 1: Current User Field Access ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> allFields = matchType.getDescribe().fields.getMap();

System.debug('Fields visible to current user: ' + allFields.size());

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

System.debug('');
System.debug('Checking FLS for 15 ESPN sync fields:');

for (String fieldName : espnFields) {
    if (allFields.containsKey(fieldName.toLowerCase())) {
        Schema.DescribeFieldResult field = allFields.get(fieldName.toLowerCase()).getDescribe();
        System.debug('  ✅ ' + fieldName);
        System.debug('     - Accessible: ' + field.isAccessible());
        System.debug('     - Createable: ' + field.isCreateable());
        System.debug('     - Updateable: ' + field.isUpdateable());
    } else {
        System.debug('  ❌ ' + fieldName + ' - NOT VISIBLE (FLS issue)');
    }
}

// ========================================
// Test 2: Check Permission Sets
// ========================================
System.debug('');
System.debug('--- Test 2: User\'s Permission Sets ---');

List<PermissionSetAssignment> userPermSets = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.IsOwnedByProfile = false
];

System.debug('Assigned Permission Sets:');
if (userPermSets.isEmpty()) {
    System.debug('  ⚠️ NO permission sets assigned');
} else {
    for (PermissionSetAssignment psa : userPermSets) {
        System.debug('  - ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
}

// ========================================
// Test 3: Check if ESPN permission sets exist
// ========================================
System.debug('');
System.debug('--- Test 3: Available ESPN Permission Sets ---');

List<PermissionSet> espnPermSets = [
    SELECT Name, Label, Description
    FROM PermissionSet
    WHERE Name LIKE '%ESPN%'
    ORDER BY Name
];

System.debug('ESPN Permission Sets in org:');
if (espnPermSets.isEmpty()) {
    System.debug('  ⚠️ NO ESPN permission sets found');
} else {
    for (PermissionSet ps : espnPermSets) {
        System.debug('  - ' + ps.Label + ' (' + ps.Name + ')');
    }
}

// ========================================
// Final Recommendation
// ========================================
System.debug('');
System.debug('=== SOLUTION ===');
System.debug('');
System.debug('Fields exist in org ✅ (confirmed in Setup)');
System.debug('Issue: FLS permissions not granted to current user');
System.debug('');
System.debug('To fix:');
System.debug('1. Go to Setup → Permission Sets');
System.debug('2. Find or create permission set (e.g., ESPN_Internal_Users)');
System.debug('3. Add Match__c object permissions');
System.debug('4. Add field-level security for all Match__c fields');
System.debug('5. Assign permission set to your user');
System.debug('');
System.debug('OR use System Administrator profile which has access to all fields');

