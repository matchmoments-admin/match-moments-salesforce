/**
 * Test script for lineup sync with automatic player creation
 * 
 * This script tests:
 * 1. Lineup sync creates missing players automatically
 * 2. Players are linked correctly to Match_Participation__c records
 * 3. ESPN API fetch for missing players works when sport/league info is available
 * 
 * Usage: Execute in Developer Console > Debug > Open Execute Anonymous Window
 */

// ============================================
// STEP 1: Find a test match with ESPN Event ID
// ============================================
System.debug('=== STEP 1: Finding test match ===');

List<Match__c> testMatches = [
    SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Competition__r.Sport__c, 
           Competition__r.ESPN_League_ID__c, Home_Team__c, Away_Team__c,
           Home_Team__r.Name, Away_Team__r.Name
    FROM Match__c
    WHERE ESPN_Event_ID__c != null
    AND Competition__c != null
    AND Home_Team__c != null
    AND Away_Team__c != null
    LIMIT 1
];

if (testMatches.isEmpty()) {
    System.debug('ERROR: No matches found with ESPN_Event_ID__c. Please create a test match first.');
    return;
}

Match__c testMatch = testMatches[0];
System.debug('Found test match: ' + testMatch.Name + ' (ID: ' + testMatch.Id + ')');
System.debug('ESPN Event ID: ' + testMatch.ESPN_Event_ID__c);
System.debug('Competition: ' + (testMatch.Competition__c != null ? testMatch.Competition__r.Sport__c : 'N/A'));

// ============================================
// STEP 2: Count existing players before sync
// ============================================
System.debug('\n=== STEP 2: Counting existing players ===');

Integer playersBefore = [
    SELECT COUNT()
    FROM Contact
    WHERE AccountId IN (:testMatch.Home_Team__c, :testMatch.Away_Team__c)
];

System.debug('Players before sync: ' + playersBefore);

// ============================================
// STEP 3: Delete existing lineups and participations to test fresh creation
// ============================================
System.debug('\n=== STEP 3: Cleaning up existing lineups ===');

List<Lineup__c> existingLineups = [
    SELECT Id
    FROM Lineup__c
    WHERE Match__c = :testMatch.Id
];

List<Match_Participation__c> existingParticipations = [
    SELECT Id
    FROM Match_Participation__c
    WHERE Match__c = :testMatch.Id
];

if (!existingParticipations.isEmpty()) {
    System.debug('Deleting ' + existingParticipations.size() + ' existing participations');
    delete existingParticipations;
}

if (!existingLineups.isEmpty()) {
    System.debug('Deleting ' + existingLineups.size() + ' existing lineups');
    delete existingLineups;
}

// ============================================
// STEP 4: Sync lineups from ESPN (this should create missing players)
// ============================================
System.debug('\n=== STEP 4: Syncing lineups from ESPN ===');

try {
    // Use ESPNSyncServiceImpl directly (avoids AuraHandledException in anonymous Apex)
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    ESPNSyncServiceImpl service = new ESPNSyncServiceImpl();
    ESPNSyncResult result = service.syncMatchLineups(testMatch.Id, uow);
    
    if (result.success) {
        System.debug('SUCCESS: Lineup sync completed');
        System.debug('Result message: ' + result.message);
        
        // Commit the unit of work
        uow.commitWork();
        System.debug('✓ Unit of work committed successfully');
    } else {
        System.debug('ERROR: Sync failed - ' + result.message);
        return;
    }
} catch (Exception e) {
    System.debug('ERROR: Exception during sync - ' + e.getMessage());
    System.debug('Exception type: ' + e.getTypeName());
    System.debug('Stack trace: ' + e.getStackTraceString());
    return;
}

// ============================================
// STEP 5: Verify players were created
// ============================================
System.debug('\n=== STEP 5: Verifying players were created ===');

Integer playersAfter = [
    SELECT COUNT()
    FROM Contact
    WHERE AccountId IN (:testMatch.Home_Team__c, :testMatch.Away_Team__c)
];

Integer newPlayers = playersAfter - playersBefore;
System.debug('Players after sync: ' + playersAfter);
System.debug('New players created: ' + newPlayers);

if (newPlayers > 0) {
    System.debug('✓ SUCCESS: ' + newPlayers + ' new player(s) were created');
} else {
    System.debug('INFO: No new players created (may already exist)');
}

// ============================================
// STEP 6: Verify lineups were created
// ============================================
System.debug('\n=== STEP 6: Verifying lineups were created ===');

// Query lineups - use basic fields that should exist
List<Lineup__c> createdLineups = new List<Lineup__c>();
try {
    createdLineups = [
        SELECT Id
        FROM Lineup__c
        WHERE Match__c = :testMatch.Id
    ];
} catch (Exception e) {
    System.debug('ERROR: Could not query Lineup__c: ' + e.getMessage());
    System.debug('This may indicate the Lineup__c object or Match__c relationship is not deployed');
}

