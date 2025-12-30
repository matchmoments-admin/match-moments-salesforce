// Check Match__c records
System.debug('=== MATCH__C DATA ===');
List<Match__c> matches = [
    SELECT Id, Name, Home_Team__c, Home_Team__r.Name, Away_Team__c, Away_Team__r.Name,
           Competition__c, Competition__r.Name, Season__c, Season__r.Name,
           Match_Date_Time__c, Status__c, Home_Score_Final__c, Away_Score_Final__c,
           ESPN_Event_ID__c, Neutral_Venue__c
    FROM Match__c
    LIMIT 5
];

for (Match__c m : matches) {
    System.debug('Match: ' + m.Name);
    System.debug('  Home: ' + (m.Home_Team__c != null ? m.Home_Team__r.Name : 'null'));
    System.debug('  Away: ' + (m.Away_Team__c != null ? m.Away_Team__r.Name : 'null'));
    System.debug('  Competition: ' + (m.Competition__c != null ? m.Competition__r.Name : 'null'));
    System.debug('  Season: ' + (m.Season__c != null ? m.Season__r.Name : 'null'));
    System.debug('  Status: ' + m.Status__c);
    System.debug('  Score: ' + m.Home_Score_Final__c + ' - ' + m.Away_Score_Final__c);
    System.debug('');
}

// Check Account (Team) records
System.debug('=== ACCOUNT (TEAMS) DATA ===');
List<Account> teams = [
    SELECT Id, Name, ESPN_Team_ID__c, Abbreviation__c, 
           Sport__c, Team_Logo_URL__c
    FROM Account
    WHERE ESPN_Team_ID__c != null
    LIMIT 5
];

for (Account t : teams) {
    System.debug('Team: ' + t.Name);
    System.debug('  ESPN_Team_ID__c: ' + t.ESPN_Team_ID__c);
    System.debug('  Abbreviation__c: ' + t.Abbreviation__c);
    System.debug('  Sport__c: ' + t.Sport__c);
    System.debug('  Team_Logo_URL__c: ' + (t.Team_Logo_URL__c != null ? 'Present' : 'null'));
    System.debug('');
}

// Check Contact (Player) records
System.debug('=== CONTACT (PLAYERS) DATA ===');
List<Contact> players = [
    SELECT Id, Name, ESPN_Player_ID__c, Position__c, Jersey_Number__c,
           AccountId, Account.Name, Profile_Image_URL__c
    FROM Contact
    WHERE ESPN_Player_ID__c != null
    LIMIT 5
];

for (Contact p : players) {
    System.debug('Player: ' + p.Name);
    System.debug('  ESPN_Player_ID__c: ' + p.ESPN_Player_ID__c);
    System.debug('  Team: ' + (p.AccountId != null ? p.Account.Name : 'null'));
    System.debug('  Position: ' + p.Position__c);
    System.debug('  Jersey: ' + p.Jersey_Number__c);
    System.debug('');
}

