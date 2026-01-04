/**
 * Comprehensive test script for ESPN lineup player creation
 * Tests both specific gameId 740776 and existing matches in org
 * Verifies:
 * - Players are created from ESPN lineup data
 * - Match_Participation__c records have Person__c set correctly
 * - Person__c = Player__c for all participations
 * - No duplicate players created
 * - Proper error handling
 */

System.debug('=== TEST ESPN LINEUP PLAYER CREATION ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// ========================================
// TEST SCENARIO 1: Specific gameId 740776
// ========================================
System.debug('=== TEST SCENARIO 1: GameId 740776 ===');

String espnEventId = '740776';

// Find or create match with ESPN Event ID 740776
List<Match__c> existingMatches = [
    SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Competition__r.Sport__c, 
           Competition__r.ESPN_League_ID__c, Home_Team__c, Away_Team__c
    FROM Match__c
    WHERE ESPN_Event_ID__c = :espnEventId
    LIMIT 1
];

Match__c testMatch;

if (existingMatches.isEmpty()) {
    System.debug('Match not found. Creating test match...');
    
    // Find Premier League competition (default for soccer)
    List<Competition__c> competitions = [
        SELECT Id, Name, ESPN_League_ID__c, Sport__c
        FROM Competition__c
        WHERE ESPN_League_ID__c = 'eng.1'
        OR Name LIKE '%Premier League%'
        LIMIT 1
    ];
    
    if (competitions.isEmpty()) {
        System.debug('WARNING: Premier League competition not found. Trying to find any soccer competition...');
        competitions = [
            SELECT Id, Name, ESPN_League_ID__c, Sport__c
            FROM Competition__c
            WHERE Sport__c = 'Soccer'
            LIMIT 1
        ];
    }
    
    if (competitions.isEmpty()) {
        System.debug('ERROR: No soccer competition found. Please create a Competition__c record first.');
        System.debug('Skipping Scenario 1, proceeding to Scenario 2...');
        testMatch = null;
    } else {
        testMatch = new Match__c();
        testMatch.ESPN_Event_ID__c = espnEventId;
        testMatch.Competition__c = competitions[0].Id;
        testMatch.Match_Level__c = 'Professional';
        testMatch.Status__c = 'Scheduled';
        testMatch.Match_Date_Time__c = DateTime.now().addDays(1);
        
        insert testMatch;
        System.debug('✓ Created test match: ' + testMatch.Id);
    }
} else {
    testMatch = existingMatches[0];
    System.debug('Using existing match: ' + testMatch.Id + ' - ' + testMatch.Name);
}

if (testMatch != null) {
    // Count players before sync
    Integer playersBefore = [
        SELECT COUNT()
        FROM Contact
        WHERE ESPN_Player_ID__c != null
    ];
    System.debug('Players in org before sync: ' + playersBefore);
    
    // Execute lineup sync
    System.debug('=== EXECUTING LINEUP SYNC ===');
    try {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        IESPNSyncService syncService = ESPNSyncServiceImpl.newInstance();
        
        ESPNSyncResult result = syncService.syncMatchLineups(testMatch.Id, uow);
        
        if (result.success) {
            System.debug('✓ Lineup sync initiated successfully');
            System.debug('Message: ' + result.message);
            
            // Commit the unit of work
            uow.commitWork();
            System.debug('✓ Unit of Work committed');
        } else {
            System.debug('✗ Lineup sync failed: ' + result.errorMessage);
        }
    } catch (Exception e) {
        System.debug('✗ ERROR during lineup sync: ' + e.getMessage());
        System.debug('Stack: ' + e.getStackTraceString());
    }
    
    // Count players after sync
    Integer playersAfter = [
        SELECT COUNT()
        FROM Contact
        WHERE ESPN_Player_ID__c != null
    ];
    System.debug('Players in org after sync: ' + playersAfter);
    System.debug('New players created: ' + (playersAfter - playersBefore));
    
    // Verify Match_Participation__c records
    System.debug('');
    System.debug('=== VERIFYING MATCH PARTICIPATIONS ===');
    List<Match_Participation__c> participations = [
        SELECT Id, Match__c, Team__c, Player__c, Person__c, Position__c, 
               Role__c, Starting_Lineup__c, Substitute__c,
               Player__r.Name, Player__r.ESPN_Player_ID__c
        FROM Match_Participation__c
        WHERE Match__c = :testMatch.Id
    ];
    
    System.debug('Total participations: ' + participations.size());
    
    Integer participationsWithPerson = 0;
    Integer participationsWithoutPerson = 0;
    Integer participationsPersonMismatch = 0;
    
    for (Match_Participation__c p : participations) {
        if (p.Person__c == null) {
            participationsWithoutPerson++;
            System.debug('✗ Participation missing Person__c: ' + p.Id + ' - Player: ' + p.Player__r.Name);
        } else if (p.Person__c != p.Player__c) {
            participationsPersonMismatch++;
            System.debug('✗ Person__c != Player__c: ' + p.Id + ' - Player: ' + p.Player__r.Name + 
                        ' (Player__c: ' + p.Player__c + ', Person__c: ' + p.Person__c + ')');
        } else {
            participationsWithPerson++;
        }
    }
    
    System.debug('Participations with Person__c set correctly: ' + participationsWithPerson);
    System.debug('Participations missing Person__c: ' + participationsWithoutPerson);
    System.debug('Participations with Person__c mismatch: ' + participationsPersonMismatch);
    
    // Verify Lineup records
    Integer lineupCount = [
        SELECT COUNT()
        FROM Lineup__c
        WHERE Match__c = :testMatch.Id
    ];
    System.debug('');
    System.debug('Lineups created: ' + lineupCount);
    
    if (participationsWithoutPerson == 0 && participationsPersonMismatch == 0) {
        System.debug('✓ Scenario 1 PASSED: All participations have Person__c set correctly');
    } else {
        System.debug('✗ Scenario 1 FAILED: Some participations have Person__c issues');
    }
} else {
    System.debug('⚠ Scenario 1 SKIPPED: Could not create/find match');
}

System.debug('');
System.debug('');

// ========================================
// TEST SCENARIO 2: Existing match in org
// ========================================
System.debug('=== TEST SCENARIO 2: Existing Match in Org ===');

// Find an existing match with ESPN Event ID
List<Match__c> existingMatchesWithEventId = [
    SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Competition__r.Sport__c,
           Competition__r.ESPN_League_ID__c, Home_Team__c, Away_Team__c
    FROM Match__c
    WHERE ESPN_Event_ID__c != null
    AND ESPN_Event_ID__c != :espnEventId  // Exclude the one we just tested
    LIMIT 1
];

if (existingMatchesWithEventId.isEmpty()) {
    System.debug('⚠ No other matches with ESPN Event ID found. Skipping Scenario 2.');
} else {
    Match__c existingMatch = existingMatchesWithEventId[0];
    System.debug('Using existing match: ' + existingMatch.Id + ' - ' + existingMatch.Name);
    System.debug('ESPN Event ID: ' + existingMatch.ESPN_Event_ID__c);
    
    // Count existing participations
    Integer participationsBefore = [
        SELECT COUNT()
        FROM Match_Participation__c
        WHERE Match__c = :existingMatch.Id
    ];
    System.debug('Existing participations before sync: ' + participationsBefore);
    
    // Execute lineup sync
    System.debug('=== EXECUTING LINEUP SYNC ===');
    try {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        IESPNSyncService syncService = ESPNSyncServiceImpl.newInstance();
        
        ESPNSyncResult result = syncService.syncMatchLineups(existingMatch.Id, uow);
        
        if (result.success) {
            System.debug('✓ Lineup sync initiated successfully');
            System.debug('Message: ' + result.message);
            
            // Commit the unit of work
            uow.commitWork();
            System.debug('✓ Unit of Work committed');
        } else {
            System.debug('✗ Lineup sync failed: ' + result.errorMessage);
        }
    } catch (Exception e) {
        System.debug('✗ ERROR during lineup sync: ' + e.getMessage());
        System.debug('Stack: ' + e.getStackTraceString());
    }
    
    // Count participations after sync
    Integer participationsAfter = [
        SELECT COUNT()
        FROM Match_Participation__c
        WHERE Match__c = :existingMatch.Id
    ];
    System.debug('Participations after sync: ' + participationsAfter);
    
    // Verify all participations have Person__c set
    List<Match_Participation__c> allParticipations = [
        SELECT Id, Player__c, Person__c, Player__r.Name
        FROM Match_Participation__c
        WHERE Match__c = :existingMatch.Id
    ];
    
    Integer validParticipations = 0;
    Integer invalidParticipations = 0;
    
    for (Match_Participation__c p : allParticipations) {
        if (p.Person__c != null && p.Person__c == p.Player__c) {
            validParticipations++;
        } else {
            invalidParticipations++;
            System.debug('✗ Invalid participation: ' + p.Id + ' - Player: ' + p.Player__r.Name);
        }
    }
    
    System.debug('Valid participations (Person__c set correctly): ' + validParticipations);
    System.debug('Invalid participations: ' + invalidParticipations);
    
    if (invalidParticipations == 0) {
        System.debug('✓ Scenario 2 PASSED: All participations have Person__c set correctly');
    } else {
        System.debug('✗ Scenario 2 FAILED: Some participations have Person__c issues');
    }
}

System.debug('');
System.debug('');

// ========================================
// OVERALL VERIFICATION
// ========================================
System.debug('=== OVERALL VERIFICATION ===');

// Find all Match_Participation__c records with missing Person__c
List<Match_Participation__c> missingPerson = [
    SELECT Id, Match__c, Player__c, Player__r.Name
    FROM Match_Participation__c
    WHERE Person__c = null
    LIMIT 10
];

if (missingPerson.isEmpty()) {
    System.debug('✓ No Match_Participation__c records with missing Person__c found');
} else {
    System.debug('✗ Found ' + missingPerson.size() + ' Match_Participation__c records with missing Person__c:');
    for (Match_Participation__c p : missingPerson) {
        System.debug('  - ' + p.Id + ' - Player: ' + p.Player__r.Name);
    }
}

// Find all Match_Participation__c records where Person__c != Player__c
// Note: SOQL doesn't support field-to-field comparison, so we query and filter in Apex
List<Match_Participation__c> allParticipationsWithPerson = [
    SELECT Id, Match__c, Player__c, Person__c, Player__r.Name
    FROM Match_Participation__c
    WHERE Person__c != null
    LIMIT 100
];

List<Match_Participation__c> mismatchedPerson = new List<Match_Participation__c>();
for (Match_Participation__c p : allParticipationsWithPerson) {
    if (p.Person__c != p.Player__c) {
        mismatchedPerson.add(p);
    }
}

if (mismatchedPerson.isEmpty()) {
    System.debug('✓ No Match_Participation__c records with Person__c != Player__c found');
} else {
    System.debug('✗ Found ' + mismatchedPerson.size() + ' Match_Participation__c records with Person__c != Player__c:');
    for (Match_Participation__c p : mismatchedPerson) {
        System.debug('  - ' + p.Id + ' - Player: ' + p.Player__r.Name + 
                    ' (Player__c: ' + p.Player__c + ', Person__c: ' + p.Person__c + ')');
    }
}

// Count players by team
System.debug('');
System.debug('=== PLAYER STATISTICS ===');
Integer totalPlayers = [
    SELECT COUNT()
    FROM Contact
    WHERE ESPN_Player_ID__c != null
];
System.debug('Total players with ESPN_Player_ID__c: ' + totalPlayers);

// Check for duplicate ESPN Player IDs
List<AggregateResult> duplicatePlayers = [
    SELECT ESPN_Player_ID__c, COUNT(Id) playerCount
    FROM Contact
    WHERE ESPN_Player_ID__c != null
    GROUP BY ESPN_Player_ID__c
    HAVING COUNT(Id) > 1
    LIMIT 10
];

if (duplicatePlayers.isEmpty()) {
    System.debug('✓ No duplicate ESPN_Player_ID__c found');
} else {
    System.debug('✗ Found ' + duplicatePlayers.size() + ' duplicate ESPN_Player_ID__c:');
    for (AggregateResult ar : duplicatePlayers) {
        System.debug('  - ESPN_Player_ID__c: ' + ar.get('ESPN_Player_ID__c') + 
                    ' - Count: ' + ar.get('playerCount'));
    }
}

System.debug('');
System.debug('=== TEST COMPLETE ===');
System.debug('Completed at: ' + DateTime.now());

