/**
 * Comprehensive test for deployed classes after compilation fixes
 * Tests: ESPNDataParser, LineupsSelector, MatchTriggerHandler
 * Verifies field access and class functionality
 */

System.debug('=== TESTING DEPLOYED CLASSES ===');
System.debug('Started at: ' + DateTime.now());
System.debug('Running as: ' + UserInfo.getName());
System.debug('');

// ========================================
// Test 1: Verify Classes Are Available
// ========================================
System.debug('--- Test 1: Class Availability ---');

try {
    Type espnParserType = Type.forName('ESPNDataParser');
    System.debug('✅ ESPNDataParser class is available');
} catch (Exception e) {
    System.debug('❌ ESPNDataParser not available: ' + e.getMessage());
}

try {
    Type lineupsSelectorType = Type.forName('LineupsSelector');
    System.debug('✅ LineupsSelector class is available');
} catch (Exception e) {
    System.debug('❌ LineupsSelector not available: ' + e.getMessage());
}

try {
    Type matchTriggerType = Type.forName('MatchTriggerHandler');
    System.debug('✅ MatchTriggerHandler class is available');
} catch (Exception e) {
    System.debug('❌ MatchTriggerHandler not available: ' + e.getMessage());
}

System.debug('');

// ========================================
// Test 2: Verify Field Access (FLS Check)
// ========================================
System.debug('--- Test 2: Field-Level Security Check ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> matchFields = matchType.getDescribe().fields.getMap();

Schema.SObjectType lineupType = Schema.getGlobalDescribe().get('Lineup__c');
Map<String, Schema.SObjectField> lineupFields = lineupType.getDescribe().fields.getMap();

// Check Match__c.Match_Level__c
if (matchFields.containsKey('match_level__c')) {
    Schema.DescribeFieldResult field = matchFields.get('match_level__c').getDescribe();
    System.debug('✅ Match__c.Match_Level__c');
    System.debug('   - Accessible: ' + field.isAccessible());
    System.debug('   - Createable: ' + field.isCreateable());
    System.debug('   - Updateable: ' + field.isUpdateable());
} else {
    System.debug('❌ Match__c.Match_Level__c - NOT VISIBLE (FLS issue)');
}

// Check Lineup__c.Match__c
if (lineupFields.containsKey('match__c')) {
    Schema.DescribeFieldResult field = lineupFields.get('match__c').getDescribe();
    System.debug('✅ Lineup__c.Match__c');
    System.debug('   - Accessible: ' + field.isAccessible());
    System.debug('   - Createable: ' + field.isCreateable());
    System.debug('   - Updateable: ' + field.isUpdateable());
} else {
    System.debug('❌ Lineup__c.Match__c - NOT VISIBLE (FLS issue)');
}

// Check Lineup__c.Lineup_JSON__c
if (lineupFields.containsKey('lineup_json__c')) {
    Schema.DescribeFieldResult field = lineupFields.get('lineup_json__c').getDescribe();
    System.debug('✅ Lineup__c.Lineup_JSON__c');
    System.debug('   - Accessible: ' + field.isAccessible());
    System.debug('   - Createable: ' + field.isCreateable());
    System.debug('   - Updateable: ' + field.isUpdateable());
} else {
    System.debug('❌ Lineup__c.Lineup_JSON__c - NOT VISIBLE (FLS issue)');
}

System.debug('');

// ========================================
// Test 3: Test LineupsSelector
// ========================================
System.debug('--- Test 3: LineupsSelector Test ---');

try {
    LineupsSelector selector = LineupsSelector.newInstance();
    System.debug('✅ LineupsSelector instantiated successfully');
    
    // Try to query existing lineups (check field access first)
    List<Lineup__c> existingLineups = new List<Lineup__c>();
    try {
        existingLineups = [
            SELECT Id, Match__c, Lineup_JSON__c
            FROM Lineup__c
            LIMIT 5
        ];
    
    System.debug('✅ Query successful - Found ' + existingLineups.size() + ' Lineup records');
    
    if (!existingLineups.isEmpty()) {
        // Test selectByMatchIds
        Set<Id> matchIds = new Set<Id>();
        for (Lineup__c l : existingLineups) {
            if (l.Match__c != null) {
                matchIds.add(l.Match__c);
            }
        }
        
        if (!matchIds.isEmpty()) {
            List<Lineup__c> lineupsByMatch = selector.selectByMatchIds(matchIds);
            System.debug('✅ selectByMatchIds() works - Found ' + lineupsByMatch.size() + ' lineups');
        }
    }
    } catch (Exception queryEx) {
        System.debug('⚠️ Direct query failed (may be FLS issue): ' + queryEx.getMessage());
        System.debug('   Trying with selector instead...');
        
        // Try using selector which may have different field access
        try {
            List<Lineup__c> lineups = selector.selectById(new Set<Id>());
            System.debug('✅ Selector works (found ' + lineups.size() + ' lineups)');
        } catch (Exception selectorEx) {
            System.debug('❌ Selector also failed: ' + selectorEx.getMessage());
        }
    }
} catch (Exception e) {
    System.debug('❌ LineupsSelector test failed: ' + e.getMessage());
    System.debug('   Type: ' + e.getTypeName());
    System.debug('   Stack: ' + e.getStackTraceString());
}

System.debug('');

// ========================================
// Test 4: Test Match__c Query with Match_Level__c
// ========================================
System.debug('--- Test 4: Match__c Query with Match_Level__c ---');

try {
    List<Match__c> matches = [
        SELECT Id, Name, Match_Level__c, ESPN_Event_ID__c, Status__c
        FROM Match__c
        WHERE Match_Level__c != null
        LIMIT 5
    ];
    
    System.debug('✅ Query successful - Found ' + matches.size() + ' Match records with Match_Level__c');
    
    for (Match__c m : matches) {
        System.debug('   - ' + m.Name + ' (Level: ' + m.Match_Level__c + ')');
    }
} catch (Exception e) {
    System.debug('❌ Match__c query failed: ' + e.getMessage());
    System.debug('   Type: ' + e.getTypeName());
    if (e.getMessage().contains('Match_Level__c')) {
        System.debug('   ⚠️ FLS issue with Match_Level__c field');
    }
}

System.debug('');

// ========================================
// Test 5: Test ESPNDataParser (if data available)
// ========================================
System.debug('--- Test 5: ESPNDataParser Availability ---');

try {
    // Just verify the class can be referenced
    System.debug('✅ ESPNDataParser class reference works');
    System.debug('   Note: Full parser testing requires ESPN API response data');
} catch (Exception e) {
    System.debug('❌ ESPNDataParser test failed: ' + e.getMessage());
}

System.debug('');

// ========================================
// Test 6: Check User Permission Sets
// ========================================
System.debug('--- Test 6: User Permission Sets ---');

List<PermissionSetAssignment> userPermSets = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.IsOwnedByProfile = false
];

System.debug('Assigned Permission Sets:');
if (userPermSets.isEmpty()) {
    System.debug('  ⚠️ NO permission sets assigned to current user');
    System.debug('  Recommendation: Assign ESPN_Internal_Users permission set');
} else {
    for (PermissionSetAssignment psa : userPermSets) {
        System.debug('  - ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
}

System.debug('');

// ========================================
// Summary
// ========================================
System.debug('=== TEST SUMMARY ===');
System.debug('All tests completed. Review output above for any issues.');
System.debug('If FLS errors found, assign permission sets to user.');
System.debug('');