System.debug('Lineups created: ' + createdLineups.size());
for (Lineup__c lineup : createdLineups) {
    System.debug('  - Lineup ID: ' + lineup.Id);
}

// ============================================
// STEP 7: Verify Match_Participation__c records
// ============================================
System.debug('\n=== STEP 7: Verifying Match_Participation__c records ===');

List<Match_Participation__c> participations = [
    SELECT Id, Player__c, Player__r.Name, Team__c, Team__r.Name, 
           Position__c, Starting_Lineup__c, Substitute__c, Person__c
    FROM Match_Participation__c
    WHERE Match__c = :testMatch.Id
    ORDER BY Team__r.Name, Starting_Lineup__c DESC, Position__c
];

System.debug('Participations created: ' + participations.size());

// Group by team
Map<Id, List<Match_Participation__c>> participationsByTeam = new Map<Id, List<Match_Participation__c>>();
for (Match_Participation__c p : participations) {
    if (!participationsByTeam.containsKey(p.Team__c)) {
        participationsByTeam.put(p.Team__c, new List<Match_Participation__c>());
    }
    participationsByTeam.get(p.Team__c).add(p);
}

for (Id teamId : participationsByTeam.keySet()) {
    List<Match_Participation__c> teamParticipations = participationsByTeam.get(teamId);
    System.debug('  Team: ' + teamParticipations[0].Team__r.Name + ' (' + teamParticipations.size() + ' players)');
    
    Integer starters = 0;
    Integer substitutes = 0;
    Integer missingPerson = 0;
    
    for (Match_Participation__c p : teamParticipations) {
        if (p.Starting_Lineup__c) starters++;
        if (p.Substitute__c) substitutes++;
        if (p.Person__c == null) missingPerson++;
    }
    
    System.debug('    - Starters: ' + starters);
    System.debug('    - Substitutes: ' + substitutes);
    if (missingPerson > 0) {
        System.debug('    - ⚠ WARNING: ' + missingPerson + ' participation(s) missing Person__c');
    } else {
        System.debug('    - ✓ All participations have Person__c set');
    }
}

// ============================================
// STEP 8: Verify player data quality
// ============================================
System.debug('\n=== STEP 8: Verifying player data quality ===');

List<Contact> playersInLineup = [
    SELECT Id, Name, FirstName, LastName, ESPN_Player_ID__c, 
           Position__c, Jersey_Number__c, AccountId, Account.Name
    FROM Contact
    WHERE Id IN (SELECT Player__c FROM Match_Participation__c WHERE Match__c = :testMatch.Id)
    ORDER BY Account.Name, Jersey_Number__c NULLS LAST
];

System.debug('Players in lineup: ' + playersInLineup.size());

Integer playersWithESPNId = 0;
Integer playersWithPosition = 0;
Integer playersWithJersey = 0;
Integer playersMissingName = 0;

for (Contact player : playersInLineup) {
    if (String.isNotBlank(player.ESPN_Player_ID__c)) playersWithESPNId++;
    if (String.isNotBlank(player.Position__c)) playersWithPosition++;
    if (player.Jersey_Number__c != null) playersWithJersey++;
    if (String.isBlank(player.LastName)) playersMissingName++;
}

System.debug('  - Players with ESPN_Player_ID__c: ' + playersWithESPNId + '/' + playersInLineup.size());
System.debug('  - Players with Position__c: ' + playersWithPosition + '/' + playersInLineup.size());
System.debug('  - Players with Jersey_Number__c: ' + playersWithJersey + '/' + playersInLineup.size());
if (playersMissingName > 0) {
    System.debug('  - ⚠ WARNING: ' + playersMissingName + ' player(s) missing LastName');
} else {
    System.debug('  - ✓ All players have LastName');
}

// ============================================
// STEP 9: Final summary
// ============================================
System.debug('\n=== STEP 9: Final Summary ===');
System.debug('Match: ' + testMatch.Name + ' (ID: ' + testMatch.Id + ')');
System.debug('ESPN Event ID: ' + testMatch.ESPN_Event_ID__c);
System.debug('Lineups found: ' + createdLineups.size());
System.debug('Participations found: ' + participations.size());
System.debug('Players in lineup: ' + playersInLineup.size());
System.debug('New players created: ' + newPlayers);
System.debug('\n✓ TEST COMPLETE - Check results above');
System.debug('\nNext steps:');
System.debug('1. Verify lineups were created in Salesforce UI');
System.debug('2. Check Match_Participation__c records are linked correctly');
System.debug('3. Verify all players have Person__c set on participations');

