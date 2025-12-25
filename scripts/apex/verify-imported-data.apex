// Verify imported CSV test data
System.debug('\n===== IMPORTED DATA VERIFICATION =====\n');

// Query Seasons
List<Season__c> seasons = [SELECT Id, Season_Name__c, Sport__c, Status__c FROM Season__c ORDER BY Season_Name__c];
System.debug('✓ Seasons (' + seasons.size() + '):');
for (Season__c s : seasons) {
    System.debug('  - ' + s.Season_Name__c + ' (' + s.Sport__c + ') - ' + s.Status__c);
}

// Query Competitions
List<Competition__c> comps = [SELECT Id, Name, Sport__c, Season__r.Season_Name__c FROM Competition__c];
System.debug('\n✓ Competitions (' + comps.size() + '):');
for (Competition__c c : comps) {
    System.debug('  - ' + c.Name + ' (' + c.Sport__c + ') - Season: ' + c.Season__r.Season_Name__c);
}

// Query Teams
List<Account> teams = [SELECT Id, Name, Sport__c FROM Account WHERE Type = 'Club' ORDER BY Name];
System.debug('\n✓ Teams (' + teams.size() + '):');
for (Account t : teams) {
    System.debug('  - ' + t.Name + ' (' + t.Sport__c + ')');
}

// Query Players
List<Contact> players = [SELECT Id, Name, Position__c, Nationality__c FROM Contact ORDER BY LastName];
System.debug('\n✓ Players (' + players.size() + '):');
for (Contact p : players) {
    System.debug('  - ' + p.Name + ' (' + p.Position__c + ', ' + p.Nationality__c + ')');
}

// Query Matches
List<Match__c> matches = [SELECT Id, Name, Status__c, Home_Score_Final__c, Away_Score_Final__c 
                           FROM Match__c ORDER BY Match_Date_Time__c DESC];
System.debug('\n✓ Matches (' + matches.size() + '):');
for (Match__c m : matches) {
    System.debug('  - ' + m.Name + ': ' + m.Home_Score_Final__c + '-' + m.Away_Score_Final__c + ' (' + m.Status__c + ')');
}

// Query Player Stats
List<Player_Season_Stats__c> stats = [SELECT Id, Player__r.Name, Goals__c, Tries__c, Assists__c, Appearances__c 
                                        FROM Player_Season_Stats__c];
System.debug('\n✓ Player Season Stats (' + stats.size() + '):');
for (Player_Season_Stats__c ps : stats) {
    String statsStr = '';
    if (ps.Tries__c != null) statsStr += ps.Tries__c + ' tries, ' + ps.Goals__c + ' goals';
    if (ps.Goals__c != null && ps.Assists__c != null) statsStr += ps.Goals__c + ' goals, ' + ps.Assists__c + ' assists';
    System.debug('  - ' + ps.Player__r.Name + ': ' + statsStr + ' (' + ps.Appearances__c + ' apps)');
}

// Query Awards
List<Award__c> awards = [SELECT Id, Player__r.Name, Team__r.Name, Award_Type__c, Year__c 
                          FROM Award__c ORDER BY Year__c DESC];
System.debug('\n✓ Awards (' + awards.size() + '):');
for (Award__c a : awards) {
    String recipient = a.Player__c != null ? a.Player__r.Name : a.Team__r.Name;
    System.debug('  - ' + a.Award_Type__c + ': ' + recipient + ' (' + a.Year__c + ')');
}

// Query Articles
List<Article__c> articles = [SELECT Id, Heading__c, Sport_Type__c, Is_Published__c 
                              FROM Article__c];
System.debug('\n✓ Articles (' + articles.size() + '):');
for (Article__c art : articles) {
    System.debug('  - ' + art.Heading__c.left(60) + '...');
}

System.debug('\n===== VERIFICATION COMPLETE =====');

