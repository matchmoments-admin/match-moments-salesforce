/**
 * CSV Test Data Import Script
 * Imports Super League 2024 and Premier League 2024-25 test data
 * 
 * Usage: Execute this script in Anonymous Apex
 */

// Data structures to hold CSV data
Map<String, Season__c> seasonMap = new Map<String, Season__c>();
Map<String, Competition__c> competitionMap = new Map<String, Competition__c>();
Map<String, Account> teamMap = new Map<String, Account>();
Map<String, Contact> playerMap = new Map<String, Contact>();
Map<String, Match__c> matchMap = new Map<String, Match__c>();
List<Award__c> awards = new List<Award__c>();
List<Article__c> articles = new List<Article__c>();
List<Team_Membership__c> teamMemberships = new List<Team_Membership__c>();
List<Player_Season_Stats__c> playerStats = new List<Player_Season_Stats__c>();

System.debug('=== Starting CSV Data Import ===');

// ============================================================================
// SUPER LEAGUE 2024 DATA
// ============================================================================

// 1. Create Season - 2024
Season__c sl2024Season = new Season__c(
    Name = '2024',
    Season_Name__c = '2024',
    Sport__c = 'Rugby League',
    Season_Type__c = 'Regular',
    Status__c = 'Completed',
    Start_Date__c = Date.newInstance(2024, 2, 1),
    End_Date__c = Date.newInstance(2024, 10, 12)
);
seasonMap.put('season_2024', sl2024Season);

// 2. Create Competition - Super League
Competition__c superLeague = new Competition__c(
    Name = 'Super League',
    Sport__c = 'Rugby League',
    Status__c = 'Active',
    Competition_Type__c = 'League'
);
competitionMap.put('sl_2024', superLeague);

// 3. Create Teams (Super League)
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
        Sport__c = 'Rugby League',
        Gender_Class__c = 'Men',
        Venue_Name__c = teamData.get('venue'),
        Type = 'Club'
    );
    teamMap.put(teamData.get('id'), team);
}

// 4. Create Players (Super League)
List<Map<String, Object>> slPlayers = new List<Map<String, Object>>{
    new Map<String, Object>{'id' => 'french_001', 'firstName' => 'Bevan', 'lastName' => 'French', 'position' => 'Fullback', 'nationality' => 'Australia', 'dob' => Date.newInstance(1996, 2, 27), 'jersey' => 1, 'tries' => 18, 'goals' => 0},
    new Map<String, Object>{'id' => 'lewis_001', 'firstName' => 'Mikey', 'lastName' => 'Lewis', 'position' => 'Halfback', 'nationality' => 'England', 'dob' => Date.newInstance(2000, 6, 15), 'jersey' => 7, 'tries' => 15, 'goals' => 45},
    new Map<String, Object>{'id' => 'williams_001', 'firstName' => 'George', 'lastName' => 'Williams', 'position' => 'Halfback', 'nationality' => 'England', 'dob' => Date.newInstance(1994, 3, 4), 'jersey' => 6, 'tries' => 8, 'goals' => 32},
    new Map<String, Object>{'id' => 'sneyd_001', 'firstName' => 'Marc', 'lastName' => 'Sneyd', 'position' => 'Halfback', 'nationality' => 'England', 'dob' => Date.newInstance(1990, 10, 17), 'jersey' => 7, 'tries' => 3, 'goals' => 78},
    new Map<String, Object>{'id' => 'lam_001', 'firstName' => 'Lachlan', 'lastName' => 'Lam', 'position' => 'Halfback', 'nationality' => 'Australia', 'dob' => Date.newInstance(1998, 1, 24), 'jersey' => 6, 'tries' => 12, 'goals' => 28},
    new Map<String, Object>{'id' => 'welsby_001', 'firstName' => 'Jack', 'lastName' => 'Welsby', 'position' => 'Fullback', 'nationality' => 'England', 'dob' => Date.newInstance(2001, 4, 11), 'jersey' => 1, 'tries' => 14, 'goals' => 0},
    new Map<String, Object>{'id' => 'croft_001', 'firstName' => 'Brodie', 'lastName' => 'Croft', 'position' => 'Halfback', 'nationality' => 'Australia', 'dob' => Date.newInstance(1997, 4, 27), 'jersey' => 7, 'tries' => 10, 'goals' => 35},
    new Map<String, Object>{'id' => 'tomkins_001', 'firstName' => 'Sam', 'lastName' => 'Tomkins', 'position' => 'Fullback', 'nationality' => 'England', 'dob' => Date.newInstance(1989, 3, 23), 'jersey' => 1, 'tries' => 8, 'goals' => 0},
    new Map<String, Object>{'id' => 'wardle_001', 'firstName' => 'Jake', 'lastName' => 'Wardle', 'position' => 'Centre', 'nationality' => 'England', 'dob' => Date.newInstance(1999, 7, 12), 'jersey' => 3, 'tries' => 16, 'goals' => 0},
    new Map<String, Object>{'id' => 'momirovski_001', 'firstName' => 'Paul', 'lastName' => 'Momirovski', 'position' => 'Centre', 'nationality' => 'Australia', 'dob' => Date.newInstance(1996, 2, 12), 'jersey' => 4, 'tries' => 12, 'goals' => 0}
};

