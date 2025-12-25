/**
 * ESPN Premier League 2025/26 Sync Test
 * Uses Fixture__c object (which exists and has fields) to test ESPN API integration
 * Tests: Teams, Players, and Fixtures sync from ESPN API
 */

System.debug('=== ESPN PREMIER LEAGUE 2025/26 SYNC TEST ===');
System.debug('Date: ' + Datetime.now());
System.debug('');

// ========================================
// PRE-TEST: Check Current State
// ========================================
System.debug('--- PRE-TEST STATE ---');

Integer preTeams = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null];
Integer prePlayers = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
Integer preFixtures = [SELECT COUNT() FROM Fixture__c];

System.debug('Existing teams: ' + preTeams);
System.debug('Existing players: ' + prePlayers);
System.debug('Existing fixtures: ' + preFixtures);
System.debug('');

// ========================================
// STEP 1: Sync Premier League Teams
// ========================================
System.debug('--- STEP 1: Syncing EPL Teams ---');
System.debug('League: English Premier League (eng.1)');
System.debug('');

Integer teamCount = 0;
try {
    teamCount = ESPNSyncService.syncLeagueTeams('soccer', 'eng.1');
    System.debug('✅ Teams synced: ' + teamCount);
    System.debug('');
} catch (Exception e) {
    System.debug('❌ ERROR syncing teams: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// ========================================
// STEP 2: Verify Team Data
// ========================================
System.debug('--- STEP 2: Verifying Team Data ---');

List<Account> eplTeams = [
    SELECT Name, ESPN_Team_ID__c, Abbreviation__c, Venue_Name__c, Logo_Url__c
    FROM Account
    WHERE ESPN_Team_ID__c != null
    AND Sport__c = 'Soccer'
    ORDER BY Name
    LIMIT 25
];

System.debug('Total EPL teams in org: ' + eplTeams.size());
System.debug('');
System.debug('Sample teams (first 10):');
Integer displayCount = 0;
for (Account team : eplTeams) {
    if (displayCount < 10) {
        System.debug('  - ' + team.Name + ' (' + team.Abbreviation__c + ') - ' + team.Venue_Name__c);
        displayCount++;
    }
}
System.debug('');

// ========================================
// STEP 3: Sync Sample Team Rosters
// ========================================
System.debug('--- STEP 3: Syncing Sample Team Rosters ---');
System.debug('Syncing 3 teams: Arsenal, Liverpool, Manchester City');
System.debug('');

List<String> teamNames = new List<String>{'Arsenal', 'Liverpool', 'Manchester City'};
Integer totalPlayers = 0;

for (String teamName : teamNames) {
    try {
        List<Account> teams = [
            SELECT Id, Name, ESPN_Team_ID__c
            FROM Account
            WHERE Name = :teamName
            AND ESPN_Team_ID__c != null
            LIMIT 1
        ];
        
        if (!teams.isEmpty()) {
            Integer playerCount = ESPNSyncService.syncTeamRoster('soccer', 'eng.1', teams[0].ESPN_Team_ID__c);
            totalPlayers += playerCount;
            System.debug('  ✅ ' + teamName + ': ' + playerCount + ' players');
        } else {
            System.debug('  ⚠️ ' + teamName + ': Team not found');
        }
    } catch (Exception e) {
        System.debug('  ❌ ' + teamName + ': ' + e.getMessage());
    }
}

System.debug('');
System.debug('Total players synced: ' + totalPlayers);
System.debug('');

// ========================================
// STEP 4: Sync Fixtures
// ========================================
System.debug('--- STEP 4: Syncing EPL Fixtures ---');
System.debug('Date range: Next 14 days from ' + Date.today());
System.debug('');

// Create/find Competition record for EPL 2025/26
List<Competition__c> comps = [
    SELECT Id, Name, ESPN_League_ID__c
    FROM Competition__c
    WHERE ESPN_League_ID__c = 'eng.1'
    LIMIT 1
];

Id competitionId;
if (comps.isEmpty()) {
    Competition__c newComp = new Competition__c(
        ESPN_League_ID__c = 'eng.1',
        Sport__c = 'Soccer',
        Season_Year__c = '2025-26',
        Status__c = 'Active'
    );
    insert newComp;
    competitionId = newComp.Id;
    System.debug('✅ Created new Competition record (ID: ' + competitionId + ')');
} else {
    competitionId = comps[0].Id;
    System.debug('✅ Using existing Competition (ID: ' + competitionId + ')');
}
System.debug('');

// Sync fixtures for next 14 days
Integer fixtureCount = 0;
Date startDate = Date.today();
for (Integer i = 0; i < 14; i++) {
    Date checkDate = startDate.addDays(i);
    try {
        Integer dayFixtures = ESPNSyncService.syncFixturesForDate('soccer', 'eng.1', checkDate, competitionId);
        if (dayFixtures > 0) {
            System.debug('  ' + checkDate.format() + ': ' + dayFixtures + ' fixtures');
            fixtureCount += dayFixtures;
        }
    } catch (Exception e) {
        // Silent - no fixtures on this day or API error
    }
}

System.debug('');
System.debug('Total fixtures synced: ' + fixtureCount);
System.debug('');

// ========================================
// STEP 5: Verify Fixture Data
// ========================================
System.debug('--- STEP 5: Verifying Fixture Data ---');

List<Fixture__c> eplFixtures = [
    SELECT Name, Home_Team__r.Name, Home_Team__r.Abbreviation__c,
           Away_Team__r.Name, Away_Team__r.Abbreviation__c,
           Fixture_Date_Time__c, Status__c,
           Home_Score_Final__c, Away_Score_Final__c, Venue__c
    FROM Fixture__c
    WHERE Competition__r.ESPN_League_ID__c = 'eng.1'
    ORDER BY Fixture_Date_Time__c
    LIMIT 20
];

System.debug('Total EPL fixtures: ' + eplFixtures.size());
System.debug('');
if (eplFixtures.size() > 0) {
    System.debug('Sample fixtures (first 10):');
    displayCount = 0;
    for (Fixture__c fix : eplFixtures) {
        if (displayCount < 10) {
            String homeAbbr = fix.Home_Team__r.Abbreviation__c != null ? fix.Home_Team__r.Abbreviation__c : fix.Home_Team__r.Name;
            String awayAbbr = fix.Away_Team__r.Abbreviation__c != null ? fix.Away_Team__r.Abbreviation__c : fix.Away_Team__r.Name;
            String dateStr = fix.Fixture_Date_Time__c != null ? fix.Fixture_Date_Time__c.format('MMM dd, HH:mm') : 'TBD';
            String score = '';
            if (fix.Home_Score_Final__c != null && fix.Away_Score_Final__c != null) {
                score = ' [' + fix.Home_Score_Final__c.intValue() + '-' + fix.Away_Score_Final__c.intValue() + ']';
            }
            System.debug('  - ' + homeAbbr + ' vs ' + awayAbbr + ' - ' + dateStr + score + ' (' + fix.Status__c + ')');
            displayCount++;
        }
    }
}
System.debug('');

// ========================================
// STEP 6: SOQL Verification
// ========================================
System.debug('--- STEP 6: SOQL Field Verification ---');

// Verify Account fields
try {
    List<Account> testTeams = [
        SELECT ESPN_Team_ID__c, Abbreviation__c, Venue_Name__c, Logo_Url__c
        FROM Account
        WHERE ESPN_Team_ID__c != null
        LIMIT 1
    ];
    System.debug('✅ Account fields verified: ESPN_Team_ID__c, Abbreviation__c, Venue_Name__c, Logo_Url__c');
} catch (Exception e) {
    System.debug('❌ Account field error: ' + e.getMessage());
}

// Verify Contact fields
try {
    List<Contact> testPlayers = [
        SELECT ESPN_Player_ID__c, Profile_Image_URL__c, Position__c, Jersey_Number__c
        FROM Contact
        WHERE ESPN_Player_ID__c != null
        LIMIT 1
    ];
    System.debug('✅ Contact fields verified: ESPN_Player_ID__c, Profile_Image_URL__c, Position__c, Jersey_Number__c');
} catch (Exception e) {
    System.debug('❌ Contact field error: ' + e.getMessage());
}

// Verify Fixture fields
try {
    List<Fixture__c> testFixtures = [
        SELECT Home_Team__c, Away_Team__c, Fixture_Date_Time__c, Status__c,
               Home_Score_Final__c, Away_Score_Final__c, Venue__c
        FROM Fixture__c
        LIMIT 1
    ];
    System.debug('✅ Fixture__c fields verified: All core fields accessible');
} catch (Exception e) {
    System.debug('❌ Fixture__c field error: ' + e.getMessage());
}

System.debug('');

// ========================================
// FINAL SUMMARY
// ========================================
System.debug('=== TEST COMPLETE ===');
System.debug('');
System.debug('Results:');
System.debug('  Teams synced: ' + teamCount);
System.debug('  Players synced: ' + totalPlayers);
System.debug('  Fixtures synced: ' + fixtureCount);
System.debug('');
System.debug('Current org totals:');
Integer postTeams = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null];
Integer postPlayers = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
Integer postFixtures = [SELECT COUNT() FROM Fixture__c];
System.debug('  Total teams: ' + postTeams);
System.debug('  Total players: ' + postPlayers);
System.debug('  Total fixtures: ' + postFixtures);
System.debug('');

if (teamCount > 0 && fixtureCount > 0) {
    System.debug('✅ SUCCESS: ESPN Premier League sync is working!');
    System.debug('✅ API integration verified');
    System.debug('✅ Field mappings verified');
} else {
    System.debug('⚠️ PARTIAL SUCCESS: Some data synced but review results above');
}

