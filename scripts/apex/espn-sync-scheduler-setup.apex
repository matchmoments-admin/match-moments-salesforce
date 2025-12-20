/**
 * @description Setup script for ESPN Sync Scheduler
 * Creates sample Scheduled_Process__c records for common use cases
 * 
 * Execute in Anonymous Apex:
 * ESPNSyncSchedulerSetup.setupScheduler();
 * ESPNSyncSchedulerSetup.createSampleJobs();
 * 
 * To start the scheduler:
 * OrgSchedulable.startScheduler();
 * 
 * To stop the scheduler:
 * OrgSchedulable.stopScheduler();
 */
public class ESPNSyncSchedulerSetup {
    
    /**
     * @description Start the OrgSchedulable scheduler
     * Creates 60 scheduled jobs (one per minute)
     */
    public static void setupScheduler() {
        System.debug('=== Starting OrgSchedulable Scheduler ===');
        
        // Stop any existing schedulers first
        OrgSchedulable.stopScheduler();
        
        // Start new scheduler
        OrgSchedulable.startScheduler();
        
        System.debug('=== Scheduler started successfully ===');
        System.debug('The scheduler will check for jobs every minute.');
    }
    
    /**
     * @description Create sample Scheduled_Process__c records
     */
    public static void createSampleJobs() {
        System.debug('=== Creating Sample Scheduled Process Jobs ===');
        
        List<Scheduled_Process__c> jobs = new List<Scheduled_Process__c>();
        
        // Find NWSL and WSL competitions if they exist
        Map<String, Id> competitionMap = getCompetitionIds();
        
        // 1. NWSL Daily Teams & Rosters Sync (3 AM daily)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncQueueable',
            Type__c = 'Queueable Job',
            IsActive__c = false, // Start as inactive for manual activation
            Frequency__c = 1,
            Units__c = 'Days',
            Sport_Type__c = 'soccer',
            League_Code__c = 'usa.nwsl',
            Competition__c = competitionMap.get('usa.nwsl'),
            Sync_Teams__c = true,
            Sync_Rosters__c = true,
            Sync_Fixtures__c = false,
            Sync_Stats__c = false,
            Max_API_Calls_Per_Run__c = 50,
            NextRunTime__c = getNextRunTime(3, 0), // 3 AM tomorrow
            BatchSize__c = null
        ));
        
        // 2. WSL Daily Teams & Rosters Sync (3:30 AM daily)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncQueueable',
            Type__c = 'Queueable Job',
            IsActive__c = false,
            Frequency__c = 1,
            Units__c = 'Days',
            Sport_Type__c = 'soccer',
            League_Code__c = 'eng.wsl',
            Competition__c = competitionMap.get('eng.wsl'),
            Sync_Teams__c = true,
            Sync_Rosters__c = true,
            Sync_Fixtures__c = false,
            Sync_Stats__c = false,
            Max_API_Calls_Per_Run__c = 50,
            NextRunTime__c = getNextRunTime(3, 30), // 3:30 AM tomorrow
            BatchSize__c = null
        ));
        
        // 3. NWSL Hourly Fixtures Sync (during season)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncQueueable',
            Type__c = 'Queueable Job',
            IsActive__c = false,
            Frequency__c = 1,
            Units__c = 'Hours',
            Sport_Type__c = 'soccer',
            League_Code__c = 'usa.nwsl',
            Competition__c = competitionMap.get('usa.nwsl'),
            Sync_Teams__c = false,
            Sync_Rosters__c = false,
            Sync_Fixtures__c = true,
            Sync_Stats__c = false,
            Fixture_Date_Range_Days__c = 7,
            Max_API_Calls_Per_Run__c = 30,
            NextRunTime__c = Datetime.now().addHours(1),
            BatchSize__c = null
        ));
        
        // 4. WSL Hourly Fixtures Sync (during season)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncQueueable',
            Type__c = 'Queueable Job',
            IsActive__c = false,
            Frequency__c = 1,
            Units__c = 'Hours',
            Sport_Type__c = 'soccer',
            League_Code__c = 'eng.wsl',
            Competition__c = competitionMap.get('eng.wsl'),
            Sync_Teams__c = false,
            Sync_Rosters__c = false,
            Sync_Fixtures__c = true,
            Sync_Stats__c = false,
            Fixture_Date_Range_Days__c = 7,
            Max_API_Calls_Per_Run__c = 30,
            NextRunTime__c = Datetime.now().addHours(1).addMinutes(15),
            BatchSize__c = null
        ));
        
        // 5. Weekly Full Sync - All Leagues (Batch job for large volume)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncBatchable',
            Type__c = 'Batch Job',
            IsActive__c = false,
            Frequency__c = 1,
            Units__c = 'Weeks',
            Sport_Type__c = 'soccer',
            League_Code__c = 'usa.nwsl',
            Sync_Teams__c = true,
            Sync_Rosters__c = true,
            Sync_Fixtures__c = true,
            Sync_Stats__c = true,
            Fixture_Date_Range_Days__c = 30,
            Max_API_Calls_Per_Run__c = 200,
            NextRunTime__c = getNextRunTime(4, 0), // 4 AM next Sunday
            BatchSize__c = 50
        ));
        
        // 6. Manual Test Job (15 minutes from now)
        jobs.add(new Scheduled_Process__c(
            ClassName__c = 'ESPNSyncQueueable',
            Type__c = 'Queueable Job',
            IsActive__c = false,
            Frequency__c = 15,
            Units__c = 'Minutes',
            Sport_Type__c = 'soccer',
            League_Code__c = 'usa.nwsl',
            Competition__c = competitionMap.get('usa.nwsl'),
            Sync_Teams__c = true,
            Sync_Rosters__c = false,
            Sync_Fixtures__c = false,
            Sync_Stats__c = false,
            Max_API_Calls_Per_Run__c = 10,
            NextRunTime__c = Datetime.now().addMinutes(15),
            BatchSize__c = null
        ));
        
        insert jobs;
        
        System.debug('=== Created ' + jobs.size() + ' sample jobs ===');
        System.debug('Jobs are INACTIVE by default. Activate them via the UI or update IsActive__c = true');
        
        // Print summary
        for (Scheduled_Process__c job : jobs) {
            System.debug('Job: ' + job.ClassName__c + ' | League: ' + job.League_Code__c + 
                        ' | Frequency: ' + job.Frequency__c + ' ' + job.Units__c + 
                        ' | Next Run: ' + job.NextRunTime__c);
        }
    }
    
    /**
     * @description Get competition IDs by ESPN League code
     * @return Map of league code to Competition ID
     */
    private static Map<String, Id> getCompetitionIds() {
        Map<String, Id> competitionMap = new Map<String, Id>();
        
        List<Competition__c> competitions = [
            SELECT Id, ESPN_League_ID__c 
            FROM Competition__c 
            WHERE ESPN_League_ID__c IN ('usa.nwsl', 'eng.wsl')
        ];
        
        for (Competition__c comp : competitions) {
            competitionMap.put(comp.ESPN_League_ID__c, comp.Id);
        }
        
        System.debug('Found ' + competitionMap.size() + ' competitions: ' + competitionMap.keySet());
        return competitionMap;
    }
    
    /**
     * @description Calculate next run time for a specific hour/minute
     * @param hour Hour (0-23)
     * @param minute Minute (0-59)
     * @return Datetime Next occurrence of this time
     */
    private static Datetime getNextRunTime(Integer hour, Integer minute) {
        Datetime now = Datetime.now();
        Datetime target = Datetime.newInstance(
            now.date(), 
            Time.newInstance(hour, minute, 0, 0)
        );
        
        // If time has passed today, schedule for tomorrow
        if (target <= now) {
            target = target.addDays(1);
        }
        
        return target;
    }
    
    /**
     * @description Quick test of a single sync operation
     */
    public static void testSingleSync() {
        System.debug('=== Testing Single Sync ===');
        
        try {
            // Test NWSL team sync
            Integer teamsCount = ESPNSyncService.syncLeagueTeams('soccer', 'usa.nwsl');
            System.debug('Successfully synced ' + teamsCount + ' NWSL teams');
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Delete all sample jobs (cleanup)
     */
    public static void deleteAllJobs() {
        List<Scheduled_Process__c> jobs = [
            SELECT Id FROM Scheduled_Process__c
        ];
        delete jobs;
        System.debug('Deleted ' + jobs.size() + ' scheduled process records');
    }
    
    /**
     * @description Activate a specific job by name pattern
     * @param namePattern Pattern to match (e.g., 'NWSL', 'WSL')
     */
    public static void activateJobsByPattern(String namePattern) {
        List<Scheduled_Process__c> jobs = [
            SELECT Id, Name, League_Code__c
            FROM Scheduled_Process__c
            WHERE League_Code__c LIKE :('%' + namePattern + '%')
            OR Sport_Type__c LIKE :('%' + namePattern + '%')
        ];
        
        for (Scheduled_Process__c job : jobs) {
            job.IsActive__c = true;
        }
        
        update jobs;
        System.debug('Activated ' + jobs.size() + ' jobs matching pattern: ' + namePattern);
    }
}

