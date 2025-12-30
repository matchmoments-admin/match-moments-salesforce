/**
 * Delete existing test data before import
 */

System.debug('========================================');
System.debug('Deleting Existing Test Data');
System.debug('========================================\n');

try {
    // Delete in reverse order of dependencies
    
    // Delete Player Season Stats
    List<Player_Season_Stats__c> playerStats = [SELECT Id FROM Player_Season_Stats__c];
    if (!playerStats.isEmpty()) {
        delete playerStats;
        System.debug('✓ Deleted ' + playerStats.size() + ' Player Season Stats');
    }
    
    // Delete Team Season Stats
    List<Team_Season_Stats__c> teamStats = [SELECT Id FROM Team_Season_Stats__c];
    if (!teamStats.isEmpty()) {
        delete teamStats;
        System.debug('✓ Deleted ' + teamStats.size() + ' Team Season Stats');
    }
    
    // Delete Match Periods
    List<Match_Period__c> periods = [SELECT Id FROM Match_Period__c];
    if (!periods.isEmpty()) {
        delete periods;
        System.debug('✓ Deleted ' + periods.size() + ' Match Periods');
    }
    
    // Delete Matches
    List<Match__c> matches = [SELECT Id FROM Match__c];
    if (!matches.isEmpty()) {
        delete matches;
        System.debug('✓ Deleted ' + matches.size() + ' Matches');
    }
    
    // Delete Fixtures (old Match object)
    List<Fixture__c> fixtures = [SELECT Id FROM Fixture__c];
    if (!fixtures.isEmpty()) {
        delete fixtures;
        System.debug('✓ Deleted ' + fixtures.size() + ' Fixtures');
    }
    
    // Delete Players (Contacts)
    List<Contact> players = [SELECT Id FROM Contact WHERE ESPN_Player_ID__c != null];
    if (!players.isEmpty()) {
        delete players;
        System.debug('✓ Deleted ' + players.size() + ' Players');
    }
    
    // Delete Teams (Accounts with ESPN_Team_ID)
    List<Account> teams = [SELECT Id FROM Account WHERE ESPN_Team_ID__c != null];
    if (!teams.isEmpty()) {
        delete teams;
        System.debug('✓ Deleted ' + teams.size() + ' Teams');
    }
    
    // Delete Competitions
    List<Competition__c> comps = [SELECT Id FROM Competition__c];
    if (!comps.isEmpty()) {
        delete comps;
        System.debug('✓ Deleted ' + comps.size() + ' Competitions');
    }
    
    // Delete Seasons
    List<Season__c> seasons = [SELECT Id FROM Season__c];
    if (!seasons.isEmpty()) {
        delete seasons;
        System.debug('✓ Deleted ' + seasons.size() + ' Seasons');
    }
    
    System.debug('\n✅ All test data deleted successfully');
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
    throw e;
}