for (Map<String, Object> playerData : slPlayers) {
    Contact player = new Contact(
        FirstName = (String)playerData.get('firstName'),
        LastName = (String)playerData.get('lastName'),
        Position__c = (String)playerData.get('position'),
        Nationality__c = (String)playerData.get('nationality'),
        Date_of_Birth__c = (Date)playerData.get('dob'),
        Jersey_Number__c = (Integer)playerData.get('jersey')
    );
    playerMap.put((String)playerData.get('id'), player);
}

// ============================================================================
// PREMIER LEAGUE 2024-25 DATA
// ============================================================================

// 1. Create Season - 2024-25
Season__c epl2425Season = new Season__c(
    Name = '2024-25',
    Season_Name__c = '2024-25',
    Sport__c = 'Soccer',
    Season_Type__c = 'Regular',
    Status__c = 'Active',
    Start_Date__c = Date.newInstance(2024, 8, 1),
    End_Date__c = Date.newInstance(2025, 5, 31)
);
seasonMap.put('season_2024_25', epl2425Season);

// 2. Create Competition - Premier League
Competition__c premierLeague = new Competition__c(
    Name = 'Premier League',
    Sport__c = 'Soccer',
    Status__c = 'Active',
    Competition_Type__c = 'League'
);
competitionMap.put('epl_2024_25', premierLeague);

// 3. Create Teams (Premier League)
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
        Gender_Class__c = 'Men',
        Venue_Name__c = teamData.get('venue'),
        Type = 'Club'
    );
    teamMap.put(teamData.get('id'), team);
}

// 4. Create Players (Premier League)
List<Map<String, Object>> eplPlayers = new List<Map<String, Object>>{
    new Map<String, Object>{'id' => 'salah_001', 'firstName' => 'Mohamed', 'lastName' => 'Salah', 'position' => 'Forward', 'nationality' => 'Egypt', 'dob' => Date.newInstance(1992, 6, 15), 'jersey' => 11, 'goals' => 29, 'assists' => 18},
    new Map<String, Object>{'id' => 'haaland_001', 'firstName' => 'Erling', 'lastName' => 'Haaland', 'position' => 'Forward', 'nationality' => 'Norway', 'dob' => Date.newInstance(2000, 7, 21), 'jersey' => 9, 'goals' => 22, 'assists' => 7},
    new Map<String, Object>{'id' => 'isak_001', 'firstName' => 'Alexander', 'lastName' => 'Isak', 'position' => 'Forward', 'nationality' => 'Sweden', 'dob' => Date.newInstance(1999, 9, 21), 'jersey' => 14, 'goals' => 23, 'assists' => 5},
    new Map<String, Object>{'id' => 'palmer_001', 'firstName' => 'Cole', 'lastName' => 'Palmer', 'position' => 'Midfielder', 'nationality' => 'England', 'dob' => Date.newInstance(2002, 5, 6), 'jersey' => 20, 'goals' => 15, 'assists' => 10},
    new Map<String, Object>{'id' => 'mbeumo_001', 'firstName' => 'Bryan', 'lastName' => 'Mbeumo', 'position' => 'Forward', 'nationality' => 'Cameroon', 'dob' => Date.newInstance(1999, 8, 7), 'jersey' => 19, 'goals' => 20, 'assists' => 8},
    new Map<String, Object>{'id' => 'wood_001', 'firstName' => 'Chris', 'lastName' => 'Wood', 'position' => 'Forward', 'nationality' => 'New Zealand', 'dob' => Date.newInstance(1991, 12, 7), 'jersey' => 11, 'goals' => 20, 'assists' => 4},
    new Map<String, Object>{'id' => 'watkins_001', 'firstName' => 'Ollie', 'lastName' => 'Watkins', 'position' => 'Forward', 'nationality' => 'England', 'dob' => Date.newInstance(1995, 12, 30), 'jersey' => 11, 'goals' => 16, 'assists' => 9},
    new Map<String, Object>{'id' => 'saka_001', 'firstName' => 'Bukayo', 'lastName' => 'Saka', 'position' => 'Midfielder', 'nationality' => 'England', 'dob' => Date.newInstance(2001, 9, 5), 'jersey' => 7, 'goals' => 11, 'assists' => 10},
    new Map<String, Object>{'id' => 'vandijk_001', 'firstName' => 'Virgil', 'lastName' => 'van Dijk', 'position' => 'Defender', 'nationality' => 'Netherlands', 'dob' => Date.newInstance(1991, 7, 8), 'jersey' => 4, 'goals' => 3, 'assists' => 1},
    new Map<String, Object>{'id' => 'odegaard_001', 'firstName' => 'Martin', 'lastName' => 'Odegaard', 'position' => 'Midfielder', 'nationality' => 'Norway', 'dob' => Date.newInstance(1998, 12, 17), 'jersey' => 8, 'goals' => 8, 'assists' => 9}
};

