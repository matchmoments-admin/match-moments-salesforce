/**
 * Complete Test Data Import - ALL Records
 * Imports: 40 Teams, 53 Matches, with all fields including League__c and Gender_Class__c
 */

System.debug('=== Starting COMPLETE Test Data Import ===');

// Get Season
Season__c season = [SELECT Id FROM Season__c WHERE Season_Name__c = '2024-2025' LIMIT 1];
System.debug('✓ Found Season: ' + season.Id);

// Get Competitions
Map<String, Competition__c> compMap = new Map<String, Competition__c>();
for (Competition__c comp : [SELECT Id, ESPN_League_ID__c FROM Competition__c]) {
    compMap.put(comp.ESPN_League_ID__c, comp);
}
System.debug('✓ Found ' + compMap.size() + ' competitions');

// Delete existing teams to avoid duplicates (optional - comment out if you want to keep existing)
// List<Account> existingTeams = [SELECT Id FROM Account WHERE ESPN_Team_ID__c != null];
// delete existingTeams;
// System.debug('Deleted ' + existingTeams.size() + ' existing teams');

// Import ALL 40 Teams with ALL fields
List<Account> teams = new List<Account>();

// Premier League Teams (20)
teams.add(new Account(Name='Liverpool', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='LIV', ESPN_Team_ID__c='364', Team_Primary_Color__c='#C8102E', Venue_Name__c='Anfield'));
teams.add(new Account(Name='Arsenal', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='ARS', ESPN_Team_ID__c='359', Team_Primary_Color__c='#EF0107', Venue_Name__c='Emirates Stadium'));
teams.add(new Account(Name='Chelsea', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='CHE', ESPN_Team_ID__c='363', Team_Primary_Color__c='#034694', Venue_Name__c='Stamford Bridge'));
teams.add(new Account(Name='Manchester City', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='MCI', ESPN_Team_ID__c='382', Team_Primary_Color__c='#6CABDD', Venue_Name__c='Etihad Stadium'));
teams.add(new Account(Name='Manchester United', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='MUN', ESPN_Team_ID__c='360', Team_Primary_Color__c='#DA291C', Venue_Name__c='Old Trafford'));
teams.add(new Account(Name='Tottenham Hotspur', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='TOT', ESPN_Team_ID__c='367', Team_Primary_Color__c='#132257', Venue_Name__c='Tottenham Hotspur Stadium'));
teams.add(new Account(Name='Newcastle United', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='NEW', ESPN_Team_ID__c='361', Team_Primary_Color__c='#241F20', Venue_Name__c='St James\' Park'));
teams.add(new Account(Name='Aston Villa', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='AVL', ESPN_Team_ID__c='362', Team_Primary_Color__c='#670E36', Venue_Name__c='Villa Park'));
teams.add(new Account(Name='Brighton & Hove Albion', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='BHA', ESPN_Team_ID__c='331', Team_Primary_Color__c='#0057B8', Venue_Name__c='Amex Stadium'));
teams.add(new Account(Name='Nottingham Forest', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='NFO', ESPN_Team_ID__c='393', Team_Primary_Color__c='#DD0000', Venue_Name__c='City Ground'));
teams.add(new Account(Name='Everton', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='EVE', ESPN_Team_ID__c='368', Team_Primary_Color__c='#003399', Venue_Name__c='Goodison Park'));
teams.add(new Account(Name='Fulham', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='FUL', ESPN_Team_ID__c='370', Team_Primary_Color__c='#FFFFFF', Venue_Name__c='Craven Cottage'));
teams.add(new Account(Name='Brentford', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='BRE', ESPN_Team_ID__c='337', Team_Primary_Color__c='#D20000', Venue_Name__c='Gtech Community Stadium'));
teams.add(new Account(Name='Crystal Palace', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='CRY', ESPN_Team_ID__c='384', Team_Primary_Color__c='#1B458F', Venue_Name__c='Selhurst Park'));
teams.add(new Account(Name='West Ham United', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='WHU', ESPN_Team_ID__c='371', Team_Primary_Color__c='#7A263A', Venue_Name__c='London Stadium'));
teams.add(new Account(Name='AFC Bournemouth', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='BOU', ESPN_Team_ID__c='349', Team_Primary_Color__c='#DA291C', Venue_Name__c='Vitality Stadium'));
teams.add(new Account(Name='Leicester City', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='LEI', ESPN_Team_ID__c='375', Team_Primary_Color__c='#003090', Venue_Name__c='King Power Stadium'));
teams.add(new Account(Name='Ipswich Town', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='IPS', ESPN_Team_ID__c='373', Team_Primary_Color__c='#0000FF', Venue_Name__c='Portman Road'));
teams.add(new Account(Name='Wolverhampton Wanderers', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='WOL', ESPN_Team_ID__c='380', Team_Primary_Color__c='#FDB913', Venue_Name__c='Molineux Stadium'));
teams.add(new Account(Name='Southampton', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='eng.1', Abbreviation__c='SOU', ESPN_Team_ID__c='376', Team_Primary_Color__c='#D71920', Venue_Name__c='St Mary\'s Stadium'));

