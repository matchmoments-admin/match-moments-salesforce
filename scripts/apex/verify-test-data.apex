/**
 * Verify Test Data Import
 * Shows what data was successfully imported
 */

System.debug('========================================');
System.debug('Test Data Verification Report');
System.debug('========================================\n');

try {
    // Query Seasons
    List<Season__c> seasons = [SELECT Id, Season_Name__c, Sport__c, Status__c, Start_Date__c, End_Date__c 
                                FROM Season__c 
                                ORDER BY Season_Name__c];
    System.debug('📅 SEASONS (' + seasons.size() + ' records):');
    for (Season__c s : seasons) {
        System.debug('  • ' + s.Season_Name__c + ' (' + s.Sport__c + ') - ' + s.Status__c);
        System.debug('    Dates: ' + s.Start_Date__c + ' to ' + s.End_Date__c);
    }
    
    // Query Competitions
    List<Competition__c> comps = [SELECT Id, Name, ESPN_League_ID__c, Sport__c, Competition_Type__c, Country__c
                                   FROM Competition__c 
                                   ORDER BY Name];
    System.debug('\n🏆 COMPETITIONS (' + comps.size() + ' records):');
    for (Competition__c c : comps) {
        System.debug('  • ' + c.Name + ' (' + c.ESPN_League_ID__c + ')');
        System.debug('    Type: ' + c.Competition_Type__c + ' | Country: ' + c.Country__c);
    }
    
    // Query Teams
    List<Account> teams = [SELECT Id, Name, ESPN_Team_ID__c, Sport__c, Venue_Name__c 
                           FROM Account 
                           WHERE ESPN_Team_ID__c != null 
                           ORDER BY Name 
                           LIMIT 10];
    System.debug('\n⚽ TEAMS (' + [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null] + ' records, showing first 10):');
    for (Account t : teams) {
        System.debug('  • ' + t.Name + ' (ESPN: ' + t.ESPN_Team_ID__c + ')');
        System.debug('    Venue: ' + t.Venue_Name__c);
    }
    
    // Query Players
    List<Contact> players = [SELECT Id, FirstName, LastName, ESPN_Player_ID__c, Position__c, Nationality__c 
                             FROM Contact 
                             WHERE ESPN_Player_ID__c != null 
                             ORDER BY LastName 
                             LIMIT 10];
    System.debug('\n👤 PLAYERS (' + [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null] + ' records, showing first 10):');
    for (Contact p : players) {
        System.debug('  • ' + p.FirstName + ' ' + p.LastName + ' (' + p.Position__c + ')');
        System.debug('    ESPN ID: ' + p.ESPN_Player_ID__c + ' | Nationality: ' + p.Nationality__c);
    }
    
    // Query Matches
    Integer matchCount = [SELECT COUNT() FROM Match__c];
    System.debug('\n🎮 MATCHES: ' + matchCount + ' records');
    
    // Query Match Periods
    Integer periodCount = [SELECT COUNT() FROM Match_Period__c];
    System.debug('⏱️  MATCH PERIODS: ' + periodCount + ' records');
    
    // Query Player Stats
    Integer playerStatsCount = [SELECT COUNT() FROM Player_Season_Stats__c];
    System.debug('📊 PLAYER SEASON STATS: ' + playerStatsCount + ' records');
    
    // Query Team Stats
    Integer teamStatsCount = [SELECT COUNT() FROM Team_Season_Stats__c];
    System.debug('📈 TEAM SEASON STATS: ' + teamStatsCount + ' records');
    
    System.debug('\n========================================');
    System.debug('✅ VERIFICATION COMPLETE');
    System.debug('========================================');
    System.debug('\nSummary:');
    System.debug('  • ' + seasons.size() + ' Season(s)');
    System.debug('  • ' + comps.size() + ' Competition(s)');
    System.debug('  • ' + [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null] + ' Team(s)');
    System.debug('  • ' + [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null] + ' Player(s)');
    System.debug('  • ' + matchCount + ' Match(es)');
    System.debug('  • ' + periodCount + ' Match Period(s)');
    System.debug('  • ' + playerStatsCount + ' Player Stat(s)');
    System.debug('  • ' + teamStatsCount + ' Team Stat(s)');
    System.debug('\n✨ All test data verified successfully!');
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
    throw e;
}

