/**
 * @description Queueable job for ESPN data synchronization
 * Reads configuration from Scheduled_Process__c and executes sync operations
 * Follows FFLIB patterns and integrates with ESPNSyncService
 * @author Brendan Milton
 * @date 2025-12-20
 * 
 * Usage:
 * System.enqueueJob(new ESPNSyncQueueable(scheduledProcessId));
 */
public class ESPNSyncQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id scheduledProcessId;
    private Scheduled_Process__c config;
    private Datetime startTime;
    private Integer totalRecordsProcessed = 0;
    private List<String> errors = new List<String>();
    
    /**
     * @description Default constructor required by OrgSchedulable
     */
    public ESPNSyncQueueable() {
        // Will be called by Type.forName().newInstance()
        // Actual config loaded from active jobs in execute()
    }
    
    /**
     * @description Constructor with scheduled process ID
     * @param processId Scheduled_Process__c record ID
     */
    public ESPNSyncQueueable(Id processId) {
        this.scheduledProcessId = processId;
    }
    
    /**
     * @description Main execution method
     * @param context Queueable context
     */
    public void execute(QueueableContext context) {
        startTime = Datetime.now();
        System.debug('=== ESPNSyncQueueable: Starting execution ===');
        
        try {
            // Load configuration
            config = queryScheduledProcess();
            if (config == null) {
                System.debug('ESPNSyncQueueable: No active scheduled process found');
                return;
            }
            
            System.debug('ESPNSyncQueueable: Processing ' + config.Name);
            
            // Create UOW for this transaction
            fflib_ISObjectUnitOfWork uow = Application.createUOW();
            
            // Execute sync operations based on configuration
            ESPNSyncResult result = executeSync(uow);
            
            // Commit all changes
            if (result.success) {
                Application.commitAndClear();
                System.debug('ESPNSyncQueueable: Successfully committed changes');
            }
            
            // Update the scheduled process record with results
            updateProcessRecord(result);
            
            // Chain next phase if needed
            chainNextPhase();
            
        } catch (Exception e) {
            System.debug('ESPNSyncQueueable: FATAL ERROR - ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            errors.add('FATAL: ' + e.getMessage());
            updateProcessRecordWithError(e);
        }
        
        Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
        System.debug('=== ESPNSyncQueueable: Complete in ' + duration + ' seconds ===');
    }
    
    /**
     * @description Query scheduled process configuration
     * @return Scheduled_Process__c record or null
     */
    private Scheduled_Process__c queryScheduledProcess() {
        if (scheduledProcessId != null) {
            List<Scheduled_Process__c> processes = [
                SELECT Id, Name, ClassName__c, Data__c,
                       Competition__c, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
                       Sport_Type__c, League_Code__c,
                       Sync_Teams__c, Sync_Rosters__c, Sync_Fixtures__c, Sync_Stats__c,
                       Fixture_Date_Range_Days__c, Max_API_Calls_Per_Run__c
                FROM Scheduled_Process__c
                WHERE Id = :scheduledProcessId
                LIMIT 1
            ];
            return processes.isEmpty() ? null : processes[0];
        } else {
            // Called by OrgSchedulable - find the first active process for this class
            List<Scheduled_Process__c> processes = [
                SELECT Id, Name, ClassName__c, Data__c,
                       Competition__c, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
                       Sport_Type__c, League_Code__c,
                       Sync_Teams__c, Sync_Rosters__c, Sync_Fixtures__c, Sync_Stats__c,
                       Fixture_Date_Range_Days__c, Max_API_Calls_Per_Run__c
                FROM Scheduled_Process__c
                WHERE ClassName__c = 'ESPNSyncQueueable'
                AND IsActive__c = TRUE
                AND Last_Sync_Status__c = 'Running'
                ORDER BY LastRunTime__c DESC
                LIMIT 1
            ];
            
            if (!processes.isEmpty()) {
                scheduledProcessId = processes[0].Id;
                return processes[0];
            }
            return null;
        }
    }
    
    /**
     * @description Execute sync operations based on configuration
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with execution results
     */
    private ESPNSyncResult executeSync(fflib_ISObjectUnitOfWork uow) {
        ESPNSyncResult combinedResult = new ESPNSyncResult();
        combinedResult.success = true;
        combinedResult.message = 'ESPN Sync completed';
        
        // Get sport and league from config or competition
        String sport = getSportType();
        String leagueCode = getLeagueCode();
        
        System.debug('ESPNSyncQueueable: Sport=' + sport + ', League=' + leagueCode);
        
        // Determine current phase based on Data__c field
        String currentPhase = String.isBlank(config.Data__c) ? 'teams' : config.Data__c;
        System.debug('ESPNSyncQueueable: Current phase=' + currentPhase);
        
        // Execute based on phase to avoid mixing DML and callouts
        if (currentPhase == 'teams' && config.Sync_Teams__c) {
            ESPNSyncResult teamResult = syncTeams(sport, leagueCode);
            mergeResult(combinedResult, teamResult, 'Teams');
            // After DML, we cannot make callouts in same transaction
            // Chain to next phase
            return combinedResult;
        }
        
        if (currentPhase == 'rosters' && config.Sync_Rosters__c) {
            ESPNSyncResult rosterResult = syncRosters(sport, leagueCode);
            mergeResult(combinedResult, rosterResult, 'Rosters');
            // After callouts, we can make more callouts
            // But chain to fixtures phase for clarity
            return combinedResult;
        }
        
        if (currentPhase == 'fixtures' && config.Sync_Fixtures__c) {
            ESPNSyncResult fixtureResult = syncFixtures(sport, leagueCode, uow);
            mergeResult(combinedResult, fixtureResult, 'Fixtures');
            return combinedResult;
        }
        
        if (currentPhase == 'stats' && config.Sync_Stats__c) {
            // Stats sync not yet implemented
            System.debug('ESPNSyncQueueable: Stats sync not yet implemented');
        }
        
        return combinedResult;
    }
    
    /**
     * @description Sync teams for the league
     * @param sport Sport type
     * @param leagueCode League code
     * @return ESPNSyncResult
     */
    private ESPNSyncResult syncTeams(String sport, String leagueCode) {
        System.debug('ESPNSyncQueueable: Syncing teams');
        try {
            Integer count = ESPNSyncService.syncLeagueTeams(sport, leagueCode);
            totalRecordsProcessed += count;
            
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = true;
            result.message = count + ' teams synced';
            result.recordsProcessed = count;
            return result;
        } catch (Exception e) {
            System.debug('ESPNSyncQueueable: Team sync error - ' + e.getMessage());
            errors.add('Teams: ' + e.getMessage());
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = false;
            result.message = 'Team sync failed: ' + e.getMessage();
            return result;
        }
    }
    
    /**
     * @description Sync rosters for all teams
     * @param sport Sport type
     * @param leagueCode League code
     * @return ESPNSyncResult
     */
    private ESPNSyncResult syncRosters(String sport, String leagueCode) {
        System.debug('ESPNSyncQueueable: Syncing rosters');
        try {
            Integer count = ESPNSyncService.syncAllRostersForLeague(sport, leagueCode);
            totalRecordsProcessed += count;
            
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = true;
            result.message = count + ' players synced';
            result.recordsProcessed = count;
            return result;
        } catch (Exception e) {
            System.debug('ESPNSyncQueueable: Roster sync error - ' + e.getMessage());
            errors.add('Rosters: ' + e.getMessage());
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = false;
            result.message = 'Roster sync failed: ' + e.getMessage();
            return result;
        }
    }
    
    /**
     * @description Sync fixtures for date range
     * @param sport Sport type
     * @param leagueCode League code
     * @param uow Unit of Work
     * @return ESPNSyncResult
     */
    private ESPNSyncResult syncFixtures(String sport, String leagueCode, fflib_ISObjectUnitOfWork uow) {
        System.debug('ESPNSyncQueueable: Syncing fixtures');
        try {
            // Get or create competition
            Id competitionId = config.Competition__c;
            if (competitionId == null) {
                String leagueName = leagueCode.toUpperCase();
                String sportType = sport.capitalize();
                String seasonYear = String.valueOf(Date.today().year());
                competitionId = ESPNSyncService.getOrCreateCompetition(leagueCode, leagueName, sportType, seasonYear);
            }
            
            // Determine date range
            Date startDate = Date.today();
            Integer days = config.Fixture_Date_Range_Days__c != null ? 
                          Integer.valueOf(config.Fixture_Date_Range_Days__c) : 7;
            Date endDate = startDate.addDays(days);
            
            Integer count = ESPNSyncService.syncFixturesForDateRange(
                sport, leagueCode, startDate, endDate, competitionId
            );
            totalRecordsProcessed += count;
            
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = true;
            result.message = count + ' fixtures synced';
            result.recordsProcessed = count;
            return result;
        } catch (Exception e) {
            System.debug('ESPNSyncQueueable: Fixture sync error - ' + e.getMessage());
            errors.add('Fixtures: ' + e.getMessage());
            ESPNSyncResult result = new ESPNSyncResult();
            result.success = false;
            result.message = 'Fixture sync failed: ' + e.getMessage();
            return result;
        }
    }
    
    /**
     * @description Get sport type from config or competition
     * @return String sport type
     */
    private String getSportType() {
        if (String.isNotBlank(config.Sport_Type__c)) {
            return config.Sport_Type__c.toLowerCase();
        }
        if (config.Competition__c != null && String.isNotBlank(config.Competition__r.Sport__c)) {
            return config.Competition__r.Sport__c.toLowerCase();
        }
        return 'soccer'; // Default
    }
    
    /**
     * @description Get league code from config or competition
     * @return String league code
     */
    private String getLeagueCode() {
        if (String.isNotBlank(config.League_Code__c)) {
            return config.League_Code__c;
        }
        if (config.Competition__c != null && String.isNotBlank(config.Competition__r.ESPN_League_ID__c)) {
            return config.Competition__r.ESPN_League_ID__c;
        }
        return 'usa.nwsl'; // Default
    }
    
    /**
     * @description Merge sync result into combined result
     * @param combined Combined result
     * @param newResult New result to merge
     * @param category Category name for error tracking
     */
    private void mergeResult(ESPNSyncResult combined, ESPNSyncResult newResult, String category) {
        if (!newResult.success) {
            combined.success = false;
            combined.message += '\n' + category + ': ' + newResult.message;
        } else {
            combined.message += '\n' + category + ': ' + newResult.message;
        }
    }
    
    /**
     * @description Update scheduled process record with results
     * @param result ESPNSyncResult from sync operations
     */
    private void updateProcessRecord(ESPNSyncResult result) {
        if (scheduledProcessId == null) return;
        
        try {
            Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
            
            Scheduled_Process__c process = new Scheduled_Process__c(
                Id = scheduledProcessId,
                Last_Sync_Status__c = result.success ? 'Success' : (errors.isEmpty() ? 'Partial' : 'Failed'),
                Last_Sync_Records_Processed__c = totalRecordsProcessed,
                Last_Sync_Duration_Seconds__c = duration
            );
            
            if (!errors.isEmpty()) {
                process.Last_Sync_Errors__c = String.join(errors, '\n');
            } else {
                process.Last_Sync_Errors__c = null; // Clear previous errors
            }
            
            update process;
            System.debug('ESPNSyncQueueable: Updated scheduled process record');
        } catch (Exception e) {
            System.debug('ESPNSyncQueueable: Failed to update process record: ' + e.getMessage());
        }
    }
    
    /**
     * @description Update scheduled process record with error
     * @param e Exception that occurred
     */
    private void updateProcessRecordWithError(Exception e) {
        if (scheduledProcessId == null) return;
        
        try {
            Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
            
            update new Scheduled_Process__c(
                Id = scheduledProcessId,
                Last_Sync_Status__c = 'Failed',
                Last_Sync_Errors__c = String.join(errors, '\n'),
                Last_Sync_Records_Processed__c = totalRecordsProcessed,
                Last_Sync_Duration_Seconds__c = duration
            );
        } catch (Exception ex) {
            System.debug('ESPNSyncQueueable: Failed to update process record with error: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Chain to next phase if multi-phase sync
     * Uses Data__c field to track current phase
     */
    private void chainNextPhase() {
        if (scheduledProcessId == null) return;
        
        // Determine current phase and next phase
        String currentPhase = String.isBlank(config.Data__c) ? 'teams' : config.Data__c;
        String nextPhase = null;
        
        // Determine next phase based on what's enabled
        if (currentPhase == 'teams' && config.Sync_Rosters__c) {
            nextPhase = 'rosters';
        } else if (currentPhase == 'teams' && config.Sync_Fixtures__c) {
            nextPhase = 'fixtures';
        } else if (currentPhase == 'rosters' && config.Sync_Fixtures__c) {
            nextPhase = 'fixtures';
        } else if (currentPhase == 'fixtures' && config.Sync_Stats__c) {
            nextPhase = 'stats';
        }
        
        if (nextPhase != null) {
            System.debug('ESPNSyncQueueable: Chaining to next phase: ' + nextPhase);
            
            // Update config to next phase
            update new Scheduled_Process__c(
                Id = scheduledProcessId,
                Data__c = nextPhase
            );
            
            // Enqueue next phase
            System.enqueueJob(new ESPNSyncQueueable(scheduledProcessId));
        } else {
            System.debug('ESPNSyncQueueable: All phases complete');
            
            // Clear phase data
            update new Scheduled_Process__c(
                Id = scheduledProcessId,
                Data__c = null
            );
        }
    }
    
    /**
     * @description Inner class for sync results
     */
    public class ESPNSyncResult {
        public Boolean success;
        public String message;
        public Integer recordsProcessed;
        
        public ESPNSyncResult() {
            this.success = false;
            this.message = '';
            this.recordsProcessed = 0;
        }
        
        // Removed static keyword - inner classes cannot have static methods in Apex
        // Use constructor instead: new ESPNSyncResult() and set properties
    }
}

