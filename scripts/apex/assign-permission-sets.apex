/**
 * Assign permission sets to users
 * Usage: Update the userEmails and permissionSetNames lists below
 * Then run: sf apex run --file scripts/apex/assign-permission-sets.apex --target-org <org-alias>
 */

// ========================================
// CONFIGURATION - Update these values
// ========================================

// List of user emails to assign permission sets to
List<String> userEmails = new List<String>{
    'brendan.milton1211@gmail.com'  // Current logged-in user
    // Add more user emails here
};

// List of permission set names to assign
List<String> permissionSetNames = new List<String>{
    'Professional_Match_Admin',
    'Professional_Match_User'  // Assign both admin and user for testing
    // Add more permission set names here:
    // 'Amateur_Match_Admin',
    // 'Amateur_Match_User',
    // 'Article_Admin',
    // 'Article_User'
};

// ========================================
// SCRIPT EXECUTION
// ========================================

System.debug('=== ASSIGNING PERMISSION SETS ===');
System.debug('Users: ' + userEmails);
System.debug('Permission Sets: ' + permissionSetNames);
System.debug('');

// Query users
List<User> users = [
    SELECT Id, Name, Email, Username
    FROM User
    WHERE Email IN :userEmails
    AND IsActive = true
];

if (users.isEmpty()) {
    System.debug('ERROR: No active users found with the specified emails.');
    System.debug('Please check the email addresses and try again.');
} else {
    System.debug('Found ' + users.size() + ' active user(s):');
    for (User u : users) {
        System.debug('  - ' + u.Name + ' (' + u.Email + ')');
    }
    System.debug('');
}

// Query permission sets
List<PermissionSet> permissionSets = [
    SELECT Id, Name, Label
    FROM PermissionSet
    WHERE Name IN :permissionSetNames
    AND IsOwnedByProfile = false
];

if (permissionSets.isEmpty()) {
    System.debug('ERROR: No permission sets found with the specified names.');
    System.debug('Please check the permission set names and ensure they are deployed.');
} else {
    System.debug('Found ' + permissionSets.size() + ' permission set(s):');
    for (PermissionSet ps : permissionSets) {
        System.debug('  - ' + ps.Label + ' (' + ps.Name + ')');
    }
    System.debug('');
}

// Check existing assignments
System.debug('Checking existing assignments...');
List<PermissionSetAssignment> existingAssignments = [
    SELECT AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId IN :new Map<Id, User>(users).keySet()
    AND PermissionSetId IN :new Map<Id, PermissionSet>(permissionSets).keySet()
];

Set<String> existingKeys = new Set<String>();
for (PermissionSetAssignment psa : existingAssignments) {
    String key = psa.AssigneeId + '_' + psa.PermissionSetId;
    existingKeys.add(key);
    System.debug('  Already assigned: User ' + psa.AssigneeId + ' -> ' + psa.PermissionSet.Label);
}

// Create new assignments
List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();

for (User u : users) {
    for (PermissionSet ps : permissionSets) {
        String key = u.Id + '_' + ps.Id;
        if (!existingKeys.contains(key)) {
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = u.Id;
            psa.PermissionSetId = ps.Id;
            newAssignments.add(psa);
        }
    }
}

if (newAssignments.isEmpty()) {
    System.debug('');
    System.debug('All permission sets are already assigned. No new assignments needed.');
} else {
    System.debug('');
    System.debug('Creating ' + newAssignments.size() + ' new assignment(s)...');
    
    try {
        insert newAssignments;
        System.debug('');
        System.debug('=== SUCCESS ===');
        System.debug('Successfully assigned permission sets:');
        for (PermissionSetAssignment psa : newAssignments) {
            System.debug('  - User ' + psa.AssigneeId + ' -> Permission Set ' + psa.PermissionSetId);
        }
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'ERROR assigning permission sets: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
}

System.debug('');
System.debug('=== COMPLETE ===');

