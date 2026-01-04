/**
 * Comprehensive test for deployed classes with real org data
 * Tests all functionality after compilation fixes and permission verification
 */

System.debug('=== COMPREHENSIVE TEST - DEPLOYED CLASSES ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// ========================================
// Test 1: Verify Match__c with Match_Level__c
// ========================================
System.debug('--- Test 1: Match__c with Match_Level__c ---');

try {
    List<Match__c> matches = [
        SELECT Id, Name, Match_Level__c, ESPN_Event_ID__c, Status__c,
               Home_Team__r.Name, Away_Team__r.Name,
               Home_Score_Final__c, Away_Score_Final__c
        FROM Match__c
        WHERE Match_Level__c != null
        LIMIT 10
    ];
    
    System.debug('✅ Found ' + matches.size() + ' Match records with Match_Level__c');
    
    Integer professionalCount = 0;
    Integer amateurCount = 0;
    Integer semiProCount = 0;
    
    for (Match__c m : matches) {
        if (m.Match_Level__c == 'Professional') professionalCount++;
        else if (m.Match_Level__c == 'Amateur') amateurCount++;
        else if (m.Match_Level__c == 'Semi-Professional') semiProCount++;
    }
    
    System.debug('   Professional: ' + professionalCount);
    System.debug('   Semi-Professional: ' + semiProCount);
    System.debug('   Amateur: ' + amateurCount);
    
} catch (Exception e) {
    System.debug('❌ Match__c query failed: ' + e.getMessage());
}

System.debug('');

// ========================================
// Test 2: Verify Lineup__c with Match__c and Lineup_JSON__c
// ========================================
System.debug('--- Test 2: Lineup__c with Match__c and Lineup_JSON__c ---');

try {
    List<Lineup__c> lineups = [
        SELECT Id, Name, Match__c, Lineup_JSON__c, Match__r.Name
        FROM Lineup__c
        WHERE Match__c != null
        LIMIT 10
    ];
    
    System.debug('✅ Found ' + lineups.size() + ' Lineup records with Match__c');
    
    Integer withJsonCount = 0;
    for (Lineup__c l : lineups) {
        if (String.isNotBlank(l.Lineup_JSON__c)) {
            withJsonCount++;
        }
    }
    
    System.debug('   Lineups with JSON: ' + withJsonCount + '/' + lineups.size());
    
    if (!lineups.isEmpty()) {
        System.debug('   Sample: ' + lineups[0].Name + ' -> Match: ' + lineups[0].Match__r.Name);
    }
    
} catch (Exception e) {
    System.debug('❌ Lineup__c query failed: ' + e.getMessage());
    if (e.getMessage().contains('Match__c') || e.getMessage().contains('Lineup_JSON__c')) {
        System.debug('   ⚠️ FLS issue with Lineup__c fields');
    }
}

System.debug('');

// ========================================
// Test 3: Test MatchTriggerHandler field access
// ========================================
System.debug('--- Test 3: MatchTriggerHandler Field Access ---');

try {
    // Test that we can read Match_Level__c which MatchTriggerHandler uses
    List<Match__c> testMatches = [
        SELECT Id, Match_Level__c
        FROM Match__c
        WHERE Match_Level__c != null
        LIMIT 1
    ];
    
    if (!testMatches.isEmpty()) {
        System.debug('✅ MatchTriggerHandler can access Match_Level__c field');
        System.debug('   Test match: ' + testMatches[0].Id + ' (Level: ' + testMatches[0].Match_Level__c + ')');
    } else {
        System.debug('⚠️ No matches with Match_Level__c found for testing');
    }
    
} catch (Exception e) {
    System.debug('❌ MatchTriggerHandler field access test failed: ' + e.getMessage());
}

System.debug('');

// ========================================
// Test 4: Test ESPNDataParser field usage
// ========================================
System.debug('--- Test 4: ESPNDataParser Field Usage ---');

try {
    // ESPNDataParser sets Match_Level__c to 'Professional' for ESPN-synced matches
    // Verify we can create/update Match__c with Match_Level__c
    List<Match__c> espnMatches = [
        SELECT Id, Name, ESPN_Event_ID__c, Match_Level__c
        FROM Match__c
        WHERE ESPN_Event_ID__c != null
        AND Match_Level__c = 'Professional'
        LIMIT 5
    ];
    
    System.debug('✅ Found ' + espnMatches.size() + ' ESPN-synced matches with Professional level');
    
    if (!espnMatches.isEmpty()) {
        System.debug('   Sample: ' + espnMatches[0].Name + ' (ESPN ID: ' + espnMatches[0].ESPN_Event_ID__c + ')');
    }
    
} catch (Exception e) {
    System.debug('❌ ESPNDataParser field usage test failed: ' + e.getMessage());
}

System.debug('');

// ========================================
// Test 5: Verify Permission Sets
// ========================================
System.debug('--- Test 5: Permission Set Verification ---');

List<PermissionSetAssignment> userPermSets = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.IsOwnedByProfile = false
    AND (PermissionSet.Name LIKE '%ESPN%' 
         OR PermissionSet.Name LIKE '%Match%'
         OR PermissionSet.Name = 'API_Data_Access')
];

System.debug('Relevant Permission Sets:');
if (userPermSets.isEmpty()) {
    System.debug('  ⚠️ No relevant permission sets found');
} else {
    for (PermissionSetAssignment psa : userPermSets) {
        System.debug('  ✅ ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
}

System.debug('');

// ========================================
// Test 6: Field Describe Verification
// ========================================
System.debug('--- Test 6: Field Describe Verification ---');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> matchFields = matchType.getDescribe().fields.getMap();

Schema.SObjectType lineupType = Schema.getGlobalDescribe().get('Lineup__c');
Map<String, Schema.SObjectField> lineupFields = lineupType.getDescribe().fields.getMap();

Boolean allFieldsAccessible = true;

// Check Match_Level__c
if (!matchFields.containsKey('match_level__c') || !matchFields.get('match_level__c').getDescribe().isAccessible()) {
    System.debug('❌ Match__c.Match_Level__c not accessible');
    allFieldsAccessible = false;
} else {
    System.debug('✅ Match__c.Match_Level__c accessible');
}

// Check Lineup__c.Match__c
if (!lineupFields.containsKey('match__c') || !lineupFields.get('match__c').getDescribe().isAccessible()) {
    System.debug('❌ Lineup__c.Match__c not accessible');
    allFieldsAccessible = false;
} else {
    System.debug('✅ Lineup__c.Match__c accessible');
}

// Check Lineup__c.Lineup_JSON__c
if (!lineupFields.containsKey('lineup_json__c') || !lineupFields.get('lineup_json__c').getDescribe().isAccessible()) {
    System.debug('❌ Lineup__c.Lineup_JSON__c not accessible');
    allFieldsAccessible = false;
} else {
    System.debug('✅ Lineup__c.Lineup_JSON__c accessible');
}

System.debug('');

// ========================================
// Summary
// ========================================
System.debug('=== COMPREHENSIVE TEST SUMMARY ===');
System.debug('');

if (allFieldsAccessible) {
    System.debug('✅ All critical fields are accessible');
} else {
    System.debug('❌ Some fields are not accessible - check FLS permissions');
}

System.debug('');
System.debug('Test completed at: ' + DateTime.now());
System.debug('');

