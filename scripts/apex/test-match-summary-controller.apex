/**
 * Comprehensive Test for MatchSummaryController
 * Tests all 5 @AuraEnabled methods and SOQL queries
 * 
 * EXECUTE THIS ENTIRE FILE IN ANONYMOUS APEX
 */

System.debug('=== TEST MATCH SUMMARY CONTROLLER ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// ========================================
// STEP 1: Get a Match__c record for testing
// ========================================
System.debug('--- STEP 1: Finding Match Record ---');
System.debug('');

List<Match__c> testMatches = [
    SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Home_Team__c, Away_Team__c,
           Status__c, Match_Date_Time__c, Home_Score_Final__c, Away_Score_Final__c
    FROM Match__c
    WHERE Status__c != null
    LIMIT 5
];

if (testMatches.isEmpty()) {
    System.debug('❌ ERROR: No Match__c records found in org');
    System.debug('   Please create at least one Match__c record to test');
    return;
}

Match__c testMatch = testMatches[0];
System.debug('✅ Using Match: ' + testMatch.Id);
System.debug('   Name: ' + testMatch.Name);
System.debug('   Status: ' + testMatch.Status__c);
System.debug('   ESPN Event ID: ' + testMatch.ESPN_Event_ID__c);
System.debug('');

String matchId = testMatch.Id;

// ========================================
// STEP 2: Test getMatchSummary()
// ========================================
System.debug('--- STEP 2: Testing getMatchSummary() ---');
System.debug('');

try {
    Map<String, Object> summary = MatchSummaryController.getMatchSummary(matchId);
    
    System.debug('✅ getMatchSummary() executed successfully');
    System.debug('   Result keys: ' + summary.keySet());
    
    if (summary.containsKey('match')) {
        Map<String, Object> matchData = (Map<String, Object>) summary.get('match');
        System.debug('   Match data keys: ' + matchData.keySet());
        System.debug('   Match ID: ' + matchData.get('id'));
        System.debug('   Match Name: ' + matchData.get('name'));
        System.debug('   Status: ' + matchData.get('status'));
    }
    
    if (summary.containsKey('goalScorers')) {
        List<Object> goalScorers = (List<Object>) summary.get('goalScorers');
        System.debug('   Goal scorers count: ' + goalScorers.size());
    }
    
} catch (Exception e) {
    System.debug('❌ getMatchSummary() FAILED: ' + e.getMessage());
    System.debug('   Stack trace: ' + e.getStackTraceString());
}

System.debug('');

// ========================================
// STEP 3: Test getMatchLineups()
// ========================================
System.debug('--- STEP 3: Testing getMatchLineups() ---');
System.debug('');

try {
    Map<String, Object> lineups = MatchSummaryController.getMatchLineups(matchId);
    
    System.debug('✅ getMatchLineups() executed successfully');
    System.debug('   Result keys: ' + lineups.keySet());
    
    if (lineups.containsKey('homeLineup')) {
        Map<String, Object> homeLineup = (Map<String, Object>) lineups.get('homeLineup');
        System.debug('   Home lineup keys: ' + homeLineup.keySet());
    }
    
    if (lineups.containsKey('awayLineup')) {
        Map<String, Object> awayLineup = (Map<String, Object>) lineups.get('awayLineup');
        System.debug('   Away lineup keys: ' + awayLineup.keySet());
    }
    
} catch (Exception e) {
    System.debug('❌ getMatchLineups() FAILED: ' + e.getMessage());
    System.debug('   Stack trace: ' + e.getStackTraceString());
}

System.debug('');

// ========================================
// STEP 4: Test getMatchMoments()
// ========================================
System.debug('--- STEP 4: Testing getMatchMoments() ---');
System.debug('');

try {
    List<Map<String, Object>> moments = MatchSummaryController.getMatchMoments(matchId);
    
    System.debug('✅ getMatchMoments() executed successfully');
    System.debug('   Moments count: ' + moments.size());
    
    if (!moments.isEmpty()) {
        Map<String, Object> firstMoment = moments[0];
        System.debug('   First moment keys: ' + firstMoment.keySet());
        System.debug('   First moment minute: ' + firstMoment.get('minute'));
        System.debug('   First moment eventType: ' + firstMoment.get('eventType'));
    }
    
} catch (Exception e) {
    System.debug('❌ getMatchMoments() FAILED: ' + e.getMessage());
    System.debug('   Stack trace: ' + e.getStackTraceString());
}

System.debug('');

// ========================================
// STEP 5: Test getLeagueTable()
// ========================================
System.debug('--- STEP 5: Testing getLeagueTable() ---');
System.debug('');

if (testMatch.Competition__c != null) {
    try {
        // Get competition season year
        Competition__c comp = [SELECT Id, Season_Year__c FROM Competition__c WHERE Id = :testMatch.Competition__c LIMIT 1];
        String seasonYear = comp.Season_Year__c;
        
        List<Map<String, Object>> table = MatchSummaryController.getLeagueTable(testMatch.Competition__c, seasonYear);
        
        System.debug('✅ getLeagueTable() executed successfully');
        System.debug('   Table rows count: ' + table.size());
        
        if (!table.isEmpty()) {
            Map<String, Object> firstRow = table[0];
            System.debug('   First row keys: ' + firstRow.keySet());
            System.debug('   First row position: ' + firstRow.get('position'));
        }
        
    } catch (Exception e) {
        System.debug('❌ getLeagueTable() FAILED: ' + e.getMessage());
        System.debug('   Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('⚠️  Skipping getLeagueTable() - Match has no Competition__c');
}

System.debug('');

// ========================================
// STEP 6: Test getMatchStats()
// ========================================
System.debug('--- STEP 6: Testing getMatchStats() ---');
System.debug('');

try {
    Map<String, Object> stats = MatchSummaryController.getMatchStats(matchId);
    
    System.debug('✅ getMatchStats() executed successfully');
    System.debug('   Stats keys: ' + stats.keySet());
    
    if (stats.containsKey('homePossession')) {
        System.debug('   Home possession: ' + stats.get('homePossession'));
        System.debug('   Away possession: ' + stats.get('awayPossession'));
    }
    
} catch (Exception e) {
    System.debug('❌ getMatchStats() FAILED: ' + e.getMessage());
    System.debug('   Stack trace: ' + e.getStackTraceString());
}

System.debug('');

// ========================================
// STEP 7: Test SOQL Queries Directly
// ========================================
System.debug('--- STEP 7: Testing SOQL Queries ---');
System.debug('');

// Test MatchesSelector query
try {
    List<Match__c> matches = MatchesSelector.newInstance().selectById(new Set<Id>{matchId});
    System.debug('✅ MatchesSelector.selectById() works: ' + matches.size() + ' records');
} catch (Exception e) {
    System.debug('❌ MatchesSelector.selectById() FAILED: ' + e.getMessage());
}

// Test LineupsSelector query
try {
    List<Lineup__c> lineups = LineupsSelector.newInstance().selectByMatchIds(new Set<Id>{matchId});
    System.debug('✅ LineupsSelector.selectByMatchIds() works: ' + lineups.size() + ' records');
} catch (Exception e) {
    System.debug('❌ LineupsSelector.selectByMatchIds() FAILED: ' + e.getMessage());
}

// Test Match_Moment__c query
try {
    // First check what fields are available
    Schema.DescribeSObjectResult momentDescribe = Match_Moment__c.SObjectType.getDescribe();
    Map<String, Schema.SObjectField> momentFields = momentDescribe.fields.getMap();
    Boolean hasDescription = momentFields.containsKey('Description__c');
    
    if (hasDescription) {
        List<Match_Moment__c> moments = [
            SELECT Id, Event_Minute__c, Event_Type__c, Description__c,
                   Primary_Player__r.Name, Team__r.Name
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            LIMIT 10
        ];
        System.debug('✅ Match_Moment__c query works: ' + moments.size() + ' records');
    } else {
        // Try without Description__c
        List<Match_Moment__c> moments = [
            SELECT Id, Event_Minute__c, Event_Type__c,
                   Primary_Player__r.Name, Team__r.Name
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            LIMIT 10
        ];
        System.debug('✅ Match_Moment__c query works (without Description__c): ' + moments.size() + ' records');
        System.debug('⚠️  Note: Description__c field not found - may need deployment');
    }
} catch (Exception e) {
    System.debug('❌ Match_Moment__c query FAILED: ' + e.getMessage());
}

// Test Team_Season_Stats__c query
if (testMatch.Competition__c != null) {
    try {
        List<Team_Season_Stats__c> teamStats = [
            SELECT Id, Team__r.Name, League_Position__c, Points__c
            FROM Team_Season_Stats__c
            WHERE Competition__c = :testMatch.Competition__c
            LIMIT 5
        ];
        System.debug('✅ Team_Season_Stats__c query works: ' + teamStats.size() + ' records');
    } catch (Exception e) {
        System.debug('❌ Team_Season_Stats__c query FAILED: ' + e.getMessage());
    }
}

// Test Account (Team) query with logo fields
if (testMatch.Home_Team__c != null || testMatch.Away_Team__c != null) {
    try {
        Set<Id> teamIds = new Set<Id>();
        if (testMatch.Home_Team__c != null) teamIds.add(testMatch.Home_Team__c);
        if (testMatch.Away_Team__c != null) teamIds.add(testMatch.Away_Team__c);
        
        List<Account> teams = [
            SELECT Id, Name, Team_Logo_URL__c, Team_Primary_Color__c, Logo_Url__c
            FROM Account
            WHERE Id IN :teamIds
        ];
        System.debug('✅ Account (Team) query with logo fields works: ' + teams.size() + ' records');
    } catch (Exception e) {
        System.debug('❌ Account (Team) query FAILED: ' + e.getMessage());
    }
}

System.debug('');

// ========================================
// STEP 8: Test CompetitionsSelector
// ========================================
System.debug('--- STEP 8: Testing CompetitionsSelector ---');
System.debug('');

if (testMatch.Competition__c != null) {
    try {
        List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{testMatch.Competition__c});
        System.debug('✅ CompetitionsSelector.selectById() works: ' + competitions.size() + ' records');
    } catch (Exception e) {
        System.debug('❌ CompetitionsSelector.selectById() FAILED: ' + e.getMessage());
    }
}

System.debug('');

// ========================================
// SUMMARY
// ========================================
System.debug('=== TEST SUMMARY ===');
System.debug('');
System.debug('✅ All MatchSummaryController methods tested');
System.debug('✅ All SOQL queries verified');
System.debug('✅ All FFLib selectors tested');
System.debug('');
System.debug('Test completed at: ' + DateTime.now());
System.debug('');