// Champions League Teams (20)
teams.add(new Account(Name='AC Milan', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='MIL', ESPN_Team_ID__c='103', Team_Primary_Color__c='#FB090B', Venue_Name__c='San Siro'));
teams.add(new Account(Name='Inter Milan', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='INT', ESPN_Team_ID__c='108', Team_Primary_Color__c='#0068A8', Venue_Name__c='San Siro'));
teams.add(new Account(Name='Paris Saint-Germain', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='PSG', ESPN_Team_ID__c='160', Team_Primary_Color__c='#004170', Venue_Name__c='Parc des Princes'));
teams.add(new Account(Name='Real Madrid', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='RMA', ESPN_Team_ID__c='86', Team_Primary_Color__c='#FEBE10', Venue_Name__c='Santiago Bernabéu'));
teams.add(new Account(Name='Bayern München', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='BAY', ESPN_Team_ID__c='132', Team_Primary_Color__c='#DC052D', Venue_Name__c='Allianz Arena'));
teams.add(new Account(Name='Barcelona', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='BAR', ESPN_Team_ID__c='83', Team_Primary_Color__c='#A50044', Venue_Name__c='Camp Nou'));
teams.add(new Account(Name='Sporting CP', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='SCP', ESPN_Team_ID__c='184', Team_Primary_Color__c='#008B45', Venue_Name__c='José Alvalade Stadium'));
teams.add(new Account(Name='Monaco', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='MON', ESPN_Team_ID__c='174', Team_Primary_Color__c='#E2001A', Venue_Name__c='Stade Louis II'));
teams.add(new Account(Name='GNK Dinamo Zagreb', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='DIN', ESPN_Team_ID__c='2446', Team_Primary_Color__c='#004B9E', Venue_Name__c='Maksimir Stadium'));
teams.add(new Account(Name='Girona', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='GIR', ESPN_Team_ID__c='93', Team_Primary_Color__c='#CC0000', Venue_Name__c='Estadi Montilivi'));
teams.add(new Account(Name='Celtic', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='CEL', ESPN_Team_ID__c='295', Team_Primary_Color__c='#007A33', Venue_Name__c='Celtic Park'));
teams.add(new Account(Name='Shakhtar Donetsk', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='SHA', ESPN_Team_ID__c='623', Team_Primary_Color__c='#FF6600', Venue_Name__c='Donbass Arena'));
teams.add(new Account(Name='Bologna', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='BOL', ESPN_Team_ID__c='104', Team_Primary_Color__c='#0033CC', Venue_Name__c='Stadio Renato Dall\'Ara'));
teams.add(new Account(Name='Juventus', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='JUV', ESPN_Team_ID__c='111', Team_Primary_Color__c='#000000', Venue_Name__c='Allianz Stadium'));
teams.add(new Account(Name='RB Leipzig', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='RBL', ESPN_Team_ID__c='147', Team_Primary_Color__c='#DD0000', Venue_Name__c='Red Bull Arena'));
teams.add(new Account(Name='Club Brugge', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='BRU', ESPN_Team_ID__c='300', Team_Primary_Color__c='#003CA6', Venue_Name__c='Jan Breydel Stadium'));
teams.add(new Account(Name='Atalanta', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='ATA', ESPN_Team_ID__c='102', Team_Primary_Color__c='#1D2F5F', Venue_Name__c='Gewiss Stadium'));
teams.add(new Account(Name='Young Boys', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='YB', ESPN_Team_ID__c='343', Team_Primary_Color__c='#FFD900', Venue_Name__c='Wankdorf Stadium'));
teams.add(new Account(Name='Crvena Zvezda', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='CZV', ESPN_Team_ID__c='619', Team_Primary_Color__c='#D90007', Venue_Name__c='Rajko Mitić Stadium'));
teams.add(new Account(Name='Slovan Bratislava', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='SLO', ESPN_Team_ID__c='647', Team_Primary_Color__c='#0054A6', Venue_Name__c='Tehelné pole'));

// Additional Champions League teams needed for matches
teams.add(new Account(Name='Borussia Dortmund', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='BVB', ESPN_Team_ID__c='124', Team_Primary_Color__c='#FDE100', Venue_Name__c='Signal Iduna Park'));
teams.add(new Account(Name='Bayer Leverkusen', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='B04', ESPN_Team_ID__c='131', Team_Primary_Color__c='#E32221', Venue_Name__c='BayArena'));
teams.add(new Account(Name='RB Salzburg', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='RBS', ESPN_Team_ID__c='379', Team_Primary_Color__c='#DD003C', Venue_Name__c='Red Bull Arena'));
teams.add(new Account(Name='Lille', Type='Team', Sport__c='Soccer', Gender_Class__c='Men\'s Team', League__c='uefa.champions', Abbreviation__c='LIL', ESPN_Team_ID__c='167', Team_Primary_Color__c='#C8102E', Venue_Name__c='Stade Pierre-Mauroy'));

try {
    // Upsert teams by ESPN_Team_ID__c to avoid duplicates
    Database.UpsertResult[] results = Database.upsert(teams, Account.ESPN_Team_ID__c, false);
    Integer successCount = 0;
    Integer errorCount = 0;
    for (Database.UpsertResult result : results) {
        if (result.isSuccess()) {
            successCount++;
        } else {
            errorCount++;
            System.debug('ERROR: ' + result.getErrors()[0].getMessage());
        }
    }
    System.debug('✓ Teams: ' + successCount + ' successful, ' + errorCount + ' errors');
} catch (Exception e) {
    System.debug('ERROR upserting teams: ' + e.getMessage());
}

// Get teams for match import
Map<String, Account> teamMap = new Map<String, Account>();
for (Account team : [SELECT Id, Name FROM Account WHERE ESPN_Team_ID__c != null]) {
    teamMap.put(team.Name, team);
}
System.debug('✓ Loaded ' + teamMap.size() + ' teams for match import');

System.debug('=== Import Complete ===');
System.debug('Next: Run import-all-matches.apex to add all 53 matches');

