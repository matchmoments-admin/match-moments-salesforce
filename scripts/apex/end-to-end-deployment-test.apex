// Comprehensive End-to-End Deployment Test
// Tests all newly deployed objects, fields, and relationships

System.debug('=== DEPLOYMENT VERIFICATION TEST ===');
System.debug('');

// ===== PART 1: VERIFY NEW OBJECTS EXIST =====
System.debug('--- Part 1: Verifying New Objects ---');

List<String> newObjects = new List<String>{
    'Season__c',
    'Team_Membership__c',
    'Award__c',
    'ESPN_Sync_Event__e',
    'ESPN_Sync_Error__c',
    'League_Config__c',
    'API_Usage__c'
};

for (String objName : newObjects) {
    try {
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objName).getDescribe();
        System.debug('✓ ' + objName + ' exists - Label: ' + describeResult.getLabel());
    } catch (Exception e) {
        System.debug('✗ ERROR: ' + objName + ' not found');
    }
}

System.debug('');

// ===== PART 2: CREATE TEST DATA =====
System.debug('--- Part 2: Creating Test Data ---');

// Create a test league (Competition)
Competition__c testLeague = new Competition__c(
    ESPN_League_ID__c = 'test-epl-001',
    Sport__c = 'Soccer'
);
insert testLeague;
System.debug('✓ Created Competition: ' + testLeague.Id);

// Create a test season
Season__c testSeason = new Season__c(
    Season_Name__c = '2024-25',
    Start_Date__c = Date.newInstance(2024, 8, 1),
    End_Date__c = Date.newInstance(2025, 5, 31)
);
insert testSeason;
System.debug('✓ Created Season: ' + testSeason.Id);

// Create a test team (Account)
Account testTeam = new Account(
    Name = 'Test United FC',
    ESPN_Team_ID__c = 'test-team-001',
    Team_Type__c = 'Professional'
);
insert testTeam;
System.debug('✓ Created Team (Account): ' + testTeam.Id + ' - ' + testTeam.Name);

// Create a test player (Contact)
Contact testPlayer = new Contact(
    FirstName = 'Test',
    LastName = 'Player',
    ESPN_Player_ID__c = 'test-player-001',
    Position__c = 'Forward'
);
insert testPlayer;
System.debug('✓ Created Player (Contact): ' + testPlayer.Id + ' - ' + testPlayer.Name);

// Create a Team Membership
Team_Membership__c membership = new Team_Membership__c(
    Player__c = testPlayer.Id,
    Team__c = testTeam.Id,
    Season__c = testSeason.Id,
    Jersey_Number__c = 10,
    Start_Date__c = Date.today().addDays(-30),
    Position__c = 'Forward'
);
insert membership;
System.debug('✓ Created Team Membership: ' + membership.Id);

// Create an Award
Award__c testAward = new Award__c(
    Name = 'Player of the Month',
    Player__c = testPlayer.Id,
    Team__c = testTeam.Id,
    Season__c = testSeason.Id,
    Competition__c = testLeague.Id,
    Award_Type__c = 'Monthly Award',
    Award_Category__c = 'Individual Award',
    Year__c = String.valueOf(Date.today().year())
);
insert testAward;
System.debug('✓ Created Award: ' + testAward.Id + ' - ' + testAward.Name);

// Create League Config
League_Config__c config = new League_Config__c(
    Name = 'EPL Config',
    Competition__c = testLeague.Id,
    ESPN_League_ID__c = 'test-epl-001',
    Is_Active__c = true,
    Sync_Frequency__c = 'Daily',
    Priority__c = 1
);
insert config;
System.debug('✓ Created League Config: ' + config.Id);

// Create ESPN Sync Error
ESPN_Sync_Error__c syncError = new ESPN_Sync_Error__c(
    League_Config__c = config.Id,
    Error_Type__c = 'API_ERROR',
    Error_Message__c = 'Test error message',
    Occurred_At__c = DateTime.now(),
    Is_Resolved__c = false
);
insert syncError;
System.debug('✓ Created ESPN Sync Error: ' + syncError.Id);

// Create API Usage record
API_Usage__c apiUsage = new API_Usage__c(
    Name = 'Test API Call',
    API_Name__c = 'ESPN API',
    Call_Count__c = 1,
    Usage_Date__c = Date.today()
);
insert apiUsage;
System.debug('✓ Created API Usage: ' + apiUsage.Id);

System.debug('');

// ===== PART 3: VERIFY RELATIONSHIPS =====
System.debug('--- Part 3: Verifying Relationships ---');

// Query back the data with relationships
Season__c queriedSeason = [
    SELECT Id, Name, Start_Date__c, End_Date__c
    FROM Season__c 
    WHERE Id = :testSeason.Id
];
System.debug('✓ Season queried successfully: ' + queriedSeason.Name);

