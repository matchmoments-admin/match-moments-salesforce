/**
 * ESPN Sync Scheduler - Men's Premier League Test Script
 * 
 * This script will:
 * 1. Start the OrgSchedulable scheduler
 * 2. Create a test job for Men's Premier League (2025-26 season)
 * 3. Execute immediately to sync teams, players, and fixtures
 * 4. Show you the results
 * 
 * EXECUTE THIS ENTIRE FILE IN ANONYMOUS APEX
 */

System.debug('=== ESPN Sync Scheduler - Men\'s Premier League Test (2025-26) ===');
System.debug('Starting at: ' + Datetime.now());

// ========================================
// STEP 1: Start the Scheduler
// ========================================
System.debug('\n--- Step 1: Starting OrgSchedulable ---');

// First, stop any existing schedulers
try {
    OrgSchedulable.stopScheduler();
    System.debug('Stopped existing schedulers');
} catch (Exception e) {
    System.debug('No existing schedulers to stop');
}

// Start the scheduler (creates 60 scheduled jobs, one per minute)
OrgSchedulable.startScheduler();

// Verify it's running
Integer schedulerCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'OrgSchedulable-%'];
System.debug('✓ Scheduler started successfully! Running ' + schedulerCount + ' scheduled jobs');

// ========================================
// STEP 2: Check for Existing Premier League Data
// ========================================
System.debug('\n--- Step 2: Pre-Test State ---');

// Check if Premier League competition exists
List<Competition__c> eplComps = [
    SELECT Id, Name, ESPN_League_ID__c 
    FROM Competition__c 
    WHERE ESPN_League_ID__c = 'eng.1' 
    LIMIT 1
];

Id eplCompetitionId = null;
if (!eplComps.isEmpty()) {
    eplCompetitionId = eplComps[0].Id;
    System.debug('Found Premier League Competition: ' + eplComps[0].Name + ' (' + eplComps[0].Id + ')');
} else {
    System.debug('No Premier League Competition found - will create one during sync');
}

// Count existing Premier League data
Integer existingTeams = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null AND Sport__c = 'Soccer'];
Integer existingPlayers = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
Integer existingFixtures = [SELECT COUNT() FROM Fixture__c WHERE Competition__r.ESPN_League_ID__c = 'eng.1'];

System.debug('Current Premier League Data:');
System.debug('  - Teams: ' + existingTeams);
System.debug('  - Players: ' + existingPlayers);
System.debug('  - Fixtures: ' + existingFixtures);

// ========================================
// STEP 3: Create Premier League Test Job
// ========================================
System.debug('\n--- Step 3: Creating Premier League Test Job ---');

// Delete any existing Premier League test jobs to avoid duplicates
delete [SELECT Id FROM Scheduled_Process__c WHERE League_Code__c = 'eng.1' AND ClassName__c = 'ESPNSyncQueueable'];

// Create test job for Men's Premier League
Scheduled_Process__c eplJob = new Scheduled_Process__c(
    ClassName__c = 'ESPNSyncQueueable',
    Type__c = 'Queueable Job',
    IsActive__c = true,
    Frequency__c = 60, // Run every 60 minutes
    Units__c = 'Minutes',
    Sport_Type__c = 'soccer',
    League_Code__c = 'eng.1',  // Men's Premier League
    Competition__c = eplCompetitionId,
    Sync_Teams__c = true,       // Sync all 20 Premier League teams
    Sync_Rosters__c = true,     // Sync player rosters for all teams
    Sync_Fixtures__c = true,    // Sync upcoming fixtures
    Sync_Stats__c = false,      // Skip stats for now (can enable later)
    Fixture_Date_Range_Days__c = 14,  // Next 14 days of fixtures
    Max_API_Calls_Per_Run__c = 100,   // Allow more API calls for full roster sync
    NextRunTime__c = Datetime.now().addMinutes(1),
    BatchSize__c = null
);

insert eplJob;

System.debug('✓ Created Premier League Test Job:');
System.debug('  - ID: ' + eplJob.Id);
System.debug('  - League: Premier League (eng.1)');
System.debug('  - Season: 2025-26');
System.debug('  - Sync Teams: YES (expecting ~20 teams)');
System.debug('  - Sync Rosters: YES (expecting ~500+ players)');
System.debug('  - Sync Fixtures: YES (next 14 days)');

