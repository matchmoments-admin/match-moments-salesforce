/**
 * Simple Test for MatchSummaryController
 * Tests basic functionality without Description__c field dependency
 */

System.debug('=== SIMPLE MATCH SUMMARY CONTROLLER TEST ===');
System.debug('');

// Get a Match record
List<Match__c> matches = [
    SELECT Id, Name, Competition__c, Home_Team__c, Away_Team__c
    FROM Match__c
    LIMIT 1
];

if (matches.isEmpty()) {
    System.debug('❌ No Match__c records found');
    return;
}

String matchId = matches[0].Id;
System.debug('Testing with Match: ' + matchId);
System.debug('');

// Test 1: getMatchSummary
try {
    Map<String, Object> result = MatchSummaryController.getMatchSummary(matchId);
    System.debug('✅ getMatchSummary: SUCCESS');
    System.debug('   Keys: ' + result.keySet());
} catch (Exception e) {
    System.debug('❌ getMatchSummary: FAILED - ' + e.getMessage());
}

// Test 2: getMatchLineups
try {
    Map<String, Object> result = MatchSummaryController.getMatchLineups(matchId);
    System.debug('✅ getMatchLineups: SUCCESS');
    System.debug('   Keys: ' + result.keySet());
} catch (Exception e) {
    System.debug('❌ getMatchLineups: FAILED - ' + e.getMessage());
}

// Test 3: getMatchMoments
try {
    List<Map<String, Object>> result = MatchSummaryController.getMatchMoments(matchId);
    System.debug('✅ getMatchMoments: SUCCESS');
    System.debug('   Count: ' + result.size());
} catch (Exception e) {
    System.debug('❌ getMatchMoments: FAILED - ' + e.getMessage());
}

// Test 4: getMatchStats
try {
    Map<String, Object> result = MatchSummaryController.getMatchStats(matchId);
    System.debug('✅ getMatchStats: SUCCESS');
    System.debug('   Keys: ' + result.keySet());
} catch (Exception e) {
    System.debug('❌ getMatchStats: FAILED - ' + e.getMessage());
}

// Test 5: getLeagueTable (if competition exists)
if (matches[0].Competition__c != null) {
    try {
        Competition__c comp = [SELECT Season_Year__c FROM Competition__c WHERE Id = :matches[0].Competition__c LIMIT 1];
        List<Map<String, Object>> result = MatchSummaryController.getLeagueTable(matches[0].Competition__c, comp.Season_Year__c);
        System.debug('✅ getLeagueTable: SUCCESS');
        System.debug('   Count: ' + result.size());
    } catch (Exception e) {
        System.debug('❌ getLeagueTable: FAILED - ' + e.getMessage());
    }
}

System.debug('');
System.debug('=== TEST COMPLETE ===');

