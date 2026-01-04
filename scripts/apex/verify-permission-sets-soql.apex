/**
 * Verify permission set assignments using SOQL
 */

System.debug('=== VERIFYING PERMISSION SET ASSIGNMENTS (SOQL) ===');
System.debug('Current User: ' + UserInfo.getName() + ' (' + UserInfo.getUserEmail() + ')');
System.debug('User ID: ' + UserInfo.getUserId());
System.debug('');

// Query all permission set assignments for current user
List<PermissionSetAssignment> allAssignments = [
    SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    ORDER BY PermissionSet.Name
];

System.debug('=== ALL PERMISSION SET ASSIGNMENTS ===');
System.debug('Total assignments: ' + allAssignments.size());
System.debug('');

for (PermissionSetAssignment psa : allAssignments) {
    System.debug('  - ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    System.debug('    Assignment ID: ' + psa.Id);
    System.debug('    Permission Set ID: ' + psa.PermissionSetId);
}
System.debug('');

// Check specifically for Professional permission sets
List<PermissionSetAssignment> professionalAssignments = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name IN ('Professional_Match_Admin', 'Professional_Match_User')
];

System.debug('=== PROFESSIONAL PERMISSION SETS ===');
if (professionalAssignments.isEmpty()) {
    System.debug('✗ No Professional permission sets assigned');
} else {
    System.debug('✓ Found ' + professionalAssignments.size() + ' Professional permission set(s):');
    for (PermissionSetAssignment psa : professionalAssignments) {
        System.debug('  ✓ ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
}
System.debug('');

System.debug('=== VERIFICATION COMPLETE ===');

