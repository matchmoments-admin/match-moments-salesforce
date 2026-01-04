/**
 * Verify that professional records are marked appropriately
 * Checks matches, teams, and players synced from ESPN
 */

System.debug('=== VERIFYING PROFESSIONAL RECORDS ===');
System.debug('Date: ' + DateTime.now());
System.debug('');

// Date range: last 7 days
Date startDate = Date.today().addDays(-7);
Date endDate = Date.today();

System.debug('Date Range: ' + startDate + ' to ' + endDate);
System.debug('');

// 1. Check Premier League Competition
System.debug('=== STEP 1: Premier League Competition ===');
List<Competition__c> competitions = [
    SELECT Id, Name, ESPN_League_ID__c, Sport__c, Status__c
    FROM Competition__c
    WHERE ESPN_League_ID__c = 'eng.1'
    LIMIT 1
];

if (competitions.isEmpty()) {
    System.debug('✗ Premier League competition not found');
} else {
    Competition__c comp = competitions[0];
    System.debug('✓ Found: ' + comp.Name + ' (' + comp.Id + ')');
    System.debug('  Sport: ' + comp.Sport__c);
    System.debug('  Status: ' + comp.Status__c);
}
System.debug('');

// 2. Check Teams
System.debug('=== STEP 2: Premier League Teams ===');
List<Account> teams = [
    SELECT Id, Name, ESPN_Team_ID__c
    FROM Account
    WHERE ESPN_Team_ID__c != null
    ORDER BY Name
    LIMIT 25
];

System.debug('Found ' + teams.size() + ' teams with ESPN IDs:');
for (Account team : teams) {
    System.debug('  ✓ ' + team.Name + ' (ESPN ID: ' + team.ESPN_Team_ID__c + ')');
}
System.debug('');

// 3. Check Matches - Professional Level
System.debug('=== STEP 3: Professional Matches (Last Week) ===');
List<Match__c> professionalMatches = [
    SELECT Id, Name, Match_Level__c, Status__c, Match_Date_Time__c,
           Home_Team__r.Name, Away_Team__r.Name, Competition__r.Name, ESPN_Event_ID__c
    FROM Match__c
    WHERE Competition__r.ESPN_League_ID__c = 'eng.1'
    AND Match_Date_Time__c >= :startDate
    AND Match_Date_Time__c <= :endDate
    ORDER BY Match_Date_Time__c DESC
];

System.debug('Found ' + professionalMatches.size() + ' matches in date range:');
System.debug('');

Integer professionalCount = 0;
Integer nullCount = 0;
Integer otherCount = 0;

for (Match__c match : professionalMatches) {
    if (match.Match_Level__c == 'Professional') {
        professionalCount++;
        System.debug('  ✓ ' + match.Match_Date_Time__c.format('yyyy-MM-dd HH:mm') + 
                    ' | ' + match.Home_Team__r.Name + 
                    ' vs ' + match.Away_Team__r.Name + 
                    ' | Level: Professional | Status: ' + match.Status__c);
    } else if (match.Match_Level__c == null) {
        nullCount++;
        System.debug('  ⚠ ' + match.Match_Date_Time__c.format('yyyy-MM-dd HH:mm') + 
                    ' | ' + match.Home_Team__r.Name + 
                    ' vs ' + match.Away_Team__r.Name + 
                    ' | Level: NULL | Status: ' + match.Status__c);
    } else {
        otherCount++;
        System.debug('  ⚠ ' + match.Match_Date_Time__c.format('yyyy-MM-dd HH:mm') + 
                    ' | ' + match.Home_Team__r.Name + 
                    ' vs ' + match.Away_Team__r.Name + 
                    ' | Level: ' + match.Match_Level__c + ' | Status: ' + match.Status__c);
    }
}

System.debug('');
System.debug('=== MATCH LEVEL SUMMARY ===');
System.debug('Professional: ' + professionalCount + ' ✓');
System.debug('Null: ' + nullCount + (nullCount > 0 ? ' ⚠' : ''));
System.debug('Other: ' + otherCount + (otherCount > 0 ? ' ⚠' : ''));
System.debug('');

// 4. Check Players
System.debug('=== STEP 4: Premier League Players ===');
List<Contact> players = [
    SELECT Id, Name, ESPN_Player_ID__c, Account.Name
    FROM Contact
    WHERE ESPN_Player_ID__c != null
    AND Account.ESPN_Team_ID__c != null
    ORDER BY Account.Name, Name
    LIMIT 50
];

System.debug('Found ' + players.size() + ' players with ESPN IDs (showing first 50):');
Map<String, Integer> playersByTeam = new Map<String, Integer>();
for (Contact player : players) {
    String teamName = player.Account.Name;
    if (!playersByTeam.containsKey(teamName)) {
        playersByTeam.put(teamName, 0);
    }
    playersByTeam.put(teamName, playersByTeam.get(teamName) + 1);
}

for (String teamName : playersByTeam.keySet()) {
    System.debug('  ✓ ' + teamName + ': ' + playersByTeam.get(teamName) + ' players');
}
System.debug('');

// 5. Overall Summary
System.debug('=== OVERALL SUMMARY ===');
System.debug('Competition: ' + (competitions.isEmpty() ? '✗ Not found' : '✓ Found'));
System.debug('Teams: ' + teams.size() + ' teams with ESPN IDs');
System.debug('Matches: ' + professionalMatches.size() + ' matches in last week');
System.debug('  - Professional: ' + professionalCount + (professionalCount == professionalMatches.size() ? ' ✓' : ' ⚠'));
System.debug('  - Null: ' + nullCount + (nullCount == 0 ? ' ✓' : ' ⚠'));
System.debug('Players: ' + players.size() + ' players with ESPN IDs (sample)');
System.debug('');

if (professionalCount == professionalMatches.size() && nullCount == 0) {
    System.debug('✅ SUCCESS: All matches are marked as Professional');
} else {
    System.debug('⚠ WARNING: Some matches need Match_Level__c set to Professional');
}

System.debug('=== VERIFICATION COMPLETE ===');