// ========================================
// STEP 4: Execute Immediately
// ========================================
System.debug('\n--- Step 4: Executing Test Job Now ---');

Long startTime = System.currentTimeMillis();

try {
    // Execute the queueable job immediately
    System.enqueueJob(new ESPNSyncQueueable(eplJob.Id));
    System.debug('✓ Job enqueued successfully!');
    System.debug('');
    System.debug('⏳ Job is running asynchronously...');
    System.debug('');
    System.debug('WAIT 30-60 SECONDS, then check results below.');
} catch (Exception e) {
    System.debug('❌ ERROR enqueuing job: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// ========================================
// STEP 5: Monitoring Instructions
// ========================================
System.debug('\n--- Step 5: How to Check Results ---');
System.debug('');
System.debug('⏰ WAIT 30-60 SECONDS (rosters take time), then run:');
System.debug('');
System.debug('// Check job status');
System.debug('Scheduled_Process__c job = [');
System.debug('    SELECT Name, Last_Sync_Status__c, Last_Sync_Records_Processed__c,');
System.debug('           Last_Sync_Errors__c, Last_Sync_Duration_Seconds__c, LastRunTime__c');
System.debug('    FROM Scheduled_Process__c');
System.debug('    WHERE Id = \'' + eplJob.Id + '\'');
System.debug('];');
System.debug('System.debug(\'Status: \' + job.Last_Sync_Status__c);');
System.debug('System.debug(\'Records: \' + job.Last_Sync_Records_Processed__c);');
System.debug('System.debug(\'Duration: \' + job.Last_Sync_Duration_Seconds__c + \' sec\');');
System.debug('System.debug(\'Errors: \' + job.Last_Sync_Errors__c);');
System.debug('');
System.debug('// Check teams synced');
System.debug('List<Account> teams = [SELECT Name, ESPN_Team_ID__c FROM Account WHERE ESPN_Team_ID__c != null ORDER BY Name];');
System.debug('System.debug(\'Total Teams: \' + teams.size());');
System.debug('for (Account t : teams) { System.debug(t.Name); }');
System.debug('');
System.debug('// Check players synced');
System.debug('System.debug(\'Total Players: \' + [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null]);');
System.debug('');
System.debug('// Check fixtures synced');
System.debug('List<Fixture__c> fixtures = [SELECT Name, Home_Team__r.Name, Away_Team__r.Name, Fixture_Date_Time__c FROM Fixture__c WHERE Competition__r.ESPN_League_ID__c = \'eng.1\' ORDER BY Fixture_Date_Time__c];');
System.debug('System.debug(\'Total Fixtures: \' + fixtures.size());');
System.debug('for (Fixture__c f : fixtures) { System.debug(f.Home_Team__r.Name + \' vs \' + f.Away_Team__r.Name + \' - \' + f.Fixture_Date_Time__c); }');
System.debug('');

// ========================================
// Summary
// ========================================
System.debug('\n=== TEST SETUP COMPLETE ===');
System.debug('');
System.debug('✅ Scheduler is running');
System.debug('✅ Premier League Test Job created');
System.debug('✅ Job execution started');
System.debug('');
System.debug('📊 Expected Results (2025-26 Season):');
System.debug('   - ~20 Premier League teams');
System.debug('   - ~500+ players (25-30 per team)');
System.debug('   - Upcoming fixtures for next 14 days');
System.debug('   - Competition record created if needed');
System.debug('   - Job status will update to "Success"');
System.debug('');
System.debug('⏳ Wait 30-60 seconds, then check the results!');
System.debug('');
System.debug('Notable Teams to Look For:');
System.debug('   - Manchester City');
System.debug('   - Arsenal FC');
System.debug('   - Liverpool FC');
System.debug('   - Manchester United');
System.debug('   - Chelsea FC');
System.debug('   - Tottenham Hotspur');
System.debug('   - Newcastle United');
System.debug('   - Aston Villa');
System.debug('   - And 12 more...');
System.debug('');


