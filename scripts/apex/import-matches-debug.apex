// Import Matches with Debug Output
System.debug('=== Importing Matches ===');

// Get Season
List<Season__c> seasons = [SELECT Id, Season_Name__c FROM Season__c WHERE Season_Name__c = '2024-2025'];
System.debug('Found ' + seasons.size() + ' seasons');
if (seasons.isEmpty()) {
    System.debug('ERROR: No season found!');
    return;
}
Season__c season = seasons[0];
System.debug('Using Season: ' + season.Id);

// Get Competitions
Map<String, Competition__c> compMap = new Map<String, Competition__c>();
for (Competition__c comp : [SELECT Id, ESPN_League_ID__c, Name FROM Competition__c]) {
    compMap.put(comp.ESPN_League_ID__c, comp);
    System.debug('Found Competition: ' + comp.ESPN_League_ID__c + ' = ' + comp.Id);
}
System.debug('Total Competitions: ' + compMap.size());

if (!compMap.containsKey('eng.1')) {
    System.debug('ERROR: Premier League competition not found!');
}
if (!compMap.containsKey('uefa.champions')) {
    System.debug('ERROR: Champions League competition not found!');
}

// Get Teams by Name
Map<String, Account> teamMap = new Map<String, Account>();
for (Account team : [SELECT Id, Name, ESPN_Team_ID__c FROM Account WHERE ESPN_Team_ID__c != null LIMIT 50]) {
    teamMap.put(team.Name, team);
    System.debug('Found Team: ' + team.Name + ' = ' + team.Id);
}
System.debug('Total Teams: ' + teamMap.size());

// Check specific teams
List<String> requiredTeams = new List<String>{'Chelsea', 'Aston Villa', 'Liverpool', 'Manchester City', 'Arsenal', 'Monaco'};
for (String teamName : requiredTeams) {
    if (!teamMap.containsKey(teamName)) {
        System.debug('WARNING: Team not found: ' + teamName);
    }
}

if (compMap.isEmpty() || teamMap.size() < 10) {
    System.debug('ERROR: Not enough data to proceed. Stopping.');
    return;
}

List<Match__c> matches = new List<Match__c>();

// Sample Premier League Matches (only if all data exists)
if (compMap.containsKey('eng.1') && teamMap.containsKey('Chelsea') && teamMap.containsKey('Aston Villa')) {
    matches.add(new Match__c(
        Competition__c = compMap.get('eng.1').Id, 
        Season__c = season.Id, 
        Home_Team__c = teamMap.get('Chelsea').Id, 
        Away_Team__c = teamMap.get('Aston Villa').Id, 
        Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 1, 14, 0, 0), 
        Status__c = 'Completed', 
        Home_Score_Final__c = 3, 
        Away_Score_Final__c = 0, 
        Venue__c = 'Stamford Bridge', 
        Attendance__c = 39866
    ));
    System.debug('Added match: Chelsea vs Aston Villa');
}

if (compMap.containsKey('eng.1') && teamMap.containsKey('Liverpool') && teamMap.containsKey('Manchester City')) {
    matches.add(new Match__c(
        Competition__c = compMap.get('eng.1').Id, 
        Season__c = season.Id, 
        Home_Team__c = teamMap.get('Liverpool').Id, 
        Away_Team__c = teamMap.get('Manchester City').Id, 
        Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 1, 16, 30, 0), 
        Status__c = 'Completed', 
        Home_Score_Final__c = 2, 
        Away_Score_Final__c = 0, 
        Venue__c = 'Anfield', 
        Attendance__c = 60343
    ));
    System.debug('Added match: Liverpool vs Manchester City');
}

if (compMap.containsKey('uefa.champions') && teamMap.containsKey('Arsenal') && teamMap.containsKey('Monaco')) {
    matches.add(new Match__c(
        Competition__c = compMap.get('uefa.champions').Id, 
        Season__c = season.Id, 
        Home_Team__c = teamMap.get('Arsenal').Id, 
        Away_Team__c = teamMap.get('Monaco').Id, 
        Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 11, 20, 0, 0), 
        Status__c = 'Completed', 
        Home_Score_Final__c = 3, 
        Away_Score_Final__c = 0, 
        Venue__c = 'Emirates Stadium', 
        Attendance__c = 60278
    ));
    System.debug('Added match: Arsenal vs Monaco (UCL)');
}

System.debug('Attempting to insert ' + matches.size() + ' matches');

if (matches.isEmpty()) {
    System.debug('ERROR: No matches to insert!');
    return;
}

try {
    insert matches;
    System.debug('✓ Successfully inserted ' + matches.size() + ' matches');
} catch (Exception e) {
    System.debug('ERROR inserting matches: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

