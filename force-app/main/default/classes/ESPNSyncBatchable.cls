/**
 * @description Batchable job for large-scale ESPN data synchronization
 * Used for processing hundreds of teams or thousands of players
 * Reads configuration from Scheduled_Process__c
 * @author Brendan Milton
 * @date 2025-12-20
 * 
 * Usage:
 * Database.executeBatch(new ESPNSyncBatchable(scheduledProcessId), 200);
 */
public class ESPNSyncBatchable implements 
    Database.Batchable<SObject>, 
    Database.AllowsCallouts, 
    Database.Stateful {
    
    private Id scheduledProcessId;
    private Scheduled_Process__c config;
    private Datetime startTime;
    
    // Stateful counters
    private Integer totalProcessed = 0;
    private Integer totalSuccesses = 0;
    private Integer totalErrors = 0;
    private List<String> errors = new List<String>();
    
    /**
     * @description Default constructor required by OrgSchedulable
     */
    public ESPNSyncBatchable() {
        // Will be called by Type.forName().newInstance()
    }
    
    /**
     * @description Constructor with scheduled process ID
     * @param processId Scheduled_Process__c record ID
     */
    public ESPNSyncBatchable(Id processId) {
        this.scheduledProcessId = processId;
    }
    
    /**
     * @description Start method - query records to process
     * @param bc Batch context
     * @return Database.QueryLocator for teams to process
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = Datetime.now();
        System.debug('=== ESPNSyncBatchable: Start ===');
        
        // Load configuration
        config = queryScheduledProcess();
        
        if (config == null) {
            System.debug('ESPNSyncBatchable: No configuration found');
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = null]);
        }
        
        System.debug('ESPNSyncBatchable: Processing ' + config.Name);
        
        // Query teams based on configuration
        String query = 'SELECT Id, Name, ESPN_Team_ID__c, Sport__c FROM Account ';
        query += 'WHERE ESPN_Team_ID__c != null ';
        
        if (config.Competition__c != null) {
            // Filter by teams in this competition (via fixtures)
            query += 'AND Id IN (SELECT Home_Team__c FROM Match__c WHERE Competition__c = :config.Competition__c) ';
        }
        
        query += 'ORDER BY Name';
        
        System.debug('ESPNSyncBatchable: Query - ' + query);
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method - process batch of teams
     * @param bc Batch context
     * @param scope List of Account records to process
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        System.debug('ESPNSyncBatchable: Processing batch of ' + scope.size() + ' teams');
        
        String sport = getSportType();
        String leagueCode = getLeagueCode();
        
        for (Account team : scope) {
            try {
                totalProcessed++;
                
                // Sync roster for this team
                if (config.Sync_Rosters__c) {
                    Integer playersCount = ESPNSyncService.syncTeamRoster(
                        sport, 
                        leagueCode, 
                        team.ESPN_Team_ID__c
                    );
                    totalSuccesses += playersCount;
                    System.debug('ESPNSyncBatchable: Synced ' + playersCount + ' players for ' + team.Name);
                }
                
            } catch (Exception e) {
                totalErrors++;
                String errorMsg = 'Team: ' + team.Name + ' - ' + e.getMessage();
                errors.add(errorMsg);
                System.debug('ESPNSyncBatchable: ERROR - ' + errorMsg);
            }
        }
    }
    
    /**
     * @description Finish method - update scheduled process record
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('=== ESPNSyncBatchable: Finish ===');
        System.debug('Total teams processed: ' + totalProcessed);
        System.debug('Total players synced: ' + totalSuccesses);
        System.debug('Total errors: ' + totalErrors);
        
        if (scheduledProcessId != null) {
            updateProcessRecord();
        }
        
        Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
        System.debug('=== ESPNSyncBatchable: Complete in ' + duration + ' seconds ===');
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
            // Called by OrgSchedulable - find the first active batch process
            List<Scheduled_Process__c> processes = [
                SELECT Id, Name, ClassName__c, Data__c,
                       Competition__c, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
                       Sport_Type__c, League_Code__c,
                       Sync_Teams__c, Sync_Rosters__c, Sync_Fixtures__c, Sync_Stats__c,
                       Fixture_Date_Range_Days__c, Max_API_Calls_Per_Run__c
                FROM Scheduled_Process__c
                WHERE ClassName__c = 'ESPNSyncBatchable'
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
     * @description Update scheduled process record with results
     */
    private void updateProcessRecord() {
        try {
            Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
            
            String status;
            if (totalErrors == 0) {
                status = 'Success';
            } else if (totalSuccesses > 0) {
                status = 'Partial';
            } else {
                status = 'Failed';
            }
            
            Scheduled_Process__c process = new Scheduled_Process__c(
                Id = scheduledProcessId,
                Last_Sync_Status__c = status,
                Last_Sync_Records_Processed__c = totalSuccesses,
                Last_Sync_Duration_Seconds__c = duration
            );
            
            if (!errors.isEmpty()) {
                // Keep only last 100 errors to avoid field size limits
                Integer maxErrors = Math.min(100, errors.size());
                List<String> limitedErrors = new List<String>();
                for (Integer i = 0; i < maxErrors; i++) {
                    limitedErrors.add(errors[i]);
                }
                process.Last_Sync_Errors__c = String.join(limitedErrors, '\n');
                
                if (errors.size() > 100) {
                    process.Last_Sync_Errors__c += '\n... and ' + (errors.size() - 100) + ' more errors';
                }
            } else {
                process.Last_Sync_Errors__c = null; // Clear previous errors
            }
            
            update process;
            System.debug('ESPNSyncBatchable: Updated scheduled process record');
        } catch (Exception e) {
            System.debug('ESPNSyncBatchable: Failed to update process record: ' + e.getMessage());
        }
    }
}

