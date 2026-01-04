/**
 * Sync fixtures for Men's Premier League for the last week
 * This will sync fixtures, teams, and players
 */

System.debug('=== ESPN SYNC: MEN\'S PREMIER LEAGUE - LAST WEEK ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// Calculate date range: 7 days ago to today
Date startDate = Date.today().addDays(-7);
Date endDate = Date.today();

System.debug('Date Range: ' + startDate + ' to ' + endDate);
System.debug('');

// Find Premier League competition
List<Competition__c> competitions = [
    SELECT Id, Name, ESPN_League_ID__c, Sport__c
    FROM Competition__c
    WHERE ESPN_League_ID__c = 'eng.1'
    AND Status__c = 'Active'
    LIMIT 1
];

if (competitions.isEmpty()) {
    System.debug('Premier League competition not found. Creating...');
    Id compId = ESPNSyncService.getOrCreateCompetition('eng.1', 'Premier League 2024-25', 'Soccer', '2024-2025');
    Competition__c newComp = [SELECT Id, Name, ESPN_League_ID__c FROM Competition__c WHERE Id = :compId LIMIT 1];
    competitions.add(newComp);
    System.debug('✓ Created/found competition: ' + newComp.Id);
}

Competition__c premierLeague = competitions[0];
System.debug('Using Competition: ' + premierLeague.Name + ' (' + premierLeague.Id + ')');
System.debug('');

// Step 1: Sync teams first (if needed)
System.debug('=== STEP 1: Syncing Teams ===');
try {
    Integer teamsSynced = ESPNSyncService.syncLeagueTeams('soccer', 'eng.1');
    System.debug('✓ Synced ' + teamsSynced + ' teams');
} catch (Exception e) {
    System.debug('✗ ERROR syncing teams: ' + e.getMessage());
}
System.debug('');

// Step 2: Sync fixtures for the last week
System.debug('=== STEP 2: Syncing Fixtures (Last Week) ===');
try {
    Integer fixturesSynced = ESPNSyncService.syncFixturesForDateRange(
        'soccer',
        'eng.1',
        startDate,
        endDate,
        premierLeague.Id
    );
    System.debug('✓ Synced ' + fixturesSynced + ' fixtures');
} catch (Exception e) {
    System.debug('✗ ERROR syncing fixtures: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}
System.debug('');

// Step 3: Sync rosters for all teams (optional - can be slow)
System.debug('=== STEP 3: Syncing Player Rosters ===');
try {
    Integer playersSynced = ESPNSyncService.syncAllRostersForLeague('soccer', 'eng.1');
    System.debug('✓ Synced ' + playersSynced + ' players');
} catch (Exception e) {
    System.debug('✗ ERROR syncing rosters: ' + e.getMessage());
}
System.debug('');

// Step 4: Verify synced fixtures and check Match_Level__c
System.debug('=== STEP 4: Verifying Synced Data ===');

List<Match__c> syncedMatches = [
    SELECT Id, Name, Match_Level__c, Status__c, Match_Date_Time__c,
           Home_Team__r.Name, Away_Team__r.Name, ESPN_Event_ID__c
    FROM Match__c
    WHERE Competition__c = :premierLeague.Id
    AND Match_Date_Time__c >= :startDate
    AND Match_Date_Time__c <= :endDate
    ORDER BY Match_Date_Time__c DESC
];

System.debug('Found ' + syncedMatches.size() + ' matches in date range:');
System.debug('');

Integer professionalCount = 0;
Integer nullCount = 0;
Integer otherCount = 0;

for (Match__c match : syncedMatches) {
    if (match.Match_Level__c == 'Professional') {
        professionalCount++;
    } else if (match.Match_Level__c == null) {
        nullCount++;
    } else {
        otherCount++;
    }
    
    System.debug(
        '  ' + match.Match_Date_Time__c.format('yyyy-MM-dd HH:mm') + 
        ' | ' + match.Home_Team__r.Name + 
        ' vs ' + match.Away_Team__r.Name + 
        ' | Level: ' + (match.Match_Level__c != null ? match.Match_Level__c : 'NULL') +
        ' | Status: ' + match.Status__c
    );
}

System.debug('');
System.debug('=== MATCH LEVEL SUMMARY ===');
System.debug('Professional: ' + professionalCount);
System.debug('Null: ' + nullCount);
System.debug('Other: ' + otherCount);
System.debug('');

// If there are matches with null Match_Level__c, backfill them
if (nullCount > 0) {
    System.debug('=== BACKFILLING NULL MATCH_LEVEL__C ===');
    List<Match__c> matchesToUpdate = new List<Match__c>();
    
    for (Match__c match : syncedMatches) {
        if (match.Match_Level__c == null) {
            match.Match_Level__c = 'Professional';
            matchesToUpdate.add(match);
        }
    }
    
    if (!matchesToUpdate.isEmpty()) {
        try {
            update matchesToUpdate;
            System.debug('✓ Backfilled ' + matchesToUpdate.size() + ' matches with Match_Level__c = Professional');
        } catch (Exception e) {
            System.debug('✗ ERROR backfilling: ' + e.getMessage());
        }
    }
}

System.debug('');
System.debug('=== SYNC COMPLETE ===');
System.debug('Completed at: ' + DateTime.now());

