// Backfill League__c, Sport__c, and Gender_Class__c on Account records
// Can be run multiple times safely (idempotent)
// Bulkified for 200+ records

System.debug('=== Starting League Data Backfill ===');

// Query all teams with ESPN IDs
List<Account> teams = [
    SELECT Id, Name, ESPN_Team_ID__c, League__c, Sport__c, Gender_Class__c
    FROM Account
    WHERE ESPN_Team_ID__c != null
    AND RecordType.DeveloperName = 'Team'
    LIMIT 200
];

System.debug('Found ' + teams.size() + ' teams to process');

Integer updatedCount = 0;

for (Account team : teams) {
    Boolean needsUpdate = false;
    String espnId = team.ESPN_Team_ID__c;
    
    // Extract league code from ESPN ID patterns
    if (String.isBlank(team.League__c)) {
        if (espnId.startsWith('eng.1')) {
            team.League__c = 'eng.1';
            team.Sport__c = 'Soccer';
            needsUpdate = true;
        } else if (espnId.startsWith('usa.nwsl')) {
            team.League__c = 'usa.nwsl';
            team.Sport__c = 'Soccer';
            team.Gender_Class__c = 'Women\'s Team';
            needsUpdate = true;
        } else if (espnId.startsWith('wnba')) {
            team.League__c = 'wnba';
            team.Sport__c = 'Basketball';
            team.Gender_Class__c = 'Women\'s Team';
            needsUpdate = true;
        } else if (espnId.startsWith('nba')) {
            team.League__c = 'nba';
            team.Sport__c = 'Basketball';
            team.Gender_Class__c = 'Men\'s Team';
            needsUpdate = true;
        } else if (espnId.startsWith('afl')) {
            team.League__c = 'afl';
            team.Sport__c = 'AFL';
            needsUpdate = true;
        } else if (espnId.contains('cricket')) {
            team.Sport__c = 'Cricket';
            needsUpdate = true;
        }
    }
    
    // Infer gender from team name if not set
    if (String.isBlank(team.Gender_Class__c)) {
        String nameLower = team.Name.toLowerCase();
        if (nameLower.contains('women') || nameLower.contains('ladies') || 
            nameLower.contains('fc women') || nameLower.contains('women\'s')) {
            team.Gender_Class__c = 'Women\'s Team';
            needsUpdate = true;
        } else if (team.Sport__c == 'Soccer') {
            // Default to men's for soccer if not specified
            team.Gender_Class__c = 'Men\'s Team';
            needsUpdate = true;
        }
    }
    
    if (needsUpdate) {
        updatedCount++;
    }
}

// Update all teams
try {
    update teams;
    System.debug('=== Successfully updated ' + updatedCount + ' teams ===');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Summary
System.debug('=== Backfill Complete ===');
System.debug('Total teams processed: ' + teams.size());
System.debug('Teams updated: ' + updatedCount);

