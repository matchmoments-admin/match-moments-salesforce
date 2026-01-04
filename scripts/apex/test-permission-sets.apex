/**
 * Test permission sets with anonymous apex
 * Verifies that the current user has the Professional_Match_Admin permission set
 * and can create/update Professional matches
 */

System.debug('=== TESTING PERMISSION SETS ===');
System.debug('Current User: ' + UserInfo.getName() + ' (' + UserInfo.getUserEmail() + ')');
System.debug('');

// 1. Check assigned permission sets
List<PermissionSetAssignment> assignments = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name IN ('Professional_Match_Admin', 'Professional_Match_User')
];

System.debug('=== ASSIGNED PERMISSION SETS ===');
if (assignments.isEmpty()) {
    System.debug('WARNING: No Professional permission sets found!');
} else {
    for (PermissionSetAssignment psa : assignments) {
        System.debug('  ✓ ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
}
System.debug('');

// 2. Test creating a Professional match (should succeed with permission set)
System.debug('=== TEST: Creating Professional Match ===');
try {
    // Get a competition and teams for testing
    Competition__c comp = [
        SELECT Id, Name, ESPN_League_ID__c
        FROM Competition__c
        WHERE ESPN_League_ID__c = 'eng.1'
        LIMIT 1
    ];
    
    List<Account> teams = [
        SELECT Id, Name
        FROM Account
        WHERE ESPN_Team_ID__c != null
        LIMIT 2
    ];
    
    if (teams.size() < 2) {
        System.debug('WARNING: Need at least 2 teams to create a test match');
    } else {
        Match__c testMatch = new Match__c(
            Competition__c = comp.Id,
            Home_Team__c = teams[0].Id,
            Away_Team__c = teams[1].Id,
            Match_Date_Time__c = DateTime.now().addDays(7),
            Status__c = 'Scheduled',
            Match_Level__c = 'Professional'
        );
        
        insert testMatch;
        System.debug('✓ SUCCESS: Created Professional match: ' + testMatch.Id);
        System.debug('  Match Level: ' + testMatch.Match_Level__c);
        
        // Clean up - delete test match
        delete testMatch;
        System.debug('  (Test match deleted)');
    }
} catch (Exception e) {
    System.debug('✗ ERROR creating Professional match: ' + e.getMessage());
    System.debug('  This may indicate a permission issue');
}
System.debug('');

// 3. Test querying Professional matches
System.debug('=== TEST: Querying Professional Matches ===');
try {
    List<Match__c> professionalMatches = [
        SELECT Id, Name, Match_Level__c, Status__c, Match_Date_Time__c
        FROM Match__c
        WHERE Match_Level__c = 'Professional'
        LIMIT 5
    ];
    
    System.debug('✓ SUCCESS: Found ' + professionalMatches.size() + ' Professional matches');
    for (Match__c m : professionalMatches) {
        System.debug('  - ' + m.Name + ' (' + m.Match_Level__c + ')');
    }
} catch (Exception e) {
    System.debug('✗ ERROR querying Professional matches: ' + e.getMessage());
}
System.debug('');

System.debug('=== TEST COMPLETE ===');

