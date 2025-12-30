/**
 * Sync Current and Upcoming Fixtures from ESPN
 * This script fetches fixtures for Premier League and Champions League
 * for a date range from 7 days ago to 60 days in the future
 */

System.debug('=== ESPN Fixture Sync Started ===');
System.debug('Date: ' + DateTime.now());

// Define date range: 7 days ago to 60 days in the future
Date startDate = Date.today().addDays(-7);
Date endDate = Date.today().addDays(60);

System.debug('Date Range: ' + startDate + ' to ' + endDate);

// Get competitions from Salesforce
List<Competition__c> competitions = [
    SELECT Id, Name, ESPN_League_ID__c, Sport__c
    FROM Competition__c
    WHERE Status__c = 'Active'
    AND ESPN_League_ID__c IN ('eng.1', 'uefa.champions')
    ORDER BY Name
];

System.debug('Found ' + competitions.size() + ' active competitions');

// Track totals
Integer totalFixtures = 0;
Integer totalErrors = 0;

// Sync fixtures for each competition
for (Competition__c comp : competitions) {
    try {
        System.debug('');
        System.debug('=== Processing: ' + comp.Name + ' (' + comp.ESPN_League_ID__c + ') ===');
        
        // Call ESPN API to sync fixtures
        Integer fixturesCount = ESPNSyncService.syncFixturesForDateRange(
            comp.Sport__c.toLowerCase(),
            comp.ESPN_League_ID__c,
            startDate,
            endDate,
            comp.Id
        );
        
        totalFixtures += fixturesCount;
        System.debug('✓ Synced ' + fixturesCount + ' fixtures for ' + comp.Name);
        
    } catch (Exception e) {
        totalErrors++;
        System.debug('✗ ERROR syncing ' + comp.Name + ': ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
}

System.debug('');
System.debug('=== ESPN Fixture Sync Completed ===');
System.debug('Total Competitions Processed: ' + competitions.size());
System.debug('Total Fixtures Synced: ' + totalFixtures);
System.debug('Total Errors: ' + totalErrors);
System.debug('Date: ' + DateTime.now());

// Query and display sample of synced fixtures
System.debug('');
System.debug('=== Sample of Synced Fixtures ===');

List<Match__c> recentFixtures = [
    SELECT Id, Name, Match_Date_Time__c, Status__c,
           Home_Team__r.Name, Away_Team__r.Name,
           Competition__r.Name
    FROM Match__c
    WHERE Match_Date_Time__c >= :startDate
    AND Match_Date_Time__c <= :endDate
    ORDER BY Match_Date_Time__c ASC
    LIMIT 10
];

for (Match__c match : recentFixtures) {
    System.debug(
        match.Match_Date_Time__c.format('yyyy-MM-dd HH:mm') + 
        ' | ' + match.Competition__r.Name + 
        ' | ' + match.Home_Team__r.Name + 
        ' vs ' + match.Away_Team__r.Name + 
        ' | ' + match.Status__c
    );
}

System.debug('');
System.debug('Total fixtures in date range: ' + recentFixtures.size());

