// Import Matches Only
System.debug('=== Importing Matches ===');

// Get Season
Season__c season = [SELECT Id FROM Season__c WHERE Season_Name__c = '2024-2025' LIMIT 1];

// Get Competitions
Map<String, Competition__c> compMap = new Map<String, Competition__c>();
for (Competition__c comp : [SELECT Id, ESPN_League_ID__c FROM Competition__c]) {
    compMap.put(comp.ESPN_League_ID__c, comp);
}

// Get Teams by Name
Map<String, Account> teamMap = new Map<String, Account>();
for (Account team : [SELECT Id, Name FROM Account WHERE Type = 'Team']) {
    teamMap.put(team.Name, team);
}

System.debug('Found ' + teamMap.size() + ' teams');
System.debug('Found ' + compMap.size() + ' competitions');

List<Match__c> matches = new List<Match__c>();

// Sample Premier League Matches
matches.add(new Match__c(Competition__c = compMap.get('eng.1').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Chelsea').Id, Away_Team__c = teamMap.get('Aston Villa').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 1, 14, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 3, Away_Score_Final__c = 0, Venue__c = 'Stamford Bridge', Attendance__c = 39866));
matches.add(new Match__c(Competition__c = compMap.get('eng.1').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Manchester United').Id, Away_Team__c = teamMap.get('Everton').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 1, 14, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 4, Away_Score_Final__c = 0, Venue__c = 'Old Trafford', Attendance__c = 73783));
matches.add(new Match__c(Competition__c = compMap.get('eng.1').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Liverpool').Id, Away_Team__c = teamMap.get('Manchester City').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 1, 16, 30, 0), Status__c = 'Finished', Home_Score_Final__c = 2, Away_Score_Final__c = 0, Venue__c = 'Anfield', Attendance__c = 60343));
matches.add(new Match__c(Competition__c = compMap.get('eng.1').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Arsenal').Id, Away_Team__c = teamMap.get('Manchester United').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 4, 20, 15, 0), Status__c = 'Finished', Home_Score_Final__c = 2, Away_Score_Final__c = 0, Venue__c = 'Emirates Stadium', Attendance__c = 60383));
matches.add(new Match__c(Competition__c = compMap.get('eng.1').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Tottenham Hotspur').Id, Away_Team__c = teamMap.get('Liverpool').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 22, 16, 30, 0), Status__c = 'Finished', Home_Score_Final__c = 3, Away_Score_Final__c = 6, Venue__c = 'Tottenham Hotspur Stadium', Attendance__c = 61595));

// Champions League Matches
matches.add(new Match__c(Competition__c = compMap.get('uefa.champions').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Arsenal').Id, Away_Team__c = teamMap.get('Monaco').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 11, 20, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 3, Away_Score_Final__c = 0, Venue__c = 'Emirates Stadium', Attendance__c = 60278));
matches.add(new Match__c(Competition__c = compMap.get('uefa.champions').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Aston Villa').Id, Away_Team__c = teamMap.get('RB Leipzig').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 10, 20, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 3, Away_Score_Final__c = 2, Venue__c = 'Villa Park', Attendance__c = 41905));
matches.add(new Match__c(Competition__c = compMap.get('uefa.champions').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Liverpool').Id, Away_Team__c = teamMap.get('Girona').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 10, 20, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 1, Away_Score_Final__c = 0, Venue__c = 'Anfield', Attendance__c = 59762));
matches.add(new Match__c(Competition__c = compMap.get('uefa.champions').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Inter Milan').Id, Away_Team__c = teamMap.get('Bayer Leverkusen').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 10, 20, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 6, Away_Score_Final__c = 0, Venue__c = 'San Siro', Attendance__c = 70123));
matches.add(new Match__c(Competition__c = compMap.get('uefa.champions').Id, Season__c = season.Id, Home_Team__c = teamMap.get('Barcelona').Id, Away_Team__c = teamMap.get('Borussia Dortmund').Id, Match_Date_Time__c = DateTime.newInstanceGmt(2024, 12, 11, 20, 0, 0), Status__c = 'Finished', Home_Score_Final__c = 3, Away_Score_Final__c = 2, Venue__c = 'Camp Nou', Attendance__c = 48502));

insert matches;
System.debug('✓ Inserted ' + matches.size() + ' matches successfully');

