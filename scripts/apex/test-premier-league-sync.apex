/**
 * ESPN Sync Scheduler - Premier League Test Script
 * 
 * This script will:
 * 1. Start the OrgSchedulable scheduler
 * 2. Create a test job for WSL (Women's Super League)
 * 3. Schedule it to run in 2 minutes
 * 4. Show you how to monitor the results
 * 
 * EXECUTE THIS ENTIRE FILE IN ANONYMOUS APEX
 */

System.debug('=== ESPN Sync Scheduler - Premier League Test ===');
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
// STEP 2: Create WSL Test Job
// ========================================
System.debug('\n--- Step 2: Creating WSL Test Job ---');

// Calculate next run time (2 minutes from now)
Datetime nextRun = Datetime.now().addMinutes(2);
System.debug('Job will run at: ' + nextRun);

// Check if WSL competition exists
List<Competition__c> wslComps = [
    SELECT Id, Name, ESPN_League_ID__c 
    FROM Competition__c 
    WHERE ESPN_League_ID__c = 'eng.wsl' 
    LIMIT 1
];

Id wslCompetitionId = null;
if (!wslComps.isEmpty()) {
    wslCompetitionId = wslComps[0].Id;
    System.debug('Found WSL Competition: ' + wslComps[0].Name + ' (' + wslComps[0].Id + ')');
} else {
    System.debug('No WSL Competition found - will create one during sync');
}

// Delete any existing test jobs to avoid duplicates
delete [SELECT Id FROM Scheduled_Process__c WHERE League_Code__c = 'eng.wsl' AND ClassName__c = 'ESPNSyncQueueable'];

// Create test job for WSL
Scheduled_Process__c testJob = new Scheduled_Process__c(
    ClassName__c = 'ESPNSyncQueueable',
    Type__c = 'Queueable Job',
    IsActive__c = true, // ACTIVE - will run in 2 minutes
    Frequency__c = 15, // Run every 15 minutes (for testing)
    Units__c = 'Minutes',
    Sport_Type__c = 'soccer',
    League_Code__c = 'eng.wsl',
    Competition__c = wslCompetitionId,
    Sync_Teams__c = true,  // Sync WSL teams
    Sync_Rosters__c = false, // Skip rosters for faster test
    Sync_Fixtures__c = true,  // Sync fixtures
    Sync_Stats__c = false,
    Fixture_Date_Range_Days__c = 7, // Next 7 days of fixtures
    Max_API_Calls_Per_Run__c = 30,
    NextRunTime__c = nextRun,
    BatchSize__c = null
);

insert testJob;

System.debug('✓ Created WSL Test Job:');
System.debug('  - ID: ' + testJob.Id);
System.debug('  - Class: ' + testJob.ClassName__c);
System.debug('  - League: ' + testJob.League_Code__c);
System.debug('  - Active: ' + testJob.IsActive__c);
System.debug('  - Next Run: ' + testJob.NextRunTime__c);
System.debug('  - Sync Teams: ' + testJob.Sync_Teams__c);
System.debug('  - Sync Fixtures: ' + testJob.Sync_Fixtures__c);

// ========================================
// STEP 3: Verification Queries
// ========================================
System.debug('\n--- Step 3: Pre-Test State ---');

// Count existing WSL data
Integer existingTeams = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null AND Sport__c = 'Soccer'];
Integer existingPlayers = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
Integer existingFixtures = [SELECT COUNT() FROM Fixture__c WHERE Competition__r.ESPN_League_ID__c = 'eng.wsl'];

System.debug('Current WSL Data:');
System.debug('  - Teams: ' + existingTeams);
System.debug('  - Players: ' + existingPlayers);
System.debug('  - Fixtures: ' + existingFixtures);

// ========================================
// STEP 4: Monitoring Instructions
// ========================================
System.debug('\n--- Step 4: How to Monitor ---');
System.debug('');
System.debug('⏰ WAIT 2-3 MINUTES, then run this query:');
System.debug('');
System.debug('// Check if job ran');
System.debug('Scheduled_Process__c job = [');
System.debug('    SELECT Name, Last_Sync_Status__c, Last_Sync_Records_Processed__c,');
System.debug('           Last_Sync_Errors__c, Last_Sync_Duration_Seconds__c, LastRunTime__c');
System.debug('    FROM Scheduled_Process__c');
System.debug('    WHERE Id = \'' + testJob.Id + '\'');
System.debug('];');
System.debug('System.debug(\'Status: \' + job.Last_Sync_Status__c);');
System.debug('System.debug(\'Records: \' + job.Last_Sync_Records_Processed__c);');
System.debug('System.debug(\'Duration: \' + job.Last_Sync_Duration_Seconds__c + \' sec\');');
System.debug('System.debug(\'Errors: \' + job.Last_Sync_Errors__c);');
System.debug('');
System.debug('// Check teams synced');
System.debug('System.debug([SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null]);');
System.debug('');
System.debug('// Check fixtures synced');
System.debug('System.debug([SELECT COUNT() FROM Fixture__c WHERE Competition__r.ESPN_League_ID__c = \'eng.wsl\']);');
System.debug('');

// ========================================
// STEP 5: Optional Manual Test
// ========================================
System.debug('\n--- Step 5: Optional - Manual Test Now ---');
System.debug('');
System.debug('If you want to test immediately (don\'t wait 2 minutes):');
System.debug('');
System.debug('System.enqueueJob(new ESPNSyncQueueable(\'' + testJob.Id + '\'));');
System.debug('');

// ========================================
// Summary
// ========================================
System.debug('\n=== TEST SETUP COMPLETE ===');
System.debug('');
System.debug('✅ Scheduler is running (60 jobs checking every minute)');
System.debug('✅ WSL Test Job created and ACTIVE');
System.debug('✅ Job will run automatically at: ' + nextRun.format('HH:mm:ss'));
System.debug('');
System.debug('📊 Expected Results:');
System.debug('   - ~12-14 WSL teams will be synced');
System.debug('   - Fixtures for next 7 days will be synced');
System.debug('   - Competition record will be created if needed');
System.debug('   - Job status will update to "Success"');
System.debug('');
System.debug('⏳ Wait 2-3 minutes, then check the job status!');
System.debug('');