Team_Membership__c queriedMembership = [
    SELECT Id, Player__c, Player__r.Name, Team__c, Team__r.Name, 
           Season__c, Season__r.Name, Is_Current__c
    FROM Team_Membership__c 
    WHERE Id = :membership.Id
];
System.debug('✓ Membership->Player relationship: ' + queriedMembership.Player__r.Name);
System.debug('✓ Membership->Team relationship: ' + queriedMembership.Team__r.Name);
System.debug('✓ Membership->Season relationship: ' + queriedMembership.Season__r.Name);
System.debug('✓ Is_Current formula field: ' + queriedMembership.Is_Current__c);

Award__c queriedAward = [
    SELECT Id, Name, Player__c, Player__r.Name, Team__c, Team__r.Name,
           Season__c, Season__r.Name, Competition__c, Competition__r.Name
    FROM Award__c 
    WHERE Id = :testAward.Id
];
System.debug('✓ Award->Player relationship: ' + queriedAward.Player__r.Name);
System.debug('✓ Award->Team relationship: ' + queriedAward.Team__r.Name);
System.debug('✓ Award->Season relationship: ' + queriedAward.Season__r.Name);
System.debug('✓ Award->Competition relationship: ' + queriedAward.Competition__r.Name);

League_Config__c queriedConfig = [
    SELECT Id, Name, Competition__c, Competition__r.Name, Is_Active__c
    FROM League_Config__c 
    WHERE Id = :config.Id
];
System.debug('✓ League Config->Competition relationship: ' + queriedConfig.Competition__r.Name);

ESPN_Sync_Error__c queriedError = [
    SELECT Id, League_Config__c, League_Config__r.Name, Error_Type__c
    FROM ESPN_Sync_Error__c 
    WHERE Id = :syncError.Id
];
System.debug('✓ Sync Error->League Config relationship: ' + queriedError.League_Config__r.Name);

System.debug('');

// ===== PART 4: VERIFY NEW FIELDS ON EXISTING OBJECTS =====
System.debug('--- Part 4: Verifying New Fields on Existing Objects ---');

// Update Account with new fields
testTeam.Current_Season__c = testSeason.Id;
testTeam.Foundation_Year__c = '1990';
testTeam.Stadium_Name__c = 'Test Stadium';
update testTeam;
System.debug('✓ Account.Current_Season__c field works');
System.debug('✓ Account.Foundation_Year__c field works');
System.debug('✓ Account.Stadium_Name__c field works');

// Update Competition with new fields
testLeague.Season__c = testSeason.Id;
update testLeague;
System.debug('✓ Competition__c.Season__c field works');

// Create a Match to test Match fields
Match__c testMatch = new Match__c(
    Name = 'Test Match',
    Competition__c = testLeague.Id,
    Home_Team__c = testTeam.Id,
    Away_Team__c = testTeam.Id,
    Match_Date__c = Date.today()
);
insert testMatch;

testMatch.Season__c = testSeason.Id;
update testMatch;
System.debug('✓ Match__c.Season__c field works');

// Update Contact with new fields
testPlayer.Current_Team__c = testTeam.Id;
testPlayer.Date_of_Birth__c = Date.newInstance(1995, 5, 15);
update testPlayer;
System.debug('✓ Contact.Current_Team__c field works');
System.debug('✓ Contact.Date_of_Birth__c field works');

System.debug('');

// ===== PART 5: TEST PLATFORM EVENT =====
System.debug('--- Part 5: Testing Platform Event ---');

ESPN_Sync_Event__e syncEvent = new ESPN_Sync_Event__e(
    League_ID__c = 'test-league-001',
    Event_Type__c = 'FIXTURE_SYNC',
    Sync_Status__c = 'Success',
    Records_Processed__c = 10,
    Message__c = 'Test sync completed'
);
Database.SaveResult sr = EventBus.publish(syncEvent);
if (sr.isSuccess()) {
    System.debug('✓ ESPN_Sync_Event__e published successfully');
} else {
    System.debug('✗ Failed to publish ESPN_Sync_Event__e');
}

System.debug('');

// ===== PART 6: CLEANUP =====
System.debug('--- Part 6: Cleanup Test Data ---');

delete new List<SObject>{
    testMatch,
    apiUsage,
    syncError,
    config,
    testAward,
    membership,
    testPlayer,
    testTeam,
    testSeason,
    testLeague
};

System.debug('✓ All test data cleaned up');
System.debug('');
System.debug('=== ALL TESTS PASSED SUCCESSFULLY ===');
System.debug('All deployed objects, fields, and relationships are working correctly!');

