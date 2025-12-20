# ESPN Sync Scheduler - Setup & Usage Guide

## Overview

The ESPN Sync Scheduler is a configurable, record-driven scheduling system that automates ESPN data synchronization overnight. It uses the **OrgSchedulable** pattern to run jobs every minute, checking for scheduled processes that need execution.

## Architecture

```
OrgSchedulable (runs every minute)
  ↓
Scheduled_Process__c (configuration records)
  ↓
ESPNSyncQueueable or ESPNSyncBatchable
  ↓
ESPNSyncService (FFLIB)
  ↓
ESPNHttpService → ESPN API
```

## Features

✅ **Record-Driven Configuration** - No code deployments needed  
✅ **Flexible Scheduling** - Minutes, Hours, Days, Weeks, Months  
✅ **Multi-Sport Support** - Soccer, Basketball, Cricket, Football  
✅ **Selective Sync** - Choose Teams, Rosters, Fixtures, Stats  
✅ **Rate Limit Protection** - Configurable API call limits  
✅ **Error Tracking** - Detailed error logs per job  
✅ **Performance Monitoring** - Duration and record count tracking  
✅ **FFLIB Compliant** - Integrates with existing patterns  

## Quick Start

### 1. Deploy Metadata

Deploy all files in this changeset to your org:
- `Scheduled_Process__c` object + fields
- `OrgSchedulable` class
- `ESPNSyncQueueable` class
- `ESPNSyncBatchable` class
- Enhanced `ESPNSyncServiceImpl` methods
- List views and tab

### 2. Start the Scheduler

Execute in Anonymous Apex:

```apex
// Start the scheduler (creates 60 scheduled jobs)
OrgSchedulable.startScheduler();

// Verify it's running
System.debug([SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'OrgSchedulable-%']);
// Should return 60
```

### 3. Create Sample Jobs

Execute in Anonymous Apex:

```apex
// Load the setup script
execute anonymous window: ESPNSyncSchedulerSetup.createSampleJobs();

// Or manually run from the script file
// scripts/apex/espn-sync-scheduler-setup.apex
```

This creates 6 sample jobs:
1. **NWSL Daily Teams & Rosters** - 3:00 AM daily
2. **WSL Daily Teams & Rosters** - 3:30 AM daily  
3. **NWSL Hourly Fixtures** - Every hour
4. **WSL Hourly Fixtures** - Every hour (offset 15 min)
5. **Weekly Full Sync** - 4:00 AM Sundays (Batch)
6. **Test Job** - 15 minutes from now

### 4. Activate Jobs

Jobs are created as **inactive** by default. Activate them via:

**Option A: UI**
1. Navigate to Scheduled Processes tab
2. Edit a record
3. Check `Is Active`
4. Save

**Option B: Apex**
```apex
ESPNSyncSchedulerSetup.activateJobsByPattern('NWSL');
```

## Configuration Guide

### Scheduled_Process__c Fields

**Core Scheduling**
- `ClassName__c` - Apex class (ESPNSyncQueueable or ESPNSyncBatchable)
- `Type__c` - Job type (Queueable/Batch/Schedulable)
- `IsActive__c` - Enable/disable job
- `Frequency__c` + `Units__c` - How often to run
- `NextRunTime__c` - When to run next (set manually first time)
- `BatchSize__c` - For batch jobs only (default 200)

**ESPN Configuration**
- `Competition__c` - Link to Competition record (optional)
- `Sport_Type__c` - soccer/basketball/cricket/football
- `League_Code__c` - ESPN league code (e.g., usa.nwsl)
- `Sync_Teams__c` - ✓ to sync team data
- `Sync_Rosters__c` - ✓ to sync player rosters
- `Sync_Fixtures__c` - ✓ to sync matches
- `Sync_Stats__c` - ✓ to sync statistics (future)
- `Fixture_Date_Range_Days__c` - Days forward to sync (default 7)
- `Max_API_Calls_Per_Run__c` - Rate limit guard (default 50)

**Monitoring Fields** (auto-populated)
- `Last_Sync_Status__c` - Success/Partial/Failed/Running
- `Last_Sync_Records_Processed__c` - Count of records synced
- `Last_Sync_Errors__c` - Error messages
- `Last_Sync_Duration_Seconds__c` - Execution time

### Creating Custom Jobs

Example: Sync WNBA teams daily at 2 AM

```apex
insert new Scheduled_Process__c(
    ClassName__c = 'ESPNSyncQueueable',
    Type__c = 'Queueable Job',
    IsActive__c = true,
    Frequency__c = 1,
    Units__c = 'Days',
    Sport_Type__c = 'basketball',
    League_Code__c = 'wnba',
    Sync_Teams__c = true,
    Sync_Rosters__c = true,
    Max_API_Calls_Per_Run__c = 50,
    NextRunTime__c = Datetime.newInstance(
        Date.today().addDays(1),
        Time.newInstance(2, 0, 0, 0)
    )
);
```

## Monitoring

### List Views

Navigate to **Scheduled Processes** tab:

1. **Active ESPN Sync Jobs** - Currently enabled jobs
2. **All Scheduled Processes** - Complete list
3. **Failed Sync Jobs** - Errors and partial syncs
4. **Running Jobs** - Currently executing
5. **Recent Sync History** - Last 7 days

### Checking Job Status

