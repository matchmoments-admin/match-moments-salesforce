/**
 * SOQL Query Tests for Match Summary Components
 * Tests all SOQL queries used in MatchSummaryController
 * 
 * EXECUTE THIS ENTIRE FILE IN ANONYMOUS APEX
 */

System.debug('=== TEST MATCH SUMMARY SOQL QUERIES ===');
System.debug('');

// ========================================
// Get Test Data
// ========================================
List<Match__c> matches = [
    SELECT Id, Home_Team__c, Away_Team__c, Competition__c
    FROM Match__c
    LIMIT 1
];

if (matches.isEmpty()) {
    System.debug('❌ No Match__c records found');
    return;
}

Match__c testMatch = matches[0];
String matchId = testMatch.Id;

System.debug('Using Match ID: ' + matchId);
System.debug('');

// ========================================
// TEST 1: Match__c with all fields
// ========================================
System.debug('--- TEST 1: Match__c Query ---');
try {
    List<Match__c> matchQuery = [
        SELECT Id, Name, Match_Date_Time__c, Status__c, Venue__c, Attendance__c,
               Referee__c, Home_Score_Final__c, Away_Score_Final__c, Match_Stats_JSON__c,
               Home_Team__c, Away_Team__c, Competition__c
        FROM Match__c
        WHERE Id = :matchId
        LIMIT 1
    ];
    System.debug('✅ Match__c query: ' + matchQuery.size() + ' records');
} catch (Exception e) {
    System.debug('❌ Match__c query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// TEST 2: Account (Team) with logo fields
// ========================================
System.debug('--- TEST 2: Account (Team) Query with Logo Fields ---');
try {
    Set<Id> teamIds = new Set<Id>();
    if (testMatch.Home_Team__c != null) teamIds.add(testMatch.Home_Team__c);
    if (testMatch.Away_Team__c != null) teamIds.add(testMatch.Away_Team__c);
    
    if (!teamIds.isEmpty()) {
        List<Account> teams = [
            SELECT Id, Name, Team_Logo_URL__c, Team_Primary_Color__c, Logo_Url__c
            FROM Account
            WHERE Id IN :teamIds
        ];
        System.debug('✅ Account (Team) query: ' + teams.size() + ' records');
    } else {
        System.debug('⚠️  No team IDs to query');
    }
} catch (Exception e) {
    System.debug('❌ Account (Team) query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// TEST 3: Match_Moment__c for goal scorers
// ========================================
System.debug('--- TEST 3: Match_Moment__c Goal Scorers Query ---');
try {
    // Check if Description__c field exists
    Schema.DescribeSObjectResult momentDescribe = Match_Moment__c.SObjectType.getDescribe();
    Map<String, Schema.SObjectField> momentFields = momentDescribe.fields.getMap();
    Boolean hasDescription = momentFields.containsKey('Description__c');
    
    if (hasDescription) {
        List<Match_Moment__c> goals = [
            SELECT Id, Event_Minute__c, Event_Second__c, Description__c,
                   Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                   Team__r.Id, Team__r.Name
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            AND Event_Type__c = 'Goal'
            ORDER BY Event_Minute__c ASC, Event_Second__c ASC
        ];
        System.debug('✅ Match_Moment__c goals query: ' + goals.size() + ' records');
    } else {
        List<Match_Moment__c> goals = [
            SELECT Id, Event_Minute__c, Event_Second__c,
                   Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                   Team__r.Id, Team__r.Name
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            AND Event_Type__c = 'Goal'
            ORDER BY Event_Minute__c ASC, Event_Second__c ASC
        ];
        System.debug('✅ Match_Moment__c goals query (without Description__c): ' + goals.size() + ' records');
        System.debug('⚠️  Note: Description__c field not found');
    }
} catch (Exception e) {
    System.debug('❌ Match_Moment__c goals query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// TEST 4: Match_Moment__c for all moments
// ========================================
System.debug('--- TEST 4: Match_Moment__c All Moments Query ---');
try {
    // Check if Description__c field exists
    Schema.DescribeSObjectResult momentDescribe = Match_Moment__c.SObjectType.getDescribe();
    Map<String, Schema.SObjectField> momentFields = momentDescribe.fields.getMap();
    Boolean hasDescription = momentFields.containsKey('Description__c');
    
    if (hasDescription) {
        List<Match_Moment__c> moments = [
            SELECT Id, Event_Minute__c, Event_Second__c, Event_Type__c, Event_Sub_Type__c,
                   Description__c, Event_Importance__c, Is_Shareable__c,
                   Primary_Player__r.Id, Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                   Secondary_Player__r.Id, Secondary_Player__r.Name,
                   Team__r.Id, Team__r.Name, Team__r.Team_Logo_URL__c,
                   Match_Period__r.Period_Type__c
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            ORDER BY Event_Minute__c ASC, Event_Second__c ASC NULLS LAST
        ];
        System.debug('✅ Match_Moment__c all moments query: ' + moments.size() + ' records');
    } else {
        List<Match_Moment__c> moments = [
            SELECT Id, Event_Minute__c, Event_Second__c, Event_Type__c, Event_Sub_Type__c,
                   Event_Importance__c, Is_Shareable__c,
                   Primary_Player__r.Id, Primary_Player__r.Name, Primary_Player__r.Jersey_Number__c,
                   Secondary_Player__r.Id, Secondary_Player__r.Name,
                   Team__r.Id, Team__r.Name, Team__r.Team_Logo_URL__c,
                   Match_Period__r.Period_Type__c
            FROM Match_Moment__c
            WHERE Match__c = :matchId
            ORDER BY Event_Minute__c ASC, Event_Second__c ASC NULLS LAST
        ];
        System.debug('✅ Match_Moment__c all moments query (without Description__c): ' + moments.size() + ' records');
        System.debug('⚠️  Note: Description__c field not found');
    }
} catch (Exception e) {
    System.debug('❌ Match_Moment__c all moments query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// TEST 5: Lineup__c query
// ========================================
System.debug('--- TEST 5: Lineup__c Query ---');
try {
    List<Lineup__c> lineups = [
        SELECT Id, Match__c, Team__c, Formation__c, Lineup_JSON__c, Captain__c
        FROM Lineup__c
        WHERE Match__c = :matchId
    ];
    System.debug('✅ Lineup__c query: ' + lineups.size() + ' records');
} catch (Exception e) {
    System.debug('❌ Lineup__c query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// TEST 6: Team_Season_Stats__c query
// ========================================
System.debug('--- TEST 6: Team_Season_Stats__c Query ---');
if (testMatch.Competition__c != null) {
    try {
        List<Team_Season_Stats__c> teamStats = [
            SELECT Id, Team__r.Id, Team__r.Name, Team__r.Team_Logo_URL__c,
                   League_Position__c, Points__c, Wins__c, Draws__c, Losses__c,
                   Goals_For__c, Goals_Against__c, Goal_Difference__c, Matches_Played__c,
                   Home_Wins__c, Home_Draws__c, Home_Losses__c,
                   Away_Wins__c, Away_Draws__c, Away_Losses__c
            FROM Team_Season_Stats__c
            WHERE Competition__c = :testMatch.Competition__c
            ORDER BY League_Position__c ASC NULLS LAST, Points__c DESC, Goal_Difference__c DESC
            LIMIT 20
        ];
        System.debug('✅ Team_Season_Stats__c query: ' + teamStats.size() + ' records');
    } catch (Exception e) {
        System.debug('❌ Team_Season_Stats__c query FAILED: ' + e.getMessage());
    }
} else {
    System.debug('⚠️  Skipping Team_Season_Stats__c - no Competition__c');
}
System.debug('');

// ========================================
// TEST 7: Competition__c query
// ========================================
System.debug('--- TEST 7: Competition__c Query ---');
if (testMatch.Competition__c != null) {
    try {
        List<Competition__c> competitions = [
            SELECT Id, Name, ESPN_League_ID__c, Sport__c, Season_Year__c
            FROM Competition__c
            WHERE Id = :testMatch.Competition__c
        ];
        System.debug('✅ Competition__c query: ' + competitions.size() + ' records');
    } catch (Exception e) {
        System.debug('❌ Competition__c query FAILED: ' + e.getMessage());
    }
} else {
    System.debug('⚠️  Skipping Competition__c - no Competition__c');
}
System.debug('');

// ========================================
// TEST 8: Match_Moment__c for cards (stats aggregation)
// ========================================
System.debug('--- TEST 8: Match_Moment__c Cards Query (for stats) ---');
try {
    List<Match_Moment__c> cards = [
        SELECT Team__c, Event_Type__c
        FROM Match_Moment__c
        WHERE Match__c = :matchId
        AND (Event_Type__c = 'Yellow Card' OR Event_Type__c = 'Red Card')
    ];
    System.debug('✅ Match_Moment__c cards query: ' + cards.size() + ' records');
} catch (Exception e) {
    System.debug('❌ Match_Moment__c cards query FAILED: ' + e.getMessage());
}
System.debug('');

// ========================================
// SUMMARY
// ========================================
System.debug('=== SOQL TEST SUMMARY ===');
System.debug('✅ All SOQL queries tested');
System.debug('');

