/**
 * Complete Test Data Import Script
 * Imports Premier League and Champions League December 2024 test data
 * 
 * Usage: sf apex run --file scripts/apex/import-test-data-complete.apex
 */

System.debug('========================================');
System.debug('Importing Test Data - PL & UCL Dec 2024');
System.debug('========================================\n');

// Maps to store created records for lookups
Map<String, Season__c> seasonMap = new Map<String, Season__c>();
Map<String, Competition__c> compMap = new Map<String, Competition__c>();
Map<String, Account> teamMap = new Map<String, Account>();
Map<String, Contact> playerMap = new Map<String, Contact>();
Map<String, Match__c> matchMap = new Map<String, Match__c>();

try {
    // ============================================================================
    // STEP 1: CREATE SEASON
    // ============================================================================
    System.debug('Step 1: Creating Season...');
    
    Season__c season = new Season__c(
        Season_Name__c = '2024-2025',
        Start_Date__c = Date.newInstance(2024, 8, 1),
        End_Date__c = Date.newInstance(2025, 5, 31),
        Sport__c = 'Soccer',
        Status__c = 'Active'
    );
    insert season;
    seasonMap.put('2024-2025', season);
    System.debug('✓ Season created: ' + season.Season_Name__c + ' (ID: ' + season.Id + ')');
    
    // ============================================================================
    // STEP 2: CREATE COMPETITIONS
    // ============================================================================
    System.debug('\nStep 2: Creating Competitions...');
    
    Competition__c premierLeague = new Competition__c(
        Season_Year__c = '2024-2025',
        Sport__c = 'Soccer',
        Competition_Type__c = 'Domestic League',
        Country__c = 'England',
        Tier_Level__c = 1,
        ESPN_League_ID__c = 'eng.1',
        Status__c = 'Active',
        Season__c = season.Id,
        Season_Start_Date__c = Date.newInstance(2024, 8, 1),
        Season_End_Date__c = Date.newInstance(2025, 5, 31)
    );
    
    Competition__c championsLeague = new Competition__c(
        Season_Year__c = '2024-2025',
        Sport__c = 'Soccer',
        Competition_Type__c = 'Continental Cup',
        Country__c = 'Europe',
        Tier_Level__c = 1,
        ESPN_League_ID__c = 'uefa.champions',
        Status__c = 'Active',
        Season__c = season.Id,
        Season_Start_Date__c = Date.newInstance(2024, 8, 1),
        Season_End_Date__c = Date.newInstance(2025, 5, 31)
    );
    
    insert new List<Competition__c>{ premierLeague, championsLeague };
    compMap.put('Premier League 2024-25', premierLeague);
    compMap.put('UEFA Champions League 2024-25', championsLeague);
    System.debug('✓ Competitions created: 2');
    
    // ============================================================================
    // STEP 3: CREATE TEAMS
    // ============================================================================
    System.debug('\nStep 3: Creating Teams...');
    
    List<Account> teams = new List<Account>();
    
    // Premier League Teams
    teams.add(new Account(Name='Liverpool', Sport__c='Soccer', ESPN_Team_ID__c='364', Venue_Name__c='Anfield'));
    teams.add(new Account(Name='Arsenal', Sport__c='Soccer', ESPN_Team_ID__c='359', Venue_Name__c='Emirates Stadium'));
    teams.add(new Account(Name='Chelsea', Sport__c='Soccer', ESPN_Team_ID__c='363', Venue_Name__c='Stamford Bridge'));
    teams.add(new Account(Name='Manchester City', Sport__c='Soccer', ESPN_Team_ID__c='382', Venue_Name__c='Etihad Stadium'));
    teams.add(new Account(Name='Manchester United', Sport__c='Soccer', ESPN_Team_ID__c='360', Venue_Name__c='Old Trafford'));
    teams.add(new Account(Name='Tottenham Hotspur', Sport__c='Soccer', ESPN_Team_ID__c='367', Venue_Name__c='Tottenham Hotspur Stadium'));
    teams.add(new Account(Name='Newcastle United', Sport__c='Soccer', ESPN_Team_ID__c='361', Venue_Name__c='St James\' Park'));
    teams.add(new Account(Name='Aston Villa', Sport__c='Soccer', ESPN_Team_ID__c='362', Venue_Name__c='Villa Park'));
    teams.add(new Account(Name='Brighton & Hove Albion', Sport__c='Soccer', ESPN_Team_ID__c='331', Venue_Name__c='Amex Stadium'));
    teams.add(new Account(Name='Nottingham Forest', Sport__c='Soccer', ESPN_Team_ID__c='393', Venue_Name__c='City Ground'));
    teams.add(new Account(Name='Everton', Sport__c='Soccer', ESPN_Team_ID__c='368', Venue_Name__c='Goodison Park'));
    teams.add(new Account(Name='Fulham', Sport__c='Soccer', ESPN_Team_ID__c='370', Venue_Name__c='Craven Cottage'));
    teams.add(new Account(Name='Brentford', Sport__c='Soccer', ESPN_Team_ID__c='337', Venue_Name__c='Gtech Community Stadium'));
    teams.add(new Account(Name='Crystal Palace', Sport__c='Soccer', ESPN_Team_ID__c='384', Venue_Name__c='Selhurst Park'));
    teams.add(new Account(Name='West Ham United', Sport__c='Soccer', ESPN_Team_ID__c='371', Venue_Name__c='London Stadium'));
    teams.add(new Account(Name='AFC Bournemouth', Sport__c='Soccer', ESPN_Team_ID__c='349', Venue_Name__c='Vitality Stadium'));
    teams.add(new Account(Name='Leicester City', Sport__c='Soccer', ESPN_Team_ID__c='375', Venue_Name__c='King Power Stadium'));
    teams.add(new Account(Name='Ipswich Town', Sport__c='Soccer', ESPN_Team_ID__c='373', Venue_Name__c='Portman Road'));
    teams.add(new Account(Name='Wolverhampton Wanderers', Sport__c='Soccer', ESPN_Team_ID__c='380', Venue_Name__c='Molineux Stadium'));
    teams.add(new Account(Name='Southampton', Sport__c='Soccer', ESPN_Team_ID__c='376', Venue_Name__c='St Mary\'s Stadium'));
    
    // Champions League Teams
    teams.add(new Account(Name='AC Milan', Sport__c='Soccer', ESPN_Team_ID__c='103', Venue_Name__c='San Siro'));
    teams.add(new Account(Name='Inter Milan', Sport__c='Soccer', ESPN_Team_ID__c='108', Venue_Name__c='San Siro'));
    teams.add(new Account(Name='Paris Saint-Germain', Sport__c='Soccer', ESPN_Team_ID__c='160', Venue_Name__c='Parc des Princes'));
    teams.add(new Account(Name='Real Madrid', Sport__c='Soccer', ESPN_Team_ID__c='86', Venue_Name__c='Santiago Bernabéu'));
    teams.add(new Account(Name='Bayern München', Sport__c='Soccer', ESPN_Team_ID__c='132', Venue_Name__c='Allianz Arena'));
    teams.add(new Account(Name='Barcelona', Sport__c='Soccer', ESPN_Team_ID__c='83', Venue_Name__c='Camp Nou'));
    teams.add(new Account(Name='Sporting CP', Sport__c='Soccer', ESPN_Team_ID__c='184', Venue_Name__c='José Alvalade Stadium'));
    teams.add(new Account(Name='Monaco', Sport__c='Soccer', ESPN_Team_ID__c='174', Venue_Name__c='Stade Louis II'));
    teams.add(new Account(Name='GNK Dinamo Zagreb', Sport__c='Soccer', ESPN_Team_ID__c='2446', Venue_Name__c='Maksimir Stadium'));
    teams.add(new Account(Name='Girona', Sport__c='Soccer', ESPN_Team_ID__c='93', Venue_Name__c='Estadi Montilivi'));
    teams.add(new Account(Name='Celtic', Sport__c='Soccer', ESPN_Team_ID__c='295', Venue_Name__c='Celtic Park'));
    teams.add(new Account(Name='Shakhtar Donetsk', Sport__c='Soccer', ESPN_Team_ID__c='623', Venue_Name__c='Donbass Arena'));
    teams.add(new Account(Name='Bologna', Sport__c='Soccer', ESPN_Team_ID__c='104', Venue_Name__c='Stadio Renato Dall\'Ara'));
    teams.add(new Account(Name='Juventus', Sport__c='Soccer', ESPN_Team_ID__c='111', Venue_Name__c='Allianz Stadium'));
    teams.add(new Account(Name='RB Leipzig', Sport__c='Soccer', ESPN_Team_ID__c='147', Venue_Name__c='Red Bull Arena'));
    teams.add(new Account(Name='Club Brugge', Sport__c='Soccer', ESPN_Team_ID__c='300', Venue_Name__c='Jan Breydel Stadium'));
    teams.add(new Account(Name='Atalanta', Sport__c='Soccer', ESPN_Team_ID__c='102', Venue_Name__c='Gewiss Stadium'));
    teams.add(new Account(Name='Young Boys', Sport__c='Soccer', ESPN_Team_ID__c='343', Venue_Name__c='Wankdorf Stadium'));
    teams.add(new Account(Name='Crvena Zvezda', Sport__c='Soccer', ESPN_Team_ID__c='619', Venue_Name__c='Rajko Mitić Stadium'));
    teams.add(new Account(Name='Slovan Bratislava', Sport__c='Soccer', ESPN_Team_ID__c='647', Venue_Name__c='Tehelné pole'));
    
    insert teams;
    for (Account team : teams) {
        teamMap.put(team.Name, team);
    }
    System.debug('✓ Teams created: ' + teams.size());
    
    // ============================================================================
    // STEP 4: CREATE PLAYERS
    // ============================================================================
    System.debug('\nStep 4: Creating Players...');
    
    List<Contact> players = new List<Contact>();
    
    // Premier League Players
    players.add(new Contact(FirstName='Mohamed', LastName='Salah', Position__c='Forward', ESPN_Player_ID__c='118748', Nationality__c='Egypt', Date_of_Birth__c=Date.newInstance(1992,6,15)));
    players.add(new Contact(FirstName='Bukayo', LastName='Saka', Position__c='Forward', ESPN_Player_ID__c='240784', Nationality__c='England', Date_of_Birth__c=Date.newInstance(2001,9,5)));
    players.add(new Contact(FirstName='Erling', LastName='Haaland', Position__c='Forward', ESPN_Player_ID__c='237678', Nationality__c='Norway', Date_of_Birth__c=Date.newInstance(2000,7,21)));
    players.add(new Contact(FirstName='Cole', LastName='Palmer', Position__c='Midfielder', ESPN_Player_ID__c='239764', Nationality__c='England', Date_of_Birth__c=Date.newInstance(2002,5,6)));
    players.add(new Contact(FirstName='Heung-Min', LastName='Son', Position__c='Forward', ESPN_Player_ID__c='73449', Nationality__c='South Korea', Date_of_Birth__c=Date.newInstance(1992,7,8)));
    players.add(new Contact(FirstName='Bruno', LastName='Fernandes', Position__c='Midfielder', ESPN_Player_ID__c='202665', Nationality__c='Portugal', Date_of_Birth__c=Date.newInstance(1994,9,8)));
    players.add(new Contact(FirstName='Ollie', LastName='Watkins', Position__c='Forward', ESPN_Player_ID__c='244362', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1995,12,30)));
    players.add(new Contact(FirstName='Alexander', LastName='Isak', Position__c='Forward', ESPN_Player_ID__c='244669', Nationality__c='Sweden', Date_of_Birth__c=Date.newInstance(1999,9,21)));
    players.add(new Contact(FirstName='Phil', LastName='Foden', Position__c='Midfielder', ESPN_Player_ID__c='191455', Nationality__c='England', Date_of_Birth__c=Date.newInstance(2000,5,28)));
    players.add(new Contact(FirstName='Luis', LastName='Diaz', Position__c='Forward', ESPN_Player_ID__c='202735', Nationality__c='Colombia', Date_of_Birth__c=Date.newInstance(1997,1,13)));
    players.add(new Contact(FirstName='Nicolas', LastName='Jackson', Position__c='Forward', ESPN_Player_ID__c='265959', Nationality__c='Senegal', Date_of_Birth__c=Date.newInstance(2001,6,20)));
    players.add(new Contact(FirstName='Dominic', LastName='Solanke', Position__c='Forward', ESPN_Player_ID__c='185294', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1997,9,14)));
    players.add(new Contact(FirstName='Jarrod', LastName='Bowen', Position__c='Forward', ESPN_Player_ID__c='182362', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1996,12,20)));
    players.add(new Contact(FirstName='Jean-Philippe', LastName='Mateta', Position__c='Forward', ESPN_Player_ID__c='215830', Nationality__c='France', Date_of_Birth__c=Date.newInstance(1997,6,28)));
    players.add(new Contact(FirstName='Gabriel', LastName='Jesus', Position__c='Forward', ESPN_Player_ID__c='156277', Nationality__c='Brazil', Date_of_Birth__c=Date.newInstance(1997,4,3)));
    players.add(new Contact(FirstName='Marcus', LastName='Rashford', Position__c='Forward', ESPN_Player_ID__c='214958', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1997,10,31)));
    players.add(new Contact(FirstName='Brennan', LastName='Johnson', Position__c='Forward', ESPN_Player_ID__c='238964', Nationality__c='Wales', Date_of_Birth__c=Date.newInstance(2001,5,23)));
    players.add(new Contact(FirstName='Chris', LastName='Wood', Position__c='Forward', ESPN_Player_ID__c='43854', Nationality__c='New Zealand', Date_of_Birth__c=Date.newInstance(1991,12,7)));
    players.add(new Contact(FirstName='Darwin', LastName='Nunez', Position__c='Forward', ESPN_Player_ID__c='208759', Nationality__c='Uruguay', Date_of_Birth__c=Date.newInstance(1999,6,24)));
    players.add(new Contact(FirstName='Callum', LastName='Wilson', Position__c='Forward', ESPN_Player_ID__c='77149', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1992,2,27)));
    
    // Champions League Players
    players.add(new Contact(FirstName='Vinicius', LastName='Junior', Position__c='Forward', ESPN_Player_ID__c='247851', Nationality__c='Brazil', Date_of_Birth__c=Date.newInstance(2000,7,12)));
    players.add(new Contact(FirstName='Kylian', LastName='Mbappé', Position__c='Forward', ESPN_Player_ID__c='231403', Nationality__c='France', Date_of_Birth__c=Date.newInstance(1998,12,20)));
    players.add(new Contact(FirstName='Robert', LastName='Lewandowski', Position__c='Forward', ESPN_Player_ID__c='41411', Nationality__c='Poland', Date_of_Birth__c=Date.newInstance(1988,8,21)));
    players.add(new Contact(FirstName='Harry', LastName='Kane', Position__c='Forward', ESPN_Player_ID__c='125689', Nationality__c='England', Date_of_Birth__c=Date.newInstance(1993,7,28)));
    players.add(new Contact(FirstName='Lautaro', LastName='Martinez', Position__c='Forward', ESPN_Player_ID__c='214242', Nationality__c='Argentina', Date_of_Birth__c=Date.newInstance(1997,8,22)));
    players.add(new Contact(FirstName='Serhou', LastName='Guirassy', Position__c='Forward', ESPN_Player_ID__c='206032', Nationality__c='Guinea', Date_of_Birth__c=Date.newInstance(1996,3,12)));
    players.add(new Contact(FirstName='Viktor', LastName='Gyökeres', Position__c='Forward', ESPN_Player_ID__c='236369', Nationality__c='Sweden', Date_of_Birth__c=Date.newInstance(1998,6,4)));
    players.add(new Contact(FirstName='Raphinha', LastName='Dias Belloli', Position__c='Forward', ESPN_Player_ID__c='247471', Nationality__c='Brazil', Date_of_Birth__c=Date.newInstance(1996,12,14)));
    players.add(new Contact(FirstName='Julián', LastName='Alvarez', Position__c='Forward', ESPN_Player_ID__c='245279', Nationality__c='Argentina', Date_of_Birth__c=Date.newInstance(2000,1,31)));
    players.add(new Contact(FirstName='Florian', LastName='Wirtz', Position__c='Midfielder', ESPN_Player_ID__c='246191', Nationality__c='Germany', Date_of_Birth__c=Date.newInstance(2003,5,3)));
    
    insert players;
    for (Contact player : players) {
        String key = player.FirstName + ' ' + player.LastName;
        playerMap.put(key.trim(), player);
    }
    System.debug('✓ Players created: ' + players.size());
    
    System.debug('\n✅ Base data import complete!');
    System.debug('   - 1 Season');
    System.debug('   - 2 Competitions');
    System.debug('   - ' + teams.size() + ' Teams');
    System.debug('   - ' + players.size() + ' Players');
    System.debug('\n⚠️  Note: Matches, Periods, and Stats require manual CSV import or additional script');
    System.debug('   Run: sf data import bulk --sobject Match__c --file data/test-data/matches.csv');
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
    throw e;
}

