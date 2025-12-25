/**
 * ESPN Sync Scheduler - Monitoring Script
 * 
 * Run this AFTER the test job has executed (2-3 minutes after setup)
 * This will show you the results and verify everything worked
 * 
 * COPY AND PASTE THIS INTO ANONYMOUS APEX
 */

System.debug('=== ESPN Sync Scheduler - Results Check ===');
System.debug('Checking at: ' + Datetime.now());
System.debug('');

// ========================================
// Find the Test Job
// ========================================
List<Scheduled_Process__c> testJobs = [
    SELECT Id, Name, ClassName__c, League_Code__c, IsActive__c,
           LastRunTime__c, NextRunTime__c,
           Last_Sync_Status__c, Last_Sync_Records_Processed__c,
           Last_Sync_Errors__c, Last_Sync_Duration_Seconds__c,
           Sync_Teams__c, Sync_Rosters__c, Sync_Fixtures__c
    FROM Scheduled_Process__c
    WHERE League_Code__c = 'eng.wsl'
    AND ClassName__c = 'ESPNSyncQueueable'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (testJobs.isEmpty()) {
    System.debug('❌ No test job found! Did you run the setup script?');
} else {
    Scheduled_Process__c job = testJobs[0];
    
    System.debug('--- Job Configuration ---');
    System.debug('Job ID: ' + job.Id);
    System.debug('Job Name: ' + job.Name);
    System.debug('League: ' + job.League_Code__c);
    System.debug('Active: ' + job.IsActive__c);
    System.debug('');
    
    System.debug('--- Execution Status ---');
    if (job.LastRunTime__c == null) {
        System.debug('⏳ Job has NOT run yet');
        System.debug('Next Run: ' + job.NextRunTime__c);
        System.debug('Current Time: ' + Datetime.now());
        
        if (job.NextRunTime__c > Datetime.now()) {
            Decimal minutesLeft = (job.NextRunTime__c.getTime() - Datetime.now().getTime()) / 60000.0;
            System.debug('⏰ Job will run in ' + minutesLeft.setScale(1) + ' minutes');
        } else {
            System.debug('🔍 Job should have run by now. Checking async jobs...');
            
            List<AsyncApexJob> queueableJobs = [
                SELECT Id, Status, ApexClass.Name, CreatedDate, CompletedDate
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'ESPNSyncQueueable'
                AND CreatedDate >= :Datetime.now().addMinutes(-10)
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            
            if (queueableJobs.isEmpty()) {
                System.debug('❌ No queueable jobs found. Check if OrgSchedulable is running:');
                System.debug('   SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE \'OrgSchedulable-%\'');
            } else {
                System.debug('Found ' + queueableJobs.size() + ' recent queueable jobs:');
                for (AsyncApexJob aj : queueableJobs) {
                    System.debug('   - Status: ' + aj.Status + ' | Started: ' + aj.CreatedDate);
                }
            }
        }
    } else {
        System.debug('✅ Job RAN at: ' + job.LastRunTime__c);
        System.debug('Status: ' + job.Last_Sync_Status__c);
        System.debug('Records Processed: ' + job.Last_Sync_Records_Processed__c);
        System.debug('Duration: ' + job.Last_Sync_Duration_Seconds__c + ' seconds');
        
        if (String.isNotBlank(job.Last_Sync_Errors__c)) {
            System.debug('⚠️  Errors: ' + job.Last_Sync_Errors__c);
        } else {
            System.debug('✅ No errors!');
        }
        
        System.debug('Next Run: ' + job.NextRunTime__c);
        System.debug('');
        
        // ========================================
        // Check Synced Data
        // ========================================
        System.debug('--- Synced Data Results ---');
        
        // Teams
        if (job.Sync_Teams__c) {
            Integer teamCount = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null];
            List<Account> wslTeams = [
                SELECT Name, ESPN_Team_ID__c, Team_Logo_URL__c, Stadium_Name__c
                FROM Account
                WHERE ESPN_Team_ID__c != null
                ORDER BY Name
                LIMIT 15
            ];
            
            System.debug('Teams Synced: ' + teamCount);
            for (Account team : wslTeams) {
                System.debug('  ✓ ' + team.Name + ' (ID: ' + team.ESPN_Team_ID__c + ')');
            }
            System.debug('');
        }
        
        // Fixtures
        if (job.Sync_Fixtures__c) {
            Integer fixtureCount = [
                SELECT COUNT() 
                FROM Fixture__c 
                WHERE Competition__r.ESPN_League_ID__c = 'eng.wsl'
            ];
            
            List<Fixture__c> recentFixtures = [
                SELECT Id, Name, Home_Team__r.Name, Away_Team__r.Name, 
                       Fixture_Date_Time__c, Status__c, ESPN_Event_ID__c
                FROM Fixture__c
                WHERE Competition__r.ESPN_League_ID__c = 'eng.wsl'
                ORDER BY Fixture_Date_Time__c
                LIMIT 10
            ];
            
            System.debug('Fixtures Synced: ' + fixtureCount);
            for (Fixture__c fix : recentFixtures) {
                String homeTeam = fix.Home_Team__r.Name != null ? fix.Home_Team__r.Name : 'TBD';
                String awayTeam = fix.Away_Team__r.Name != null ? fix.Away_Team__r.Name : 'TBD';
                System.debug('  ✓ ' + homeTeam + ' vs ' + awayTeam + ' - ' + fix.Fixture_Date_Time__c?.format('MMM dd'));
            }
            System.debug('');
        }
        
        // Competition
        List<Competition__c> comps = [
            SELECT Id, Name, ESPN_League_ID__c, Sport__c, Status__c
            FROM Competition__c
            WHERE ESPN_League_ID__c = 'eng.wsl'
            LIMIT 1
        ];
        
        if (!comps.isEmpty()) {
            System.debug('Competition: ' + comps[0].Name);
            System.debug('  Sport: ' + comps[0].Sport__c);
            System.debug('  Status: ' + comps[0].Status__c);
            System.debug('');
        }
        
        // ========================================
        // Success Summary
        // ========================================
        if (job.Last_Sync_Status__c == 'Success') {
            System.debug('');
            System.debug('🎉 TEST SUCCESSFUL! 🎉');
            System.debug('');
            System.debug('✅ Scheduler is working');
            System.debug('✅ WSL data synced successfully');
            System.debug('✅ ' + job.Last_Sync_Records_Processed__c + ' records processed');
            System.debug('✅ Completed in ' + job.Last_Sync_Duration_Seconds__c + ' seconds');
            System.debug('');
            System.debug('🚀 READY TO DEPLOY!');
            System.debug('');
            System.debug('Next Steps:');
            System.debug('1. Review the synced data in the UI');
            System.debug('2. Deploy the changes to your org');
            System.debug('3. Create production scheduled jobs');
            System.debug('4. Deactivate this test job:');
            System.debug('   UPDATE Scheduled_Process__c SET IsActive__c = false WHERE Id = \'' + job.Id + '\'');
        } else if (job.Last_Sync_Status__c == 'Partial') {
            System.debug('');
            System.debug('⚠️  PARTIAL SUCCESS');
            System.debug('Some data synced but there were errors. Check Last_Sync_Errors__c field.');
        } else if (job.Last_Sync_Status__c == 'Failed') {
            System.debug('');
            System.debug('❌ TEST FAILED');
            System.debug('Check the errors above and fix before deploying.');
        }
    }
}

System.debug('');
System.debug('=== Results Check Complete ===');