for (Map<String, Object> playerData : eplPlayers) {
    Contact player = new Contact(
        FirstName = (String)playerData.get('firstName'),
        LastName = (String)playerData.get('lastName'),
        Position__c = (String)playerData.get('position'),
        Nationality__c = (String)playerData.get('nationality'),
        Date_of_Birth__c = (Date)playerData.get('dob'),
        Jersey_Number__c = (Integer)playerData.get('jersey')
    );
    playerMap.put((String)playerData.get('id'), player);
}

// ============================================================================
// INSERT RECORDS IN PROPER ORDER
// ============================================================================

try {
    // Step 1: Insert Seasons
    System.debug('Inserting ' + seasonMap.size() + ' seasons...');
    insert seasonMap.values();
    System.debug('✓ Seasons inserted successfully');
    
    // Step 2: Link Competitions to Seasons and Insert
    superLeague.Season__c = seasonMap.get('sl_2024').Id;
    premierLeague.Season__c = seasonMap.get('season_2024_25').Id;
    
    System.debug('Inserting ' + competitionMap.size() + ' competitions...');
    insert competitionMap.values();
    System.debug('✓ Competitions inserted successfully');
    
    // Step 3: Insert Teams
    System.debug('Inserting ' + teamMap.size() + ' teams...');
    insert teamMap.values();
    System.debug('✓ Teams inserted successfully');
    
    // Step 4: Insert Players
    System.debug('Inserting ' + playerMap.size() + ' players...');
    insert playerMap.values();
    System.debug('✓ Players inserted successfully');
    
    // Step 5: Create Matches (Super League)
    List<Match__c> matches = new List<Match__c>{
        new Match__c(
            Name = 'Wigan vs Hull KR - Grand Final',
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
        ),
        new Match__c(
            Name = 'Warrington vs St Helens',
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
        ),
        new Match__c(
            Name = 'Hull KR vs Warrington - Semi Final',
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
        ),
        new Match__c(
            Name = 'Wigan vs Leigh',
            Competition__c = competitionMap.get('sl_2024').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Home_Team__c = teamMap.get('sl_wigan').Id,
            Away_Team__c = teamMap.get('sl_leigh').Id,
            Match_Date_Time__c = DateTime.newInstance(2024, 8, 6, 20, 0, 0),
            Status__c = 'Completed',
            Home_Score_Final__c = 36,
            Away_Score_Final__c = 6,
            Venue__c = 'DW Stadium',
            Attendance__c = 18321
        ),
        new Match__c(
            Name = 'Leeds vs Catalans',
            Competition__c = competitionMap.get('sl_2024').Id,
            Season__c = seasonMap.get('season_2024').Id,
            Home_Team__c = teamMap.get('sl_leeds').Id,
            Away_Team__c = teamMap.get('sl_catalans').Id,
            Match_Date_Time__c = DateTime.newInstance(2025, 2, 20, 19, 45, 0),
            Status__c = 'Scheduled',
            Home_Score_Final__c = 0,
            Away_Score_Final__c = 0,
            Venue__c = 'Headingley Stadium'
        )
    };
    
    // Add Premier League matches
    matches.add(new Match__c(
        Name = 'Liverpool vs Arsenal',
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
        Name = 'Manchester City vs Chelsea',
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
        Name = 'Newcastle vs Brighton',
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Home_Team__c = teamMap.get('epl_newcastle').Id,
        Away_Team__c = teamMap.get('epl_brighton').Id,
        Match_Date_Time__c = DateTime.newInstance(2025, 1, 4, 15, 0, 0),
        Status__c = 'Scheduled',
        Venue__c = 'St James\' Park'
    ));
    
    matches.add(new Match__c(
        Name = 'Arsenal vs Tottenham',
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Home_Team__c = teamMap.get('epl_arsenal').Id,
        Away_Team__c = teamMap.get('epl_spurs').Id,
        Match_Date_Time__c = DateTime.newInstance(2025, 1, 15, 16, 30, 0),
        Status__c = 'Scheduled',
        Venue__c = 'Emirates Stadium'
    ));
    
    matches.add(new Match__c(
        Name = 'Liverpool vs Manchester United',
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
    
    System.debug('Inserting ' + matches.size() + ' matches...');
    insert matches;
    System.debug('✓ Matches inserted successfully');
    
    // Store matches for award/article references
    for (Match__c m : matches) {
        matchMap.put(m.Name, m);
    }
    
    // Step 6: Create Player Season Stats (Super League)
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('french_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Team__c = teamMap.get('sl_wigan').Id,
        Tries__c = 18,
        Goals__c = 0,
        Appearances__c = 27
    ));
    
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('lewis_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Team__c = teamMap.get('sl_hullkr').Id,
        Tries__c = 15,
        Goals__c = 45,
        Appearances__c = 28
    ));
    
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('williams_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Team__c = teamMap.get('sl_warrington').Id,
        Tries__c = 8,
        Goals__c = 32,
        Appearances__c = 25
    ));
    
    // Add more SL player stats
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('sneyd_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Team__c = teamMap.get('sl_salford').Id,
        Tries__c = 3,
        Goals__c = 78,
        Appearances__c = 26
    ));
    
    // Step 7: Create Player Season Stats (Premier League)
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('salah_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Team__c = teamMap.get('epl_liverpool').Id,
        Goals__c = 29,
        Assists__c = 18,
        Appearances__c = 35
    ));
    
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('haaland_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Team__c = teamMap.get('epl_mancity').Id,
        Goals__c = 22,
        Assists__c = 7,
        Appearances__c = 32
    ));
    
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('isak_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Team__c = teamMap.get('epl_newcastle').Id,
        Goals__c = 23,
        Assists__c = 5,
        Appearances__c = 33
    ));
    
    playerStats.add(new Player_Season_Stats__c(
        Player__c = playerMap.get('palmer_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Team__c = teamMap.get('epl_chelsea').Id,
        Goals__c = 15,
        Assists__c = 10,
        Appearances__c = 31
    ));
    
    System.debug('Inserting ' + playerStats.size() + ' player season stats...');
    insert playerStats;
    System.debug('✓ Player season stats inserted successfully');
    
    // Step 8: Create Awards (Super League)
    awards.add(new Award__c(
        Player__c = playerMap.get('french_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'Man of Steel',
        Award_Category__c = 'Individual Award',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    awards.add(new Award__c(
        Player__c = playerMap.get('lewis_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'Albert Goldthorpe Medal',
        Award_Category__c = 'Individual Award',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    awards.add(new Award__c(
        Player__c = playerMap.get('french_001').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'Lance Todd Trophy',
        Award_Category__c = 'Individual Award',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    awards.add(new Award__c(
        Team__c = teamMap.get('sl_wigan').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'League Leaders Shield',
        Award_Category__c = 'Team Trophy',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    awards.add(new Award__c(
        Team__c = teamMap.get('sl_wigan').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'Grand Final Winners',
        Award_Category__c = 'Team Trophy',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    awards.add(new Award__c(
        Team__c = teamMap.get('sl_wigan').Id,
        Season__c = seasonMap.get('season_2024').Id,
        Competition__c = competitionMap.get('sl_2024').Id,
        Award_Type__c = 'Challenge Cup Winners',
        Award_Category__c = 'Team Trophy',
        Year__c = 2024,
        Sport__c = 'Rugby League'
    ));
    
    // Step 9: Create Awards (Premier League)
    awards.add(new Award__c(
        Player__c = playerMap.get('salah_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Award_Type__c = 'Golden Boot',
        Award_Category__c = 'Individual Award',
        Year__c = 2025,
        Sport__c = 'Soccer'
    ));
    
    awards.add(new Award__c(
        Player__c = playerMap.get('vandijk_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Award_Type__c = 'PFA Player of the Year',
        Award_Category__c = 'Individual Award',
        Year__c = 2025,
        Sport__c = 'Soccer'
    ));
    
    awards.add(new Award__c(
        Player__c = playerMap.get('palmer_001').Id,
        Season__c = seasonMap.get('season_2024_25').Id,
        Competition__c = competitionMap.get('epl_2024_25').Id,
        Award_Type__c = 'Young Player of the Year',
        Award_Category__c = 'Individual Award',
        Year__c = 2025,
        Sport__c = 'Soccer'
    ));
    
    System.debug('Inserting ' + awards.size() + ' awards...');
    insert awards;
    System.debug('✓ Awards inserted successfully');
    
    // Step 10: Create Articles (Super League)
    articles.add(new Article__c(
        Heading__c = 'Wigan Warriors vs Hull KR: Grand Final Showdown',
        Body__c = 'The 2024 Super League Grand Final pits champions Wigan Warriors against first-time finalists Hull Kingston Rovers. Wigan are chasing a historic quadruple having already won the League Leaders Shield Challenge Cup and World Club Challenge. Hull KR led by the electric Mikey Lewis are looking to upset the odds at Old Trafford.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Wigan vs Hull KR - Grand Final').Id,
        Sport_Type__c = 'Rugby League'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Bevan French: The Man of Steel\'s Record-Breaking Season',
        Body__c = 'Wigan Warriors fullback Bevan French has been named Man of Steel for 2024 after a phenomenal season. With 18 tries and countless try assists French has been the creative spark behind Wigan\'s historic quadruple. This analysis explores his impact on the game.',
        Is_Published__c = true,
        Related_Player__c = playerMap.get('french_001').Id,
        Related_Team__c = teamMap.get('sl_wigan').Id,
        Sport_Type__c = 'Rugby League'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Wigan Warriors 9-2 Hull KR: Warriors Complete Historic Quadruple',
        Body__c = 'Wigan Warriors defeated Hull Kingston Rovers 9-2 in a tense defensive Grand Final to become the first team in Super League history to win all four major trophies in one season. Bevan French won the Harry Sunderland Trophy as Man of the Match despite the low-scoring affair.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Wigan vs Hull KR - Grand Final').Id,
        Related_Team__c = teamMap.get('sl_wigan').Id,
        Sport_Type__c = 'Rugby League'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Super League Grand Final Sets TV Viewing Record',
        Body__c = 'The 2024 Super League Grand Final between Wigan Warriors and Hull KR attracted a peak BBC Two audience of 385000 viewers setting a new record for a Super League playoff game. The game was watched by over 65000 fans at Old Trafford.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Wigan vs Hull KR - Grand Final').Id,
        Sport_Type__c = 'Rugby League'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Hull KR Reach First Ever Grand Final',
        Body__c = 'Hull Kingston Rovers have reached their first ever Super League Grand Final after a dramatic 10-8 victory over Warrington Wolves in the semi-final. Mikey Lewis kicked the winning drop goal in golden point extra time sending Craven Park into raptures.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Hull KR vs Warrington - Semi Final').Id,
        Related_Team__c = teamMap.get('sl_hullkr').Id,
        Sport_Type__c = 'Rugby League'
    ));
    
    // Step 11: Create Articles (Premier League)
    articles.add(new Article__c(
        Heading__c = 'Liverpool vs Arsenal: Title Race Showdown',
        Body__c = 'Liverpool host Arsenal in a crucial top-of-the-table clash at Anfield. Both teams are vying for the Premier League title with just a few points separating them. Mohamed Salah has been in scintillating form while Arsenal\'s Bukayo Saka continues to impress.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Liverpool vs Arsenal').Id,
        Sport_Type__c = 'Soccer'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Mohamed Salah\'s Record-Breaking Season',
        Body__c = 'At 32 years old Mohamed Salah is having one of his best ever seasons. With 29 goals and 18 assists he\'s matched Thierry Henry\'s record of 4 Golden Boots. This analysis explores what makes Salah so effective and how Liverpool have built their attack around him.',
        Is_Published__c = true,
        Related_Player__c = playerMap.get('salah_001').Id,
        Related_Team__c = teamMap.get('epl_liverpool').Id,
        Sport_Type__c = 'Soccer'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Manchester City 3-1 Chelsea: Haaland Double Secures Victory',
        Body__c = 'Erling Haaland scored twice as Manchester City defeated Chelsea 3-1 at the Etihad Stadium. Despite a consolation goal from Cole Palmer against his former club City dominated proceedings and moved closer to Champions League qualification.',
        Is_Published__c = true,
        Related_Match__c = matchMap.get('Manchester City vs Chelsea').Id,
        Related_Player__c = playerMap.get('haaland_001').Id,
        Sport_Type__c = 'Soccer'
    ));
    
    articles.add(new Article__c(
        Heading__c = 'Premier League Sets New Attendance Record',
        Body__c = 'The Premier League has announced that the 2024-25 season has set a new attendance record with an average of 39876 fans per match. Manchester United led the way with the highest average home attendance of 73738.',
        Is_Published__c = true,
        Sport_Type__c = 'Soccer'
    ));
    
    System.debug('Inserting ' + articles.size() + ' articles...');
    insert articles;
    System.debug('✓ Articles inserted successfully');
    
    // ========================================================================
    // FINAL SUMMARY
    // ========================================================================
    
    System.debug('\n=== IMPORT COMPLETE ===');
    System.debug('✓ Seasons: ' + seasonMap.size());
    System.debug('✓ Competitions: ' + competitionMap.size());
    System.debug('✓ Teams: ' + teamMap.size());
    System.debug('✓ Players: ' + playerMap.size());
    System.debug('✓ Matches: ' + matches.size());
    System.debug('✓ Player Stats: ' + playerStats.size());
    System.debug('✓ Awards: ' + awards.size());
    System.debug('✓ Articles: ' + articles.size());
    System.debug('\n=== All test data imported successfully! ===\n');
    
    // Query and display sample data
    System.debug('\n=== Sample Data Verification ===');
    
    List<Season__c> insertedSeasons = [SELECT Id, Name, Sport__c, Status__c FROM Season__c ORDER BY Name];
    System.debug('\nSeasons (' + insertedSeasons.size() + '):');
    for (Season__c s : insertedSeasons) {
        System.debug('  - ' + s.Name + ' (' + s.Sport__c + ') - ' + s.Status__c);
    }
    
    List<Competition__c> insertedComps = [SELECT Id, Name, Sport__c, Season__r.Name FROM Competition__c];
    System.debug('\nCompetitions (' + insertedComps.size() + '):');
    for (Competition__c c : insertedComps) {
        System.debug('  - ' + c.Name + ' (' + c.Sport__c + ') - Season: ' + c.Season__r.Name);
    }
    
    List<Match__c> insertedMatches = [SELECT Id, Name, Status__c, Home_Score_Final__c, Away_Score_Final__c 
                                       FROM Match__c ORDER BY Match_Date_Time__c DESC LIMIT 5];
    System.debug('\nRecent Matches (' + insertedMatches.size() + '):');
    for (Match__c m : insertedMatches) {
        System.debug('  - ' + m.Name + ': ' + m.Home_Score_Final__c + '-' + m.Away_Score_Final__c + ' (' + m.Status__c + ')');
    }
    
    List<Award__c> insertedAwards = [SELECT Id, Player__r.Name, Team__r.Name, Award_Type__c, Year__c 
                                      FROM Award__c ORDER BY Year__c DESC];
    System.debug('\nAwards (' + insertedAwards.size() + '):');
    for (Award__c a : insertedAwards) {
        String recipient = a.Player__c != null ? a.Player__r.Name : a.Team__r.Name;
        System.debug('  - ' + a.Award_Type__c + ': ' + recipient + ' (' + a.Year__c + ')');
    }
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
    throw e;
}

