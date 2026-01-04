Id userId = UserInfo.getUserId();
Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'ESPN_Internal_Users' LIMIT 1].Id;

// Check if already assigned
List<PermissionSetAssignment> existing = [
    SELECT Id 
    FROM PermissionSetAssignment 
    WHERE PermissionSetId = :permSetId 
    AND AssigneeId = :userId
    LIMIT 1
];

if (existing.isEmpty()) {
    PermissionSetAssignment psa = new PermissionSetAssignment(
        PermissionSetId = permSetId, 
        AssigneeId = userId
    );
    insert psa;
    System.debug('Permission set assigned successfully');
} else {
    System.debug('Permission set already assigned');
}

