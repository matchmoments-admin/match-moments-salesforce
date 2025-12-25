// Check Premier League sync results
System.debug('=== Premier League Sync Results ===');
System.debug('');

// Check job status
Scheduled_Process__c job = [
    SELECT Name, Last_Sync_Status__c, Last_Sync_Records_Processed__c,
           Last_Sync_Errors__c, Last_Sync_Duration_Seconds__c, LastRunTime__c
    FROM Scheduled_Process__c
    WHERE League_Code__c = 'eng.1' AND ClassName__c = 'ESPNSyncQueueable'
    ORDER BY LastModifiedDate DESC
    LIMIT 1
];

System.debug('--- Job Status ---');
System.debug('Name: ' + job.Name);
System.debug('Status: ' + job.Last_Sync_Status__c);
System.debug('Records Processed: ' + job.Last_Sync_Records_Processed__c);
System.debug('Duration: ' + job.Last_Sync_Duration_Seconds__c + ' seconds');
System.debug('Errors: ' + job.Last_Sync_Errors__c);
System.debug('Last Run: ' + job.LastRunTime__c);
System.debug('');

// Check teams synced
List<Account> teams = [
    SELECT Name, ESPN_Team_ID__c, Team_Short_Name__c, Stadium_Name__c
    FROM Account 
    WHERE ESPN_Team_ID__c != null 
    ORDER BY Name
];

System.debug('--- Teams Synced (' + teams.size() + ') ---');
for (Account t : teams) {
    System.debug('  - ' + t.Name + ' (' + t.Team_Short_Name__c + ')' + (t.Stadium_Name__c != null ? ' - ' + t.Stadium_Name__c : ''));
}
System.debug('');

// Check players synced
Integer totalPlayers = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
System.debug('--- Players Synced ---');
System.debug('Total Players: ' + totalPlayers);
System.debug('');

// Show sample players from a few teams
List<Contact> samplePlayers = [
    SELECT FirstName, LastName, Account.Name, Position__c, Jersey_Number__c
    FROM Contact 
    WHERE ESPN_Player_ID__c != null 
    ORDER BY Account.Name, LastName
    LIMIT 20
];

System.debug('Sample Players (first 20):');
for (Contact p : samplePlayers) {
    String jersey = p.Jersey_Number__c != null ? ' #' + p.Jersey_Number__c.intValue() : '';
    String position = p.Position__c != null ? ' - ' + p.Position__c : '';
    System.debug('  - ' + p.FirstName + ' ' + p.LastName + jersey + position + ' (' + p.Account.Name + ')');
}
System.debug('');

// Check fixtures synced
List<Fixture__c> fixtures = [
    SELECT Name, Home_Team__r.Name, Away_Team__r.Name, Fixture_Date_Time__c, Status__c
    FROM Fixture__c 
    WHERE Competition__r.ESPN_League_ID__c = 'eng.1' 
    ORDER BY Fixture_Date_Time__c
];

System.debug('--- Fixtures Synced (' + fixtures.size() + ') ---');
for (Fixture__c f : fixtures) {
    String dateStr = f.Fixture_Date_Time__c != null ? f.Fixture_Date_Time__c.format('MMM dd, yyyy HH:mm') : 'TBD';
    System.debug('  - ' + f.Home_Team__r.Name + ' vs ' + f.Away_Team__r.Name + ' - ' + dateStr + ' (' + f.Status__c + ')');
}
System.debug('');

// Summary
System.debug('=== SUMMARY ===');
System.debug('✅ Teams: ' + teams.size());
System.debug('✅ Players: ' + totalPlayers);
System.debug('✅ Fixtures: ' + fixtures.size());
System.debug('✅ Job Status: ' + job.Last_Sync_Status__c);
System.debug('✅ Duration: ' + job.Last_Sync_Duration_Seconds__c + ' seconds');
System.debug('');


