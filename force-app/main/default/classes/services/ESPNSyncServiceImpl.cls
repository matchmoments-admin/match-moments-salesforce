/**
 * @description Service implementation for ESPN data synchronization
 * Orchestrates data flow between ESPN API, Selectors, and Domains
 * 
 * IMPORTANT: This service NEVER commits the UOW - that's the entry point's job
 * 
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class ESPNSyncServiceImpl implements IESPNSyncService {
    
    /**
     * @description Factory method to get service instance
     * @return IESPNSyncService Service instance
     */
    public static IESPNSyncService newInstance() {
        return (IESPNSyncService) Application.Service.newInstance(IESPNSyncService.class);
    }
    
    // =========================================================================
    // TEAM SYNC
    // =========================================================================
    
    /**
     * @description Sync team data from ESPN
     * @param teamId Account (Team) record ID
     * @param uow Unit of Work instance (passed from entry point)
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncTeam(Id teamId, fflib_ISObjectUnitOfWork uow) {
        try {
            // 1. Query team using Selector
            List<Account> teamList = TeamsSelector.newInstance().selectById(new Set<Id>{ teamId });
            
            if (teamList.isEmpty()) {
                return ESPNSyncResult.failure('Team not found', teamId);
            }
            
            Account team = teamList[0];
            
            // 2. Validate using Domain
            ITeams teamsDomain = (ITeams) Application.Domain.newInstance(teamList);
            teamsDomain.validateTeamType();
            
            // 3. Validate required fields
            if (String.isBlank(team.Name)) {
                return ESPNSyncResult.failure('Team name is required', teamId);
            }
            if (String.isBlank(team.Sport__c)) {
                return ESPNSyncResult.failure('Sport is required on the team record', teamId);
            }
            
            // 4. Resolve ESPN Team ID if missing
            String espnTeamId = team.ESPN_Team_ID__c;
            
            if (String.isBlank(espnTeamId)) {
                espnTeamId = searchTeamByName(team.Name, team.Sport__c);
                
                if (String.isBlank(espnTeamId)) {
                    return ESPNSyncResult.failure(
                        'Team "' + team.Name + '" not found in ESPN database. Please verify the team name.',
                        teamId
                    );
                }
            }
            
            // 5. Fetch team details from ESPN
            String espnSport = SportUtils.normalizeSportForESPN(team.Sport__c);
            String leagueCode = SportUtils.getDefaultLeagueCode(team.Sport__c);
            
            ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(espnSport, leagueCode);
            
            if (!response.success) {
                return ESPNSyncResult.failure('ESPN API error: ' + response.errorMessage, teamId);
            }
            
            // 6. Find our team in the response
            ESPNHttpService.ESPNTeam teamData = null;
            for (ESPNHttpService.ESPNTeam t : response.teams) {
                if (t.id == espnTeamId) {
                    teamData = t;
                    break;
                }
            }
            
            if (teamData == null) {
                return ESPNSyncResult.failure('Team data not found in ESPN response', teamId);
            }
            
            // 7. Update team record
            Account updatedTeam = new Account(
                Id = teamId,
                ESPN_Team_ID__c = teamData.id,
                Abbreviation__c = teamData.shortName,
                Logo_Url__c = teamData.logoUrl,
                Venue_Name__c = teamData.venueName
            );
            
            // 8. Register with UOW (NO COMMIT!)
            uow.registerDirty(updatedTeam);
            
            return ESPNSyncResult.success('Team synced: ' + teamData.name, teamId)
                .withData(JSON.serialize(teamData));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncTeam error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + e.getStackTraceString());
            return ESPNSyncResult.failure('Error syncing team: ' + e.getMessage(), teamId);
        }
    }
    
    // =========================================================================
    // PLAYER SYNC
    // =========================================================================
    
    /**
     * @description Sync player data from ESPN
     * @param playerId Contact (Player) record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncPlayer(Id playerId, fflib_ISObjectUnitOfWork uow) {
        try {
            // 1. Query player with team info
            List<Contact> players = PlayersSelector.newInstance().selectByIdWithTeam(new Set<Id>{ playerId });
            
            if (players.isEmpty()) {
                return ESPNSyncResult.failure('Player not found', playerId);
            }
            
            Contact player = players[0];
            
            // 2. Validate team is linked
            if (player.Current_Team__c == null || String.isBlank(player.Current_Team__r.ESPN_Team_ID__c)) {
                return ESPNSyncResult.failure('Player must be linked to a team with ESPN ID', playerId);
            }
            
            // 3. Get team roster from ESPN
            String sportType = String.isNotBlank(player.Current_Team__r.Sport__c) 
                ? player.Current_Team__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = SportUtils.getDefaultLeagueCode(sportType);
            String teamId = player.Current_Team__r.ESPN_Team_ID__c;
            
            ESPNHttpService.ESPNRosterResponse response = ESPNHttpService.getTeamRoster(espnSport, leagueCode, teamId);
            
            if (!response.success) {
                return ESPNSyncResult.failure('ESPN API error: ' + response.errorMessage, playerId);
            }
            
            // 4. Find matching player in roster
            ESPNHttpService.ESPNAthlete matchedAthlete = null;
            for (ESPNHttpService.ESPNAthlete athlete : response.athletes) {
                if (athlete.displayName.containsIgnoreCase(player.Name) || 
                    player.Name.containsIgnoreCase(athlete.displayName)) {
                    matchedAthlete = athlete;
                    break;
                }
            }
            
            if (matchedAthlete == null) {
                return ESPNSyncResult.failure('Player not found in team roster', playerId);
            }
            
            // 5. Update player using Domain pattern
            Map<String, Object> athleteData = new Map<String, Object>{
                'id' => matchedAthlete.id,
                'firstName' => matchedAthlete.firstName,
                'lastName' => matchedAthlete.lastName,
                'position' => matchedAthlete.position,
                'jersey' => matchedAthlete.jersey,
                'headshotUrl' => matchedAthlete.headshotUrl
            };
            
            Contact updatedPlayer = new Contact(
                Id = playerId,
                ESPN_Player_ID__c = matchedAthlete.id,
                Position__c = matchedAthlete.position,
                Profile_Image_URL__c = matchedAthlete.headshotUrl,
                Player_Role__c = 'Player'
            );
            
            if (String.isNotBlank(matchedAthlete.jersey) && matchedAthlete.jersey.isNumeric()) {
                updatedPlayer.Jersey_Number__c = Integer.valueOf(matchedAthlete.jersey);
            }
            
            // 6. Register with UOW
            uow.registerDirty(updatedPlayer);
            
            return ESPNSyncResult.success('Player synced: ' + matchedAthlete.displayName, playerId)
                .withData(JSON.serialize(matchedAthlete));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncPlayer error: ' + e.getMessage());
            return ESPNSyncResult.failure('Error syncing player: ' + e.getMessage(), playerId);
        }
    }
    
    // =========================================================================
    // FIXTURE SYNC
    // =========================================================================
    
    /**
     * @description Sync fixture data from ESPN
     * @param fixtureId Match__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncFixture(Id fixtureId, fflib_ISObjectUnitOfWork uow) {
        try {
            // 1. Query fixture with details
            List<Match__c> fixtureList = MatchesSelector.newInstance().selectByIdWithDetails(new Set<Id>{ fixtureId });
            
            if (fixtureList.isEmpty()) {
                return ESPNSyncResult.failure('Fixture not found', fixtureId);
            }
            
            Match__c fixture = fixtureList[0];
            
            // 2. Determine sport and league
            String sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                ? fixture.Competition__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = (fixture.Competition__c != null && fixture.Competition__r.ESPN_League_ID__c != null)
                ? fixture.Competition__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // 3. Resolve ESPN Event ID
            String eventId = fixture.ESPN_Event_ID__c;
            
            if (String.isBlank(eventId)) {
                // Try to find by date
                eventId = searchFixtureByDate(fixture, espnSport, leagueCode);
                
                if (String.isBlank(eventId)) {
                    return ESPNSyncResult.failure('ESPN Event ID not found. Set ESPN_Event_ID__c on the fixture.', fixtureId);
                }
            }
            
            // 4. Get live feed from ESPN
            ESPNHttpService.ESPNLiveFeedResponse response = ESPNHttpService.getLiveFeed(espnSport, leagueCode, eventId);
            
            if (!response.success) {
                return ESPNSyncResult.failure('ESPN API error: ' + response.errorMessage, fixtureId);
            }
            
            // 5. Update fixture record
            Match__c updatedFixture = new Match__c(
                Id = fixtureId,
                ESPN_Event_ID__c = eventId,
                Home_Score_Final__c = response.homeScore != null ? Decimal.valueOf(response.homeScore) : null,
                Away_Score_Final__c = response.awayScore != null ? Decimal.valueOf(response.awayScore) : null,
                Status__c = Fixtures.mapESPNStatus(response.matchStatus)
            );
            
            // 6. Register with UOW
            uow.registerDirty(updatedFixture);
            
            String scoreMsg = (response.homeScore != null ? response.homeScore : '0') + ' - ' + 
                             (response.awayScore != null ? response.awayScore : '0');
            
            return ESPNSyncResult.success('Fixture updated. Score: ' + scoreMsg, fixtureId)
                .withData(JSON.serialize(response));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncFixture error: ' + e.getMessage());
            return ESPNSyncResult.failure('Error syncing fixture: ' + e.getMessage(), fixtureId);
        }
    }
    
    // =========================================================================
    // COMPETITION FIXTURES SYNC
    // =========================================================================
    
    /**
     * @description Sync all fixtures for a competition from ESPN
     * @param competitionId Competition__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncCompetitionFixtures(Id competitionId, fflib_ISObjectUnitOfWork uow) {
        try {
            // 1. Query competition
            List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{ competitionId });
            
            if (competitions.isEmpty()) {
                return ESPNSyncResult.failure('Competition not found', competitionId);
            }
            
            Competition__c comp = competitions[0];
            
            // 2. Determine sport and league
            String sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = String.isNotBlank(comp.ESPN_League_ID__c) 
                ? comp.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // 3. Get fixtures from ESPN
            Date today = Date.today();
            String dateStr = today.year() + String.valueOf(today.month()).leftPad(2, '0') + String.valueOf(today.day()).leftPad(2, '0');
            
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                return ESPNSyncResult.failure(
                    response.errorMessage != null ? response.errorMessage : 'No fixtures found',
                    competitionId
                );
            }
            
            // 4. Collect team ESPN IDs for lookup
            Set<String> teamEspnIds = new Set<String>();
            for (ESPNHttpService.ESPNEvent event : response.events) {
                if (event.homeTeamId != null) teamEspnIds.add(event.homeTeamId);
                if (event.awayTeamId != null) teamEspnIds.add(event.awayTeamId);
            }
            
            // 5. Query existing teams (bulk - NOT in loop!)
            Map<String, Id> teamEspnIdToAccountId = TeamsSelector.newInstance().selectESPNIdToAccountIdMap(teamEspnIds);
            
            // 6. Create/update fixtures
            Integer created = 0;
            Integer updated = 0;
            
            // Query existing fixtures by ESPN Event ID
            Set<String> eventIds = new Set<String>();
            for (ESPNHttpService.ESPNEvent event : response.events) {
                eventIds.add(event.id);
            }
            
            List<Match__c> existingFixtures = MatchesSelector.newInstance().selectByESPNEventIds(eventIds);
            Map<String, Match__c> existingByEspnId = new Map<String, Match__c>();
            for (Match__c f : existingFixtures) {
                existingByEspnId.put(f.ESPN_Event_ID__c, f);
            }
            
            // 7. Build fixtures
            for (ESPNHttpService.ESPNEvent event : response.events) {
                Match__c fixture;
                
                if (existingByEspnId.containsKey(event.id)) {
                    // Update existing
                    fixture = existingByEspnId.get(event.id);
                    updated++;
                } else {
                    // Create new
                    fixture = new Match__c();
                    fixture.Competition__c = competitionId;
                    created++;
                }
                
                fixture.ESPN_Event_ID__c = event.id;
                fixture.Match_Date_Time__c = Fixtures.parseESPNDate(event.eventDate);
                fixture.Status__c = Fixtures.mapESPNStatus(event.status);
                fixture.Venue__c = event.venueName;
                
                // Link teams if they exist
                if (event.homeTeamId != null && teamEspnIdToAccountId.containsKey(event.homeTeamId)) {
                    fixture.Home_Team__c = teamEspnIdToAccountId.get(event.homeTeamId);
                }
                if (event.awayTeamId != null && teamEspnIdToAccountId.containsKey(event.awayTeamId)) {
                    fixture.Away_Team__c = teamEspnIdToAccountId.get(event.awayTeamId);
                }
                
                // Set scores if available
                if (event.homeScore != null) {
                    fixture.Home_Score_Final__c = Decimal.valueOf(event.homeScore);
                }
                if (event.awayScore != null) {
                    fixture.Away_Score_Final__c = Decimal.valueOf(event.awayScore);
                }
                
                // Register with UOW
                if (fixture.Id != null) {
                    uow.registerDirty(fixture);
                } else {
                    uow.registerNew(fixture);
                }
            }
            
            return ESPNSyncResult.success('Synced ' + response.events.size() + ' fixtures for ' + comp.Name, competitionId)
                .withCounts(response.events.size(), created, updated);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncCompetitionFixtures error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + e.getStackTraceString());
            return ESPNSyncResult.failure('Error syncing fixtures: ' + e.getMessage(), competitionId);
        }
    }
    
    // =========================================================================
    // BULK OPERATIONS
    // =========================================================================
    
    /**
     * @description Bulk sync multiple teams
     * @param teamIds Set of Account (Team) record IDs
     * @param uow Unit of Work instance
     * @return List of ESPNSyncResult for each team
     */
    public List<ESPNSyncResult> syncTeams(Set<Id> teamIds, fflib_ISObjectUnitOfWork uow) {
        List<ESPNSyncResult> results = new List<ESPNSyncResult>();
        
        for (Id teamId : teamIds) {
            results.add(syncTeam(teamId, uow));
        }
        
        return results;
    }
    
    // =========================================================================
    // BULK COMPETITION SYNC METHODS (For Scheduled Jobs)
    // =========================================================================
    
    /**
     * @description Sync all teams for a competition
     * Uses existing ESPNSyncService static methods
     * @param competitionId Competition__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncCompetitionTeams(Id competitionId, fflib_ISObjectUnitOfWork uow) {
        try {
            // Query competition
            List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{ competitionId });
            
            if (competitions.isEmpty()) {
                return ESPNSyncResult.failure('Competition not found', competitionId);
            }
            
            Competition__c comp = competitions[0];
            
            // Determine sport and league
            String sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = String.isNotBlank(comp.ESPN_League_ID__c) 
                ? comp.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // Use existing static method (doesn't use UOW pattern)
            Integer teamsCount = ESPNSyncService.syncLeagueTeams(espnSport, leagueCode);
            
            return ESPNSyncResult.success('Synced ' + teamsCount + ' teams for ' + comp.Name, competitionId)
                .withCounts(teamsCount, 0, 0);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncCompetitionTeams error: ' + e.getMessage());
            return ESPNSyncResult.failure('Error syncing competition teams: ' + e.getMessage(), competitionId);
        }
    }
    
    /**
     * @description Sync all rosters for a competition
     * @param competitionId Competition__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncCompetitionRosters(Id competitionId, fflib_ISObjectUnitOfWork uow) {
        try {
            // Query competition
            List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{ competitionId });
            
            if (competitions.isEmpty()) {
                return ESPNSyncResult.failure('Competition not found', competitionId);
            }
            
            Competition__c comp = competitions[0];
            
            // Determine sport and league
            String sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = String.isNotBlank(comp.ESPN_League_ID__c) 
                ? comp.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // Use existing static method (doesn't use UOW pattern)
            Integer playersCount = ESPNSyncService.syncAllRostersForLeague(espnSport, leagueCode);
            
            return ESPNSyncResult.success('Synced ' + playersCount + ' players for ' + comp.Name, competitionId)
                .withCounts(playersCount, 0, 0);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncCompetitionRosters error: ' + e.getMessage());
            return ESPNSyncResult.failure('Error syncing competition rosters: ' + e.getMessage(), competitionId);
        }
    }
    
    /**
     * @description Sync fixtures with date range for a competition
     * @param competitionId Competition__c record ID
     * @param startDate Start date for fixtures
     * @param endDate End date for fixtures
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncCompetitionFixturesDateRange(
        Id competitionId, 
        Date startDate, 
        Date endDate,
        fflib_ISObjectUnitOfWork uow
    ) {
        try {
            // Query competition
            List<Competition__c> competitions = CompetitionsSelector.newInstance().selectById(new Set<Id>{ competitionId });
            
            if (competitions.isEmpty()) {
                return ESPNSyncResult.failure('Competition not found', competitionId);
            }
            
            Competition__c comp = competitions[0];
            
            // Determine sport and league
            String sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = String.isNotBlank(comp.ESPN_League_ID__c) 
                ? comp.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // Use existing static method (doesn't use UOW pattern)
            Integer fixturesCount = ESPNSyncService.syncFixturesForDateRange(
                espnSport, 
                leagueCode, 
                startDate, 
                endDate, 
                competitionId
            );
            
            return ESPNSyncResult.success('Synced ' + fixturesCount + ' fixtures for ' + comp.Name, competitionId)
                .withCounts(fixturesCount, 0, 0);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncCompetitionFixturesDateRange error: ' + e.getMessage());
            return ESPNSyncResult.failure('Error syncing competition fixtures: ' + e.getMessage(), competitionId);
        }
    }
    
    // =========================================================================
    // PRIVATE HELPER METHODS
    // =========================================================================
    
    /**
     * @description Search ESPN for team by name
     * @param teamName Team name to search
     * @param sportType Sport type
     * @return ESPN Team ID if found
     */
    private String searchTeamByName(String teamName, String sportType) {
        String espnSport = SportUtils.normalizeSportForESPN(sportType);
        String leagueCode = SportUtils.getDefaultLeagueCode(sportType);
        
        ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(espnSport, leagueCode);
        
        if (response.success && response.teams != null) {
            for (ESPNHttpService.ESPNTeam team : response.teams) {
                if (team.name.equalsIgnoreCase(teamName) ||
                    team.name.containsIgnoreCase(teamName) ||
                    teamName.containsIgnoreCase(team.name) ||
                    (team.shortName != null && team.shortName.equalsIgnoreCase(teamName))) {
                    return team.id;
                }
            }
        }
        
        return null;
    }
    
    /**
     * @description Search for fixture by date and teams
     * @param fixture Fixture record
     * @param espnSport ESPN sport code
     * @param leagueCode ESPN league code
     * @return ESPN Event ID if found
     */
    private String searchFixtureByDate(Match__c fixture, String espnSport, String leagueCode) {
        Date fixtureDate = fixture.Match_Date_Time__c != null 
            ? fixture.Match_Date_Time__c.date() : Date.today();
        String dateStr = fixtureDate.year() + 
            String.valueOf(fixtureDate.month()).leftPad(2, '0') + 
            String.valueOf(fixtureDate.day()).leftPad(2, '0');
        
        ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
        
        if (response.success && response.events != null) {
            for (ESPNHttpService.ESPNEvent event : response.events) {
                // Match by name if available
                if (event.name != null && fixture.Name != null) {
                    if (event.name.containsIgnoreCase(fixture.Name) || 
                        fixture.Name.containsIgnoreCase(event.name)) {
                        return event.id;
                    }
                }
            }
        }
        
        return null;
    }
}

