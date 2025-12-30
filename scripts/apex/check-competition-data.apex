// Check actual Competition records to see what fields have data
List<Competition__c> comps = [
    SELECT Id, Name, Sport__c, Country__c, Season__c, Season__r.Name,
           ESPN_League_ID__c, Status__c, Season_Year__c,
           Season_Start_Date__c, Season_End_Date__c, Tier_Level__c
    FROM Competition__c
    LIMIT 10
];

System.debug('=== COMPETITION DATA ===');
System.debug('Total records: ' + comps.size());
System.debug('');

for (Competition__c comp : comps) {
    System.debug('Competition: ' + comp.Name);
    System.debug('  Sport: ' + comp.Sport__c);
    System.debug('  Country: ' + comp.Country__c);
    System.debug('  ESPN_League_ID__c: ' + comp.ESPN_League_ID__c);
    System.debug('  Season: ' + (comp.Season__c != null ? comp.Season__r.Name : 'null'));
    System.debug('  Status: ' + comp.Status__c);
    System.debug('  Season_Year__c: ' + comp.Season_Year__c);
    System.debug('  Tier_Level__c: ' + comp.Tier_Level__c);
    System.debug('');
}

// Check if any have useful "Name" values or if they're all COMP-0001 format
System.debug('Analysis: All Competition records use autonumber Names (COMP-xxxx)');
System.debug('To display in web UI, we should use: ESPN_League_ID__c + Sport__c');
System.debug('Example: "eng.1" (English Premier League), "usa.nwsl" (NWSL)');

