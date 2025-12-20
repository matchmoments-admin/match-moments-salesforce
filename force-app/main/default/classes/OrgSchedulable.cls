/**
 * @description Global scheduler that runs every minute to execute scheduled processes
 * Based on OrgSchedulable pattern with ESPN-specific enhancements
 * @author Brendan Milton
 * @date 2025-12-20
 * 
 * Usage:
 * OrgSchedulable.startScheduler(); // Start 60 scheduled jobs (one per minute)
 * OrgSchedulable.stopScheduler();  // Stop all scheduled jobs
 */
public with sharing class OrgSchedulable implements Schedulable {
    private static final Integer MAX_RUNNING_JOBS = 90;
    private static Datetime now = Datetime.now();
    
    /**
     * @description Start the scheduler - creates 60 scheduled jobs (one per minute)
     * This ensures a job runs every minute to check for pending processes
     */
    public static void startScheduler() {
        String schedule = '0 {0} * * * ?';
        OrgSchedulable instance = new OrgSchedulable();
        for (Integer m = 0; m < 60; m++) {
            System.schedule('OrgSchedulable-' + m, String.format(schedule, new List<Object>{ m }), instance);
        }
        System.debug('OrgSchedulable: Started 60 scheduled jobs');
    }
    
    /**
     * @description Stop all OrgSchedulable jobs
     */
    public static void stopScheduler() {
        Integer aborted = 0;
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'OrgSchedulable-%']) {
            System.abortJob(ct.Id);
            aborted++;
        }
        System.debug('OrgSchedulable: Stopped ' + aborted + ' scheduled jobs');
    }
    
    /**
     * @description Get all active jobs that are due to run
     * @return List of Scheduled_Process__c records ready for execution
     */
    public static List<Scheduled_Process__c> getJobsToProcess() {
        List<Scheduled_Process__c> jobs = [
            SELECT Id, Name, ClassName__c, Data__c, Frequency__c, IsActive__c, 
                   LastRunTime__c, NextRunTime__c, Type__c, Units__c, BatchSize__c,
                   Competition__c, Sport_Type__c, League_Code__c,
                   Sync_Teams__c, Sync_Rosters__c, Sync_Fixtures__c, Sync_Stats__c,
                   Fixture_Date_Range_Days__c, Max_API_Calls_Per_Run__c,
                   Last_Sync_Status__c, Last_Sync_Records_Processed__c
            FROM Scheduled_Process__c
            WHERE IsActive__c = TRUE 
            AND NextRunTime__c <= :now
            ORDER BY NextRunTime__c ASC
        ];
        System.debug('OrgSchedulable: Found ' + jobs.size() + ' jobs to process');
        return jobs;
    }
    
    /**
     * @description Get set of currently running job class names
     * @return Set of Apex class names currently executing
     */
    public static Set<String> getRunningJobs() {
        List<AsyncApexJob> runningJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType IN ('BatchApex', 'Queueable') 
            AND Status IN ('Queued', 'Processing', 'Preparing', 'Holding')
        ];
        Set<String> runningJobNames = new Set<String>();
        for (AsyncApexJob job : runningJobs) {
            runningJobNames.add(job.ApexClass.Name);
        }
        System.debug('OrgSchedulable: ' + runningJobNames.size() + ' jobs currently running');
        return runningJobNames;
    }
    
    /**
     * @description Validate ESPN-specific job configuration
     * @param job Scheduled Process record
     * @return Boolean true if valid ESPN configuration
     */
    public static Boolean validateESPNJob(Scheduled_Process__c job) {
        // If no ESPN sync flags are set, assume it's valid non-ESPN job
        if (!job.Sync_Teams__c && !job.Sync_Rosters__c && 
            !job.Sync_Fixtures__c && !job.Sync_Stats__c) {
            return true;
        }
        
        // ESPN jobs need Sport Type and League Code
        if (String.isBlank(job.Sport_Type__c)) {
            System.debug('OrgSchedulable: Job ' + job.Name + ' missing Sport_Type__c');
            updateJobWithError(job, 'Configuration Error: Sport Type is required for ESPN sync');
            return false;
        }
        
        if (String.isBlank(job.League_Code__c)) {
            System.debug('OrgSchedulable: Job ' + job.Name + ' missing League_Code__c');
            updateJobWithError(job, 'Configuration Error: League Code is required for ESPN sync');
            return false;
        }
        
        // Validate Sport Type is supported
        Set<String> validSports = new Set<String>{'soccer', 'basketball', 'cricket', 'football'};
        if (!validSports.contains(job.Sport_Type__c.toLowerCase())) {
            System.debug('OrgSchedulable: Job ' + job.Name + ' has invalid Sport_Type__c: ' + job.Sport_Type__c);
            updateJobWithError(job, 'Configuration Error: Sport Type must be soccer, basketball, cricket, or football');
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Update job record with error message
     * @param job Scheduled Process record
     * @param errorMessage Error description
     */
    private static void updateJobWithError(Scheduled_Process__c job, String errorMessage) {
        try {
            job.Last_Sync_Status__c = 'Failed';
            job.Last_Sync_Errors__c = errorMessage + ' (Validation failed at ' + Datetime.now() + ')';
            update job;
        } catch (Exception e) {
            System.debug('OrgSchedulable: Failed to update job with error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Execute a scheduled process
     * @param job Scheduled Process configuration
     */
    public static void runJob(Scheduled_Process__c job) {
        System.debug('OrgSchedulable: Running job ' + job.Name + ' (' + job.ClassName__c + ')');
        
        // Validate ESPN jobs
        if (job.Sport_Type__c != null && !validateESPNJob(job)) {
            System.debug('OrgSchedulable: Skipping job ' + job.Name + ' - failed ESPN validation');
            return;
        }
        
        // Get the service class
        Type serviceClass = Type.forName(job.ClassName__c);
        if (serviceClass == null) {
            System.debug('OrgSchedulable: ERROR - Class not found: ' + job.ClassName__c);
            updateJobWithError(job, 'Class not found: ' + job.ClassName__c);
            return;
        }
        
        // Instantiate the service
        Object serviceInstance = serviceClass.newInstance();
        
        // Execute based on type
        try {
            if (serviceInstance instanceof Database.Batchable<SObject>) {
                Integer batchSize = job.BatchSize__c != null ? Integer.valueOf(job.BatchSize__c) : 200;
                Database.executeBatch((Database.Batchable<SObject>) serviceInstance, batchSize);
                System.debug('OrgSchedulable: Executed batch job with batch size ' + batchSize);
            } else if (serviceInstance instanceof Queueable) {
                System.enqueueJob((Queueable) serviceInstance);
                System.debug('OrgSchedulable: Enqueued queueable job');
            } else if (serviceInstance instanceof Schedulable) {
                String schedule = '0 ' + (now.minute() + 1) + ' ' + now.hour() + ' * * ?';
                System.schedule(job.ClassName__c + ' - ' + (now.minute() + 1), schedule, (Schedulable) serviceInstance);
                System.debug('OrgSchedulable: Scheduled job for next minute');
            } else {
                throw new SchedulableJobException('Could not run job ' + job.ClassName__c + '. Must implement Batchable, Queueable, or Schedulable');
            }
        } catch (Exception e) {
            System.debug('OrgSchedulable: ERROR executing job: ' + e.getMessage());
            updateJobWithError(job, 'Execution Error: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Filter jobs to prevent overloading the system
     * @param runningJobNames Set of currently running class names
     * @param jobsToProcess List of jobs that are due
     * @return Filtered list of jobs safe to run
     */
    public static List<Scheduled_Process__c> filterJobsToProcess(Set<String> runningJobNames, List<Scheduled_Process__c> jobsToProcess) {
        List<Scheduled_Process__c> filteredJobsToProcess = new List<Scheduled_Process__c>();
        Boolean hasTooManyJobs = runningJobNames.size() > MAX_RUNNING_JOBS;
        
        for (Scheduled_Process__c job : jobsToProcess) {
            // Skip if too many jobs and this is a batch job
            if (hasTooManyJobs && job.BatchSize__c != null) {
                System.debug('OrgSchedulable: Too many jobs in queue (' + runningJobNames.size() + ') - skipping ' + job.ClassName__c);
                continue;
            }
            
            // Skip if this class is already running (for batch jobs)
            if (runningJobNames.contains(job.ClassName__c) && job.BatchSize__c != null) {
                System.debug('OrgSchedulable: Job already running - skipping ' + job.ClassName__c);
                continue;
            }
            
            filteredJobsToProcess.add(job);
        }
        
        System.debug('OrgSchedulable: Filtered to ' + filteredJobsToProcess.size() + ' jobs to execute');
        return filteredJobsToProcess;
    }
    
    /**
     * @description Process a list of jobs
     * @param jobs List of Scheduled_Process__c records to execute
     * @return List of successfully processed jobs
     */
    public static List<Scheduled_Process__c> processJobs(List<Scheduled_Process__c> jobs) {
        List<Scheduled_Process__c> processedJobs = new List<Scheduled_Process__c>();
        
        for (Scheduled_Process__c job : jobs) {
            try {
                runJob(job);
                updateJob(job);
                processedJobs.add(job);
                System.debug('OrgSchedulable: Successfully processed job ' + job.Name);
            } catch (SchedulableJobException ex) {
                System.debug('OrgSchedulable: SchedulableJobException for ' + job.Name + ': ' + ex.getMessage());
                // Job already updated with error
            } catch (Exception ex) {
                System.debug('OrgSchedulable: Exception for ' + job.Name + ': ' + ex.getMessage());
                updateJobWithError(job, 'Unexpected Error: ' + ex.getMessage());
            }
        }
        
        return processedJobs;
    }
    
    /**
     * @description Update job record with next run time
     * @param job Scheduled Process record
     */
    public static void updateJob(Scheduled_Process__c job) {
        Datetime lastRunTime = now;
        Integer frequency = Integer.valueOf(job.Frequency__c);
        Datetime nextRunTime = null;
        
        switch on job.Units__c {
            when 'Minutes' {
                nextRunTime = lastRunTime.addMinutes(frequency);
            }
            when 'Hours' {
                nextRunTime = lastRunTime.addHours(frequency);
            }
            when 'Days' {
                nextRunTime = lastRunTime.addDays(frequency);
            }
            when 'Weeks' {
                nextRunTime = lastRunTime.addDays(frequency * 7);
            }
            when 'Months' {
                nextRunTime = lastRunTime.addMonths(frequency);
            }
            when else {
                System.debug('OrgSchedulable: Unknown unit: ' + job.Units__c);
            }
        }
        
        job.LastRunTime__c = lastRunTime;
        job.NextRunTime__c = nextRunTime?.addSeconds(-30); // 30 second buffer
        job.Last_Sync_Status__c = 'Running';
    }
    
    /**
     * @description Main execution method called by Salesforce scheduler
     * @param context Schedulable context
     */
    public void execute(SchedulableContext context) {
        System.debug('=== OrgSchedulable: Execute starting at ' + now + ' ===');
        
        try {
            Set<String> runningJobNames = getRunningJobs();
            List<Scheduled_Process__c> jobsToProcess = getJobsToProcess();
            List<Scheduled_Process__c> filteredJobsToProcess = filterJobsToProcess(runningJobNames, jobsToProcess);
            List<Scheduled_Process__c> processedJobs = processJobs(filteredJobsToProcess);
            
            if (!processedJobs.isEmpty()) {
                update processedJobs;
                System.debug('OrgSchedulable: Updated ' + processedJobs.size() + ' job records');
            }
            
            System.debug('=== OrgSchedulable: Execute complete ===');
        } catch (Exception e) {
            System.debug('OrgSchedulable: FATAL ERROR in execute(): ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Custom exception for schedulable job errors
     */
    private class SchedulableJobException extends Exception {
    }
}

