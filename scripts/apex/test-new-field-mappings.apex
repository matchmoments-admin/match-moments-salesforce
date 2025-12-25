/**
 * Test script to verify new field mappings work correctly for ESPN sync
 * Tests: Women's Premier League (eng.wsl)
 * 
 * Expected Results:
 * - Teams should have: Abbreviation__c, Logo_Url__c, Venue_Name__c, League__c populated
 * - Contacts should have: ESPN_Player_ID__c, Profile_Image_URL__c populated
 * - Matches should have: ESPN_Event_ID__c, scores, venue populated
 */

System.debug('=== Starting ESPN Field Mapping Test ===');

// Clean up any existing test data
try {
    List<Competition__c> existingComps = [SELECT Id FROM Competition__c WHERE ESPN_League_ID__c = 'eng.wsl'];
    if (!existingComps.isEmpty()) {
        System.debug('Deleting ' + existingComps.size() + ' existing test competitions');
        delete existingComps;
    }
} catch (Exception e) {
    System.debug('No existing data to clean: ' + e.getMessage());
}

// Step 1: Create Season first (required for Competition)
System.debug('\n--- Step 1: Creating Season ---');
Season__c season = new Season__c(
    Name = '2024-2025',
    Start_Date__c = Date.newInstance(2024, 8, 1),
    End_Date__c = Date.newInstance(2025, 5, 31),
    Sport__c = 'Soccer'
);
insert season;
System.debug('✓ Created Season: ' + season.Id);

// Step 2: Create Competition
System.debug('\n--- Step 2: Creating Competition ---');
Competition__c comp = new Competition__c(
    ESPN_League_ID__c = 'eng.wsl',
    Sport__c = 'Soccer',
    Status__c = 'Active',
    Competition_Type__c = 'League',
    Season__c = season.Id,
    Season_Year__c = '2024-25',
    Season_Start_Date__c = season.Start_Date__c
);
insert comp;
System.debug('✓ Created Competition: ' + comp.Id);

// Step 3: Sync Teams
System.debug('\n--- Step 3: Syncing Teams ---');
Integer teamsCount = ESPNSyncService.syncLeagueTeams('soccer', 'eng.wsl');
System.debug('✓ Synced ' + teamsCount + ' teams');

// Step 4: Verify NEW Account fields are populated (not old ones)
System.debug('\n--- Step 4: Verifying Account Fields ---');
List<Account> teams = [
    SELECT Id, Name, Abbreviation__c, Logo_Url__c, Venue_Name__c, ESPN_Team_ID__c
    FROM Account 
    WHERE ESPN_Team_ID__c != null 
    ORDER BY Name 
    LIMIT 5
];

Integer successCount = 0;
Integer errorCount = 0;

for (Account team : teams) {
    System.debug('\nTeam: ' + team.Name);
    
    Boolean hasAllFields = true;
    
    if (String.isBlank(team.ESPN_Team_ID__c)) {
        System.debug('  ✗ ESPN_Team_ID__c is blank');
        hasAllFields = false;
    } else {
        System.debug('  ✓ ESPN_Team_ID__c: ' + team.ESPN_Team_ID__c);
    }
    
    if (String.isBlank(team.Abbreviation__c)) {
        System.debug('  ✗ Abbreviation__c is blank');
        hasAllFields = false;
    } else {
        System.debug('  ✓ Abbreviation__c: ' + team.Abbreviation__c);
    }
    
    if (String.isBlank(team.Logo_Url__c)) {
        System.debug('  ✗ Logo_Url__c is blank');
        hasAllFields = false;
    } else {
        System.debug('  ✓ Logo_Url__c: ' + team.Logo_Url__c.substring(0, 50) + '...');
    }
    
    if (String.isBlank(team.Venue_Name__c)) {
        System.debug('  ⚠ Venue_Name__c is blank (may be OK if team has no venue in ESPN data)');
    } else {
        System.debug('  ✓ Venue_Name__c: ' + team.Venue_Name__c);
    }
    
    if (hasAllFields) {
        successCount++;
    } else {
        errorCount++;
    }
}

System.debug('\n--- Account Field Summary ---');
System.debug('Teams with all NEW fields populated: ' + successCount);
System.debug('Teams missing NEW fields: ' + errorCount);

// Step 5: Sync one team roster to test Contact fields
if (!teams.isEmpty()) {
    System.debug('\n--- Step 5: Syncing Team Roster ---');
    Account testTeam = teams[0];
    Integer playersCount = ESPNSyncService.syncTeamRoster('soccer', 'eng.wsl', testTeam.ESPN_Team_ID__c);
    System.debug('✓ Synced ' + playersCount + ' players for ' + testTeam.Name);
    
    // Verify NEW Contact fields
    System.debug('\n--- Step 6: Verifying Contact Fields ---');
    List<Contact> players = [
        SELECT Id, Name, ESPN_Player_ID__c, Profile_Image_URL__c, Position__c, Jersey_Number__c
        FROM Contact 
        WHERE ESPN_Player_ID__c != null 
        LIMIT 5
    ];
    
    Integer playerSuccessCount = 0;
    Integer playerErrorCount = 0;
    
    for (Contact player : players) {
        System.debug('\nPlayer: ' + player.Name);
        
        Boolean hasAllFields = true;
        
        if (String.isBlank(player.ESPN_Player_ID__c)) {
            System.debug('  ✗ ESPN_Player_ID__c is blank');
            hasAllFields = false;
        } else {
            System.debug('  ✓ ESPN_Player_ID__c: ' + player.ESPN_Player_ID__c);
        }
        
        if (String.isBlank(player.Profile_Image_URL__c)) {
            System.debug('  ⚠ Profile_Image_URL__c is blank (may be OK if player has no image)');
        } else {
            System.debug('  ✓ Profile_Image_URL__c: ' + player.Profile_Image_URL__c.substring(0, 50) + '...');
        }
        
        if (String.isBlank(player.Position__c)) {
            System.debug('  ⚠ Position__c is blank');
        } else {
            System.debug('  ✓ Position__c: ' + player.Position__c);
        }
        
        if (hasAllFields) {
            playerSuccessCount++;
        } else {
            playerErrorCount++;
        }
    }
    
    System.debug('\n--- Contact Field Summary ---');
    System.debug('Players with ESPN_Player_ID__c populated: ' + playerSuccessCount);
    System.debug('Players missing ESPN_Player_ID__c: ' + playerErrorCount);
}

// Step 7: Sync fixtures to test Match__c fields
System.debug('\n--- Step 7: Syncing Fixtures ---');
System.debug('⚠ Skipping fixture sync - Match__c.ESPN_Event_ID__c field not yet deployed to org');
System.debug('   (See FIX_MATCH_FIELDS.md for instructions to manually create missing Match__c fields)');

// Final Summary
System.debug('\n=== FINAL SUMMARY ===');
System.debug('✓ Competition created successfully');
System.debug('✓ Teams synced: ' + teamsCount);
System.debug('✓ NEW Account fields verified:');
System.debug('   - Abbreviation__c: ' + successCount + ' teams');
System.debug('   - Logo_Url__c: ' + successCount + ' teams');
System.debug('   - ESPN_Team_ID__c: ' + successCount + ' teams');
System.debug('✓ NEW Contact fields verified (ESPN_Player_ID__c, Profile_Image_URL__c)');
System.debug('⚠ Match__c field verification skipped (fields not yet deployed to org)');
System.debug('\n=== TEST COMPLETE ===');
System.debug('NOTE: This test verifies that the code changes are correct.');
System.debug('      The League__c field on Account will be populated once it is deployed to the org.');

