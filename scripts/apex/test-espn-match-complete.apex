/**
 * Test comprehensive ESPN match data sync
 * Tests syncMatchComplete() with gameId 740788
 * Verifies all records are created: Match, Lineups, Match_Participation, Commentary, Match_Moment, Match_Period
 */

System.debug('=== TEST ESPN MATCH COMPLETE SYNC ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// Find or create a match with ESPN Event ID 740788
String espnEventId = '740788';

List<Match__c> existingMatches = [
    SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Home_Team__c, Away_Team__c
    FROM Match__c
    WHERE ESPN_Event_ID__c = :espnEventId
    LIMIT 1
];

Match__c testMatch;

if (existingMatches.isEmpty()) {
    System.debug('Match not found. Creating test match...');
    
    // Find Premier League competition
    List<Competition__c> competitions = [
        SELECT Id, Name, ESPN_League_ID__c
        FROM Competition__c
        WHERE ESPN_League_ID__c = 'eng.1'
        LIMIT 1
    ];
    
    if (competitions.isEmpty()) {
        System.debug('ERROR: Premier League competition not found. Please create it first.');
        return;
    }
    
    testMatch = new Match__c();
    testMatch.ESPN_Event_ID__c = espnEventId;
    testMatch.Competition__c = competitions[0].Id;
    testMatch.Match_Level__c = 'Professional';
    testMatch.Status__c = 'Completed';
    testMatch.Match_Date_Time__c = DateTime.newInstance(2026, 1, 3, 17, 30, 0);
    
    insert testMatch;
    System.debug('✓ Created test match: ' + testMatch.Id);
} else {
    testMatch = existingMatches[0];
    System.debug('Using existing match: ' + testMatch.Id + ' - ' + testMatch.Name);
}

System.debug('');

// Execute comprehensive sync
System.debug('=== EXECUTING COMPREHENSIVE SYNC ===');
try {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    IESPNSyncService syncService = ESPNSyncServiceImpl.newInstance();
    
    ESPNSyncResult result = syncService.syncMatchComplete(testMatch.Id, uow);
    
    if (result.success) {
        System.debug('✓ Sync initiated successfully');
        System.debug('Message: ' + result.message);
        
        // Commit the unit of work
        uow.commitWork();
        System.debug('✓ Unit of Work committed');
    } else {
        System.debug('✗ Sync failed: ' + result.errorMessage);
        return;
    }
} catch (Exception e) {
    System.debug('✗ ERROR during sync: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
    return;
}

System.debug('');

// Verify all records were created
System.debug('=== VERIFYING CREATED RECORDS ===');

// 1. Match
Match__c match = [
    SELECT Id, Name, ESPN_Event_ID__c, Home_Team__c, Away_Team__c,
           Home_Score_Final__c, Away_Score_Final__c, Status__c
    FROM Match__c
    WHERE Id = :testMatch.Id
    LIMIT 1
];
System.debug('Match: ' + match.Name);
System.debug('  Home Team: ' + match.Home_Team__c);
System.debug('  Away Team: ' + match.Away_Team__c);
System.debug('  Score: ' + match.Home_Score_Final__c + ' - ' + match.Away_Score_Final__c);
System.debug('');

// 2. Lineups
List<Lineup__c> lineups = [
    SELECT Id, Team__r.Name, Formation__c, Starting_XI_Count__c
    FROM Lineup__c
    WHERE Match__c = :testMatch.Id
];
System.debug('Lineups: ' + lineups.size());
for (Lineup__c lineup : lineups) {
    System.debug('  ' + lineup.Team__r.Name + ' - Formation: ' + lineup.Formation__c + 
                 ', Starters: ' + lineup.Starting_XI_Count__c);
}
System.debug('');

// 3. Match Participations
List<Match_Participation__c> participations = [
    SELECT Id, Player__r.Name, Position__c, Role__c
    FROM Match_Participation__c
    WHERE Match__c = :testMatch.Id
];
System.debug('Match Participations: ' + participations.size());
Integer starterCount = 0;
Integer substituteCount = 0;
for (Match_Participation__c p : participations) {
    if (p.Role__c == 'Starter') starterCount++;
    if (p.Role__c == 'Substitute') substituteCount++;
}
System.debug('  Starters: ' + starterCount);
System.debug('  Substitutes: ' + substituteCount);
System.debug('');

// 4. Commentary
List<Commentary__c> commentaries = [
    SELECT Id, Name
    FROM Commentary__c
    WHERE Match__c = :testMatch.Id
];
System.debug('Commentaries: ' + commentaries.size());
System.debug('');

// 5. Match Moments
List<Match_Moment__c> moments = [
    SELECT Id, Event_Type__c, Event_Minute__c, Description__c
    FROM Match_Moment__c
    WHERE Match__c = :testMatch.Id
    ORDER BY Event_Time__c ASC
    LIMIT 10
];
System.debug('Match Moments: ' + [
    SELECT COUNT() 
    FROM Match_Moment__c 
    WHERE Match__c = :testMatch.Id
]);
System.debug('Sample moments (first 10):');
for (Match_Moment__c moment : moments) {
    System.debug('  ' + moment.Event_Minute__c + '\' - ' + moment.Event_Type__c + ': ' + 
                 (moment.Description__c != null ? moment.Description__c.left(50) : ''));
}
System.debug('');

// 6. Match Periods
List<Match_Period__c> periods = [
    SELECT Id, Period_Number__c, Period_Type__c, 
           Home_Score_Period__c, Away_Score_Period__c,
           Home_Score_Cumulative__c, Away_Score_Cumulative__c
    FROM Match_Period__c
    WHERE Match__c = :testMatch.Id
    ORDER BY Period_Number__c ASC
];
System.debug('Match Periods: ' + periods.size());
for (Match_Period__c period : periods) {
    System.debug('  Period ' + period.Period_Number__c + ' (' + period.Period_Type__c + '): ' +
                 period.Home_Score_Period__c + ' - ' + period.Away_Score_Period__c +
                 ' (Cumulative: ' + period.Home_Score_Cumulative__c + ' - ' + 
                 period.Away_Score_Cumulative__c + ')');
}
System.debug('');

System.debug('=== TEST COMPLETE ===');
System.debug('Completed at: ' + DateTime.now());