```apex
// Query recent runs
List<Scheduled_Process__c> recent = [
    SELECT Name, LastRunTime__c, Last_Sync_Status__c, 
           Last_Sync_Records_Processed__c, Last_Sync_Duration_Seconds__c
    FROM Scheduled_Process__c
    WHERE LastRunTime__c >= LAST_N_DAYS:1
    ORDER BY LastRunTime__c DESC
];

for (Scheduled_Process__c job : recent) {
    System.debug(job.Name + ': ' + job.Last_Sync_Status__c + 
                 ' (' + job.Last_Sync_Records_Processed__c + ' records)');
}
```

### Viewing Errors

```apex
List<Scheduled_Process__c> failed = [
    SELECT Name, Last_Sync_Errors__c
    FROM Scheduled_Process__c
    WHERE Last_Sync_Status__c IN ('Failed', 'Partial')
    ORDER BY LastRunTime__c DESC
    LIMIT 10
];

for (Scheduled_Process__c job : failed) {
    System.debug('Job: ' + job.Name);
    System.debug('Errors: ' + job.Last_Sync_Errors__c);
}
```

## Troubleshooting

### Job Not Running

1. **Check if scheduler is active**
```apex
System.debug([SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'OrgSchedulable-%']);
```

2. **Check if job is active and NextRunTime is in the past**
```apex
List<Scheduled_Process__c> due = [
    SELECT Name, NextRunTime__c, IsActive__c
    FROM Scheduled_Process__c
    WHERE NextRunTime__c <= :Datetime.now()
];
System.debug('Due jobs: ' + due);
```

3. **Check for validation errors**
```apex
List<Scheduled_Process__c> invalid = [
    SELECT Name, Last_Sync_Errors__c
    FROM Scheduled_Process__c
    WHERE Last_Sync_Errors__c LIKE '%Configuration Error%'
];
```

### ESPN API Errors

If you see ESPN API errors:

1. **Check Remote Site Settings**
   - Setup → Remote Site Settings
   - Ensure `https://site.web.api.espn.com` is configured

2. **Verify League Codes**
   - Common codes: usa.nwsl, eng.wsl, wnba
   - Test manually: `ESPNHttpService.getTeams('soccer', 'usa.nwsl')`

3. **Rate Limiting**
   - Reduce `Max_API_Calls_Per_Run__c`
   - Increase `Frequency__c` to spread out calls

### Too Many Running Jobs

```apex
// Check async jobs
System.debug([SELECT COUNT() FROM AsyncApexJob 
              WHERE Status IN ('Queued', 'Processing')]);

// OrgSchedulable will skip jobs if > 90 running
```

## Maintenance

### Stop Scheduler Temporarily

```apex
OrgSchedulable.stopScheduler();
```

### Restart Scheduler

```apex
OrgSchedulable.startScheduler();
```

### Deactivate All Jobs

```apex
update [SELECT Id FROM Scheduled_Process__c SET IsActive__c = false];
```

### Delete All Jobs

```apex
ESPNSyncSchedulerSetup.deleteAllJobs();
```

### Manual Test Run

```apex
// Test a single sync operation
ESPNSyncSchedulerSetup.testSingleSync();

// Or run a specific job manually
Id jobId = [SELECT Id FROM Scheduled_Process__c LIMIT 1].Id;
System.enqueueJob(new ESPNSyncQueueable(jobId));
```

## Performance Optimization

### Queueable vs Batch

**Use Queueable When:**
- < 50 teams to process
- Need real-time execution
- Simple dependencies (teams → rosters → fixtures)

**Use Batch When:**
- 100+ teams to process
- Can tolerate slower execution
- Want to process in smaller chunks

### Governor Limits

- **Queueable**: 50 chained jobs per transaction
- **Batch**: 5 concurrent jobs, unlimited scope size
- **API Callouts**: 100 per transaction (both)

**Recommendation**: Use Queueable for overnight syncs, Batch for weekly full syncs

## FFLIB Integration

The scheduler seamlessly integrates with existing FFLIB patterns:

```apex
// In ESPNSyncQueueable
fflib_ISObjectUnitOfWork uow = Application.createUOW();

IESPNSyncService syncService = 
    (IESPNSyncService) Application.Service.newInstance(IESPNSyncService.class);

// Execute sync operations
syncService.syncCompetitionTeams(competitionId, uow);
syncService.syncCompetitionRosters(competitionId, uow);

// Commit all changes
Application.commitAndClear();
```

## Best Practices

1. **Start with Test Jobs** - Use 15-minute frequency for testing
2. **Monitor First Week** - Watch for errors and adjust timing
3. **Stagger Job Times** - Avoid running all jobs simultaneously
4. **Use Competition Lookup** - Link jobs to specific competitions
5. **Set Realistic API Limits** - Start with 30-50 calls per run
6. **Review Errors Weekly** - Check Failed Sync Jobs list view
7. **Deactivate Off-Season** - Disable fixture syncs when season ends

## Support

For issues or questions:
1. Check `Last_Sync_Errors__c` field on job record
2. Review Apex logs for OrgSchedulable execution
3. Query AsyncApexJob for job history
4. Test individual components (ESPNHttpService, ESPNSyncService)

## Version History

- **v1.0** (2025-12-20) - Initial implementation
  - OrgSchedulable pattern
  - ESPNSyncQueueable
  - ESPNSyncBatchable  
  - Scheduled_Process__c object
  - Bulk sync methods in ESPNSyncServiceImpl

