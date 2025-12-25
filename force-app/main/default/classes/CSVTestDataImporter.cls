/**
 * CSV Test Data Importer
 * Imports test data for Super League 2024 and Premier League 2024-25
 */
public with sharing class CSVTestDataImporter {
    
    public class ImportResult {
        public Integer seasonsCreated = 0;
        public Integer competitionsCreated = 0;
        public Integer teamsCreated = 0;
        public Integer playersCreated = 0;
        public Integer matchesCreated = 0;
        public Integer statsCreated = 0;
        public Integer awardsCreated = 0;
        public Integer articlesCreated = 0;
        public Boolean success = false;
        public String errorMessage;
    }
    
    /**
     * Main import method
     */
    public static ImportResult importTestData() {
        ImportResult result = new ImportResult();
        
        try {
            // Collections to hold data
            Map<String, Season__c> seasonMap = new Map<String, Season__c>();
            Map<String, Competition__c> competitionMap = new Map<String, Competition__c>();
            Map<String, Account> teamMap = new Map<String, Account>();
            Map<String, Contact> playerMap = new Map<String, Contact>();
            
            // Step 1: Create Seasons
            seasonMap.putAll(createSeasons());
            insert seasonMap.values();
            result.seasonsCreated = seasonMap.size();
            
            // Step 2: Create Competitions
            competitionMap.putAll(createCompetitions(seasonMap));
            insert competitionMap.values();
            result.competitionsCreated = competitionMap.size();
            
            // Step 3: Create Teams
            teamMap.putAll(createTeams());
            insert teamMap.values();
            result.teamsCreated = teamMap.size();
            
            // Step 4: Create Players
            playerMap.putAll(createPlayers());
            insert playerMap.values();
            result.playersCreated = playerMap.size();
            
            // Step 4.5: Create Team Memberships
            List<Team_Membership__c> memberships = createTeamMemberships(
                seasonMap, teamMap, playerMap
            );
            insert memberships;
            System.debug('✓ Created ' + memberships.size() + ' team memberships');
            
            // Step 4.6: Update Current_Team__c on players
            updatePlayerCurrentTeams(playerMap, teamMap);
            update playerMap.values();
            System.debug('✓ Updated player current teams');
            
            // Step 5: Create Matches
            List<Match__c> matches = createMatches(seasonMap, competitionMap, teamMap);
            insert matches;
            result.matchesCreated = matches.size();
            
            // Store matches for article references (by index)
            Map<Integer, Match__c> matchMap = new Map<Integer, Match__c>();
            for (Integer i = 0; i < matches.size(); i++) {
                matchMap.put(i, matches[i]);
            }
            
            // Step 6: Create Player Season Stats
            List<Player_Season_Stats__c> stats = createPlayerStats(seasonMap, competitionMap, teamMap, playerMap);
            insert stats;
            result.statsCreated = stats.size();
            
            // Step 7: Create Awards
            List<Award__c> awards = createAwards(seasonMap, competitionMap, teamMap, playerMap);
            insert awards;
            result.awardsCreated = awards.size();
            
            // Step 8: Create Articles
            List<Article__c> articles = createArticles(teamMap, playerMap, matchMap);
            insert articles;
            result.articlesCreated = articles.size();
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage() + '\n' + e.getStackTraceString();
        }
        
        return result;
    }
    
    /**
     * Create Seasons
     */
    private static Map<String, Season__c> createSeasons() {
        Map<String, Season__c> seasonMap = new Map<String, Season__c>();
        
        // Super League 2024
        seasonMap.put('season_2024', new Season__c(
            Season_Name__c = '2024',
            Sport__c = 'Rugby',
            Season_Type__c = 'Calendar Year',
            Status__c = 'Completed',
            Start_Date__c = Date.newInstance(2024, 2, 1),
            End_Date__c = Date.newInstance(2024, 10, 12)
        ));
        
        // Premier League 2024-25
        seasonMap.put('season_2024_25', new Season__c(
            Season_Name__c = '2024-25',
            Sport__c = 'Soccer',
            Season_Type__c = 'Split Year',
            Status__c = 'Active',
            Start_Date__c = Date.newInstance(2024, 8, 1),
            End_Date__c = Date.newInstance(2025, 5, 31)
        ));
        
        return seasonMap;
    }
    
    /**
     * Create Competitions
     */
    private static Map<String, Competition__c> createCompetitions(Map<String, Season__c> seasonMap) {
        Map<String, Competition__c> competitionMap = new Map<String, Competition__c>();
        
        // Super League
        competitionMap.put('sl_2024', new Competition__c(
            Sport__c = 'Rugby League',
            Status__c = 'Active',
            Competition_Type__c = 'Domestic League',
            Season__c = seasonMap.get('season_2024').Id,
            ESPN_League_ID__c = 'SL2024',
            Season_Start_Date__c = Date.newInstance(2024, 2, 1),
            Season_Year__c = '2024'
        ));
        
        // Premier League
        competitionMap.put('epl_2024_25', new Competition__c(
            Sport__c = 'Soccer',
            Status__c = 'Active',
            Competition_Type__c = 'Domestic League',
            Season__c = seasonMap.get('season_2024_25').Id,
            ESPN_League_ID__c = 'EPL2024_25',
            Season_Start_Date__c = Date.newInstance(2024, 8, 1),
            Season_Year__c = '2024-25'
        ));
        
        return competitionMap;
    }
    
    /**
     * Create Teams
     */
    private static Map<String, Account> createTeams() {
        Map<String, Account> teamMap = new Map<String, Account>();
        
        // Super League Teams
        List<Map<String, String>> slTeams = new List<Map<String, String>>{
            new Map<String, String>{'id' => 'sl_wigan', 'name' => 'Wigan Warriors', 'venue' => 'DW Stadium'},
            new Map<String, String>{'id' => 'sl_hullkr', 'name' => 'Hull Kingston Rovers', 'venue' => 'Craven Park'},
            new Map<String, String>{'id' => 'sl_warrington', 'name' => 'Warrington Wolves', 'venue' => 'Halliwell Jones Stadium'},
            new Map<String, String>{'id' => 'sl_salford', 'name' => 'Salford Red Devils', 'venue' => 'Salford Community Stadium'},
            new Map<String, String>{'id' => 'sl_leigh', 'name' => 'Leigh Leopards', 'venue' => 'Leigh Sports Village'},
            new Map<String, String>{'id' => 'sl_sthelens', 'name' => 'St Helens', 'venue' => 'Totally Wicked Stadium'},
            new Map<String, String>{'id' => 'sl_leeds', 'name' => 'Leeds Rhinos', 'venue' => 'Headingley Stadium'},
            new Map<String, String>{'id' => 'sl_catalans', 'name' => 'Catalans Dragons', 'venue' => 'Stade Gilbert Brutus'},
            new Map<String, String>{'id' => 'sl_huddersfield', 'name' => 'Huddersfield Giants', 'venue' => 'John Smith\'s Stadium'},
            new Map<String, String>{'id' => 'sl_castleford', 'name' => 'Castleford Tigers', 'venue' => 'Mend-A-Hose Jungle'},
            new Map<String, String>{'id' => 'sl_hull', 'name' => 'Hull FC', 'venue' => 'MKM Stadium'},
            new Map<String, String>{'id' => 'sl_london', 'name' => 'London Broncos', 'venue' => 'Plough Lane'}
        };
        
        for (Map<String, String> teamData : slTeams) {
            Account team = new Account(
                Name = teamData.get('name'),
                Sport__c = 'Rugby',
                Venue_Name__c = teamData.get('venue'),
                Type = 'Club'
            );
            // Gender_Class__c is not required, skip if it causes issues
            teamMap.put(teamData.get('id'), team);
        }
        
        // Premier League Teams
        List<Map<String, String>> eplTeams = new List<Map<String, String>>{
            new Map<String, String>{'id' => 'epl_liverpool', 'name' => 'Liverpool', 'venue' => 'Anfield'},
            new Map<String, String>{'id' => 'epl_arsenal', 'name' => 'Arsenal', 'venue' => 'Emirates Stadium'},
            new Map<String, String>{'id' => 'epl_mancity', 'name' => 'Manchester City', 'venue' => 'Etihad Stadium'},
            new Map<String, String>{'id' => 'epl_chelsea', 'name' => 'Chelsea', 'venue' => 'Stamford Bridge'},
            new Map<String, String>{'id' => 'epl_newcastle', 'name' => 'Newcastle United', 'venue' => 'St James\' Park'},
            new Map<String, String>{'id' => 'epl_villa', 'name' => 'Aston Villa', 'venue' => 'Villa Park'},
            new Map<String, String>{'id' => 'epl_forest', 'name' => 'Nottingham Forest', 'venue' => 'City Ground'},
            new Map<String, String>{'id' => 'epl_spurs', 'name' => 'Tottenham Hotspur', 'venue' => 'Tottenham Hotspur Stadium'},
            new Map<String, String>{'id' => 'epl_manutd', 'name' => 'Manchester United', 'venue' => 'Old Trafford'},
            new Map<String, String>{'id' => 'epl_brighton', 'name' => 'Brighton', 'venue' => 'Amex Stadium'}
        };
        
        for (Map<String, String> teamData : eplTeams) {
            Account team = new Account(
                Name = teamData.get('name'),
                Sport__c = 'Soccer',
                Venue_Name__c = teamData.get('venue'),
                Type = 'Club'
            );
            // Gender_Class__c is not required, skip if it causes issues
            teamMap.put(teamData.get('id'), team);
        }
        
        return teamMap;
    }
    
    /**
     * Create Players
     */
    private static Map<String, Contact> createPlayers() {
        Map<String, Contact> playerMap = new Map<String, Contact>();
        
        // Super League Players (Position__c omitted - rugby positions not in picklist)
        playerMap.put('french_001', new Contact(
            FirstName = 'Bevan', LastName = 'French',
            Nationality__c = 'Australia', Date_of_Birth__c = Date.newInstance(1996, 2, 27), Jersey_Number__c = 1
        ));
        playerMap.put('lewis_001', new Contact(
            FirstName = 'Mikey', LastName = 'Lewis',
            Nationality__c = 'England', Date_of_Birth__c = Date.newInstance(2000, 6, 15), Jersey_Number__c = 7
        ));
        playerMap.put('williams_001', new Contact(
            FirstName = 'George', LastName = 'Williams',
            Nationality__c = 'England', Date_of_Birth__c = Date.newInstance(1994, 3, 4), Jersey_Number__c = 6
        ));
        playerMap.put('sneyd_001', new Contact(
            FirstName = 'Marc', LastName = 'Sneyd',
            Nationality__c = 'England', Date_of_Birth__c = Date.newInstance(1990, 10, 17), Jersey_Number__c = 7
        ));
        
        // Premier League Players
        playerMap.put('salah_001', new Contact(
            FirstName = 'Mohamed', LastName = 'Salah', Position__c = 'Forward',
            Nationality__c = 'Egypt', Date_of_Birth__c = Date.newInstance(1992, 6, 15), Jersey_Number__c = 11
        ));
        playerMap.put('haaland_001', new Contact(
            FirstName = 'Erling', LastName = 'Haaland', Position__c = 'Forward',
            Nationality__c = 'Norway', Date_of_Birth__c = Date.newInstance(2000, 7, 21), Jersey_Number__c = 9
        ));
        playerMap.put('isak_001', new Contact(
            FirstName = 'Alexander', LastName = 'Isak', Position__c = 'Forward',
            Nationality__c = 'Sweden', Date_of_Birth__c = Date.newInstance(1999, 9, 21), Jersey_Number__c = 14
        ));
        playerMap.put('palmer_001', new Contact(
            FirstName = 'Cole', LastName = 'Palmer', Position__c = 'Midfielder',
            Nationality__c = 'England', Date_of_Birth__c = Date.newInstance(2002, 5, 6), Jersey_Number__c = 20
        ));
        playerMap.put('vandijk_001', new Contact(
            FirstName = 'Virgil', LastName = 'van Dijk', Position__c = 'Defender',
            Nationality__c = 'Netherlands', Date_of_Birth__c = Date.newInstance(1991, 7, 8), Jersey_Number__c = 4
        ));
        playerMap.put('saka_001', new Contact(
            FirstName = 'Bukayo', LastName = 'Saka', Position__c = 'Midfielder',
            Nationality__c = 'England', Date_of_Birth__c = Date.newInstance(2001, 9, 5), Jersey_Number__c = 7
        ));
        
        return playerMap;
    }
    
    /**
     * Create Matches
     */
    private static List<Match__c> createMatches(
        Map<String, Season__c> seasonMap,
        Map<String, Competition__c> competitionMap,
        Map<String, Account> teamMap
    ) {
        List<Match__c> matches = new List<Match__c>();
        
        // Super League Matches
        matches.add(new Match__c(
            Competition__c = competitionMap.get('sl_2024').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Home_Team__c = teamMap.get('sl_wigan').Id,
            Away_Team__c = teamMap.get('sl_hullkr').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 10, 12, 19, 0, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 9,
            Away_Score_Final__c = 2,
            Venue__c = 'Old Trafford',
            Attendance__c = 65536
        ));
        
        matches.add(new Match__c(
            Competition__c = competitionMap.get('sl_2024').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Home_Team__c = teamMap.get('sl_warrington').Id,
            Away_Team__c = teamMap.get('sl_sthelens').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 9, 28, 19, 30, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 23,
            Away_Score_Final__c = 22,
            Venue__c = 'Halliwell Jones Stadium',
            Attendance__c = 12500
        ));
        
        matches.add(new Match__c(
            Competition__c = competitionMap.get('sl_2024').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Home_Team__c = teamMap.get('sl_hullkr').Id,
            Away_Team__c = teamMap.get('sl_warrington').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 10, 5, 19, 30, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 10,
            Away_Score_Final__c = 8,
            Venue__c = 'Craven Park',
            Attendance__c = 10069
        ));
        
        // Premier League Matches
        matches.add(new Match__c(
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Home_Team__c = teamMap.get('epl_liverpool').Id,
            Away_Team__c = teamMap.get('epl_arsenal').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 12, 21, 15, 0, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 2,
            Away_Score_Final__c = 1,
            Venue__c = 'Anfield',
            Attendance__c = 60025
        ));
        
        matches.add(new Match__c(
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Home_Team__c = teamMap.get('epl_mancity').Id,
            Away_Team__c = teamMap.get('epl_chelsea').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 12, 15, 17, 30, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 3,
            Away_Score_Final__c = 1,
            Venue__c = 'Etihad Stadium',
            Attendance__c = 53400
        ));
        
        matches.add(new Match__c(
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Home_Team__c = teamMap.get('epl_liverpool').Id,
            Away_Team__c = teamMap.get('epl_manutd').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 12, 1, 16, 30, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 4,
            Away_Score_Final__c = 0,
            Venue__c = 'Anfield',
            Attendance__c = 61276
        ));
        
        return matches;
    }
    
    /**
     * Create Player Season Stats
     */
    private static List<Player_Season_Stats__c> createPlayerStats(
        Map<String, Season__c> seasonMap,
        Map<String, Competition__c> competitionMap,
        Map<String, Account> teamMap,
        Map<String, Contact> playerMap
    ) {
        List<Player_Season_Stats__c> stats = new List<Player_Season_Stats__c>();
        
        // Super League Stats
        stats.add(new Player_Season_Stats__c(
            Player__c = playerMap.get('french_001').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Competition__c = competitionMap.get('sl_2024').Id,
            Team__c = teamMap.get('sl_wigan').Id,
            Tries__c = 18, Goals__c = 0, Appearances__c = 27
        ));
        
        stats.add(new Player_Season_Stats__c(
            Player__c = playerMap.get('lewis_001').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Competition__c = competitionMap.get('sl_2024').Id,
            Team__c = teamMap.get('sl_hullkr').Id,
            Tries__c = 15, Goals__c = 45, Appearances__c = 28
        ));
        
        // Premier League Stats
        stats.add(new Player_Season_Stats__c(
            Player__c = playerMap.get('salah_001').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Team__c = teamMap.get('epl_liverpool').Id,
            Goals__c = 29, Assists__c = 18, Appearances__c = 35
        ));
        
        stats.add(new Player_Season_Stats__c(
            Player__c = playerMap.get('haaland_001').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Team__c = teamMap.get('epl_mancity').Id,
            Goals__c = 22, Assists__c = 7, Appearances__c = 32
        ));
        
        stats.add(new Player_Season_Stats__c(
            Player__c = playerMap.get('isak_001').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Team__c = teamMap.get('epl_newcastle').Id,
            Goals__c = 23, Assists__c = 5, Appearances__c = 33
        ));
        
        return stats;
    }
    
    /**
     * Create Awards
     */
    private static List<Award__c> createAwards(
        Map<String, Season__c> seasonMap,
        Map<String, Competition__c> competitionMap,
        Map<String, Account> teamMap,
        Map<String, Contact> playerMap
    ) {
        List<Award__c> awards = new List<Award__c>();
        
        // Super League Awards
        awards.add(new Award__c(
            Player__c = playerMap.get('french_001').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Competition__c = competitionMap.get('sl_2024').Id,
            Award_Type__c = 'Man of Steel',
            Award_Category__c = 'Individual Award',
            Year__c = 2024, Sport__c = 'Rugby'
        ));
        
        awards.add(new Award__c(
            Team__c = teamMap.get('sl_wigan').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Competition__c = competitionMap.get('sl_2024').Id,
            Award_Type__c = 'Grand Final Winners',
            Award_Category__c = 'Team Trophy',
            Year__c = 2024, Sport__c = 'Rugby'
        ));
        
        // Premier League Awards
        awards.add(new Award__c(
            Player__c = playerMap.get('salah_001').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Award_Type__c = 'Golden Boot',
            Award_Category__c = 'Individual Award',
            Year__c = 2025, Sport__c = 'Soccer'
        ));
        
        awards.add(new Award__c(
            Player__c = playerMap.get('vandijk_001').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Competition__c = competitionMap.get('epl_2024_25').Id,
            Award_Type__c = 'PFA Player of the Year',
            Award_Category__c = 'Individual Award',
            Year__c = 2025, Sport__c = 'Soccer'
        ));
        
        return awards;
    }
    
    /**
     * Create Articles
     */
    private static List<Article__c> createArticles(
        Map<String, Account> teamMap,
        Map<String, Contact> playerMap,
        Map<Integer, Match__c> matchMap
    ) {
        List<Article__c> articles = new List<Article__c>();
        
        // Super League Articles (Related_Match__c omitted - expects Opportunity, not Match__c)
        articles.add(new Article__c(
            Heading__c = 'Wigan Warriors vs Hull KR: Grand Final Showdown',
            Body__c = 'The 2024 Super League Grand Final pits champions Wigan Warriors against first-time finalists Hull Kingston Rovers.',
            Is_Published__c = true,
            Sport_Type__c = 'Rugby'
        ));
        
        articles.add(new Article__c(
            Heading__c = 'Bevan French: The Man of Steel\'s Record-Breaking Season',
            Body__c = 'Wigan Warriors fullback Bevan French has been named Man of Steel for 2024 after a phenomenal season.',
            Is_Published__c = true,
            Related_Player__c = playerMap.get('french_001').Id,
            Related_Team__c = teamMap.get('sl_wigan').Id,
            Sport_Type__c = 'Rugby'
        ));
        
        // Premier League Articles (Related_Match__c omitted - expects Opportunity, not Match__c)
        articles.add(new Article__c(
            Heading__c = 'Liverpool vs Arsenal: Title Race Showdown',
            Body__c = 'Liverpool host Arsenal in a crucial top-of-the-table clash at Anfield.',
            Is_Published__c = true,
            Sport_Type__c = 'Soccer'
        ));
        
        articles.add(new Article__c(
            Heading__c = 'Mohamed Salah\'s Record-Breaking Season',
            Body__c = 'At 32 years old Mohamed Salah is having one of his best ever seasons.',
            Is_Published__c = true,
            Related_Player__c = playerMap.get('salah_001').Id,
            Related_Team__c = teamMap.get('epl_liverpool').Id,
            Sport_Type__c = 'Soccer'
        ));
        
        return articles;
    }
    
    /**
     * Create Team Memberships to link players to teams
     */
    private static List<Team_Membership__c> createTeamMemberships(
        Map<String, Season__c> seasonMap,
        Map<String, Account> teamMap,
        Map<String, Contact> playerMap
    ) {
        List<Team_Membership__c> memberships = new List<Team_Membership__c>();
        
        // Super League Memberships
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('french_001').Id,
            Team__c = teamMap.get('sl_wigan').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Jersey_Number__c = 1,
            Start_Date__c = Date.newInstance(2024, 2, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('lewis_001').Id,
            Team__c = teamMap.get('sl_hullkr').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Jersey_Number__c = 7,
            Start_Date__c = Date.newInstance(2024, 2, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('williams_001').Id,
            Team__c = teamMap.get('sl_warrington').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Jersey_Number__c = 6,
            Start_Date__c = Date.newInstance(2024, 2, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('sneyd_001').Id,
            Team__c = teamMap.get('sl_salford').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Jersey_Number__c = 7,
            Start_Date__c = Date.newInstance(2024, 2, 1),
            Status__c = 'Active'
        ));
        
        // Premier League Memberships
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('salah_001').Id,
            Team__c = teamMap.get('epl_liverpool').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 11,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('haaland_001').Id,
            Team__c = teamMap.get('epl_mancity').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 9,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('isak_001').Id,
            Team__c = teamMap.get('epl_newcastle').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 14,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('palmer_001').Id,
            Team__c = teamMap.get('epl_chelsea').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 20,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('vandijk_001').Id,
            Team__c = teamMap.get('epl_liverpool').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 4,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        memberships.add(new Team_Membership__c(
            Player__c = playerMap.get('saka_001').Id,
            Team__c = teamMap.get('epl_arsenal').Id,
            Season__c = seasonMap.get('season_2024_25').Id,
            Jersey_Number__c = 7,
            Start_Date__c = Date.newInstance(2024, 8, 1),
            Status__c = 'Active'
        ));
        
        return memberships;
    }
    
    /**
     * Update Current_Team__c lookup on Contact records
     */
    private static void updatePlayerCurrentTeams(
        Map<String, Contact> playerMap,
        Map<String, Account> teamMap
    ) {
        // Super League Players
        playerMap.get('french_001').Current_Team__c = teamMap.get('sl_wigan').Id;
        playerMap.get('lewis_001').Current_Team__c = teamMap.get('sl_hullkr').Id;
        playerMap.get('williams_001').Current_Team__c = teamMap.get('sl_warrington').Id;
        playerMap.get('sneyd_001').Current_Team__c = teamMap.get('sl_salford').Id;
        
        // Premier League Players
        playerMap.get('salah_001').Current_Team__c = teamMap.get('epl_liverpool').Id;
        playerMap.get('haaland_001').Current_Team__c = teamMap.get('epl_mancity').Id;
        playerMap.get('isak_001').Current_Team__c = teamMap.get('epl_newcastle').Id;
        playerMap.get('palmer_001').Current_Team__c = teamMap.get('epl_chelsea').Id;
        playerMap.get('vandijk_001').Current_Team__c = teamMap.get('epl_liverpool').Id;
        playerMap.get('saka_001').Current_Team__c = teamMap.get('epl_arsenal').Id;
    }
}

