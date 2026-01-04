/**
 * Check if permission sets exist in org and list their details
 * Run this to verify permission sets are deployed before assigning them
 */

System.debug('=== CHECKING PERMISSION SETS ===');
System.debug('');

// List of expected permission sets
List<String> expectedPermissionSets = new List<String>{
    'Professional_Match_Admin',
    'Professional_Match_User',
    'Amateur_Match_Admin',
    'Amateur_Match_User',
    'Article_Admin',
    'Article_User',
    'ESPN_Internal_Users',
    'API_Data_Access'
};

// Query all permission sets
List<PermissionSet> allPermissionSets = [
    SELECT Id, Name, Label, Description, IsOwnedByProfile
    FROM PermissionSet
    WHERE IsOwnedByProfile = false
    ORDER BY Name
];

System.debug('Total custom permission sets in org: ' + allPermissionSets.size());
System.debug('');

// Check expected permission sets
System.debug('=== EXPECTED PERMISSION SETS ===');
Map<String, PermissionSet> permissionSetMap = new Map<String, PermissionSet>();
for (PermissionSet ps : allPermissionSets) {
    permissionSetMap.put(ps.Name, ps);
}

Integer foundCount = 0;
Integer missingCount = 0;

for (String expectedName : expectedPermissionSets) {
    if (permissionSetMap.containsKey(expectedName)) {
        PermissionSet ps = permissionSetMap.get(expectedName);
        System.debug('✅ ' + ps.Label + ' (' + ps.Name + ')');
        if (String.isNotBlank(ps.Description)) {
            System.debug('   Description: ' + ps.Description);
        }
        foundCount++;
    } else {
        System.debug('❌ ' + expectedName + ' - NOT FOUND');
        missingCount++;
    }
}

System.debug('');
System.debug('=== SUMMARY ===');
System.debug('Found: ' + foundCount + ' / ' + expectedPermissionSets.size());
System.debug('Missing: ' + missingCount + ' / ' + expectedPermissionSets.size());

if (missingCount > 0) {
    System.debug('');
    System.debug('⚠️  Some permission sets are missing. Please deploy them before assigning to users.');
}

System.debug('');
System.debug('=== ALL CUSTOM PERMISSION SETS IN ORG ===');
for (PermissionSet ps : allPermissionSets) {
    System.debug('  - ' + ps.Label + ' (' + ps.Name + ')');
}

