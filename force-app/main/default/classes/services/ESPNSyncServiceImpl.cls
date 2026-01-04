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
                // Try to find by date and teams using resolver
                eventId = ESPNEventIdResolver.resolveEventId(fixture, espnSport, leagueCode);
                
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
                Status__c = Matches.mapESPNStatus(response.matchStatus)
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
    // COMPREHENSIVE MATCH SYNC
    // =========================================================================
    
    /**
     * @description Sync complete match data from ESPN (teams, players, match, lineups, commentary, periods)
     * @param fixtureId Match__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncMatchComplete(Id fixtureId, fflib_ISObjectUnitOfWork uow) {
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
                // Try to find by date and teams using resolver
                eventId = ESPNEventIdResolver.resolveEventId(fixture, espnSport, leagueCode);
                
                if (String.isBlank(eventId)) {
                    return ESPNSyncResult.failure('ESPN Event ID not found. Set ESPN_Event_ID__c on the fixture.', fixtureId);
                }
            }
            
            // 4. Get comprehensive match summary from ESPN
            ESPNHttpService.ESPNMatchSummaryResponse response = ESPNHttpService.getMatchSummaryDetailed(espnSport, leagueCode, eventId);
            
            if (!response.success) {
                return ESPNSyncResult.failure('ESPN API error: ' + response.errorMessage, fixtureId);
            }
            
            // 5. Update Match__c record
            Match__c updatedFixture = new Match__c(
                Id = fixtureId,
                ESPN_Event_ID__c = eventId,
                Home_Score_Final__c = response.homeScore != null ? Decimal.valueOf(response.homeScore) : null,
                Away_Score_Final__c = response.awayScore != null ? Decimal.valueOf(response.awayScore) : null,
                Status__c = Matches.mapESPNStatus(response.matchStatus)
            );
            
            if (String.isNotBlank(response.eventDate)) {
                updatedFixture.Match_Date_Time__c = ESPNDataParser.parseESPNDateTime(response.eventDate);
            }
            
            uow.registerDirty(updatedFixture);
            
            // 6. Sync/create teams if needed
            Map<String, Id> teamIdMap = new Map<String, Id>();
            
            if (String.isNotBlank(response.homeTeamId)) {
                Id homeTeamId = syncOrFindTeam(response.homeTeamId, response.homeTeamName, espnSport, leagueCode, uow);
                if (homeTeamId != null) {
                    teamIdMap.put(response.homeTeamId, homeTeamId);
                    updatedFixture.Home_Team__c = homeTeamId;
                }
            }
            
            if (String.isNotBlank(response.awayTeamId)) {
                Id awayTeamId = syncOrFindTeam(response.awayTeamId, response.awayTeamName, espnSport, leagueCode, uow);
                if (awayTeamId != null) {
                    teamIdMap.put(response.awayTeamId, awayTeamId);
                    updatedFixture.Away_Team__c = awayTeamId;
                }
            }
            
            // 7. Sync lineups and create Match_Participation__c records
            if (response.lineups != null && !response.lineups.isEmpty()) {
                // Bulk query existing lineups and participations upfront (FFLIB best practice)
                Set<Id> teamIdsForQuery = new Set<Id>(teamIdMap.values());
                Map<Id, Map<Id, Lineup__c>> existingLineupsMap = 
                    LineupsSelector.newInstance().selectByMatchAndTeamIds(new Set<Id>{ fixtureId }, teamIdsForQuery);
                
                List<Match_Participation__c> allExistingParticipations = 
                    MatchParticipationsSelector.newInstance().selectByMatchAndTeamIds(
                        new Set<Id>{ fixtureId }, 
                        teamIdsForQuery
                    );
                
                // Group existing participations by match and team
                Map<Id, Map<Id, List<Match_Participation__c>>> existingParticipationsByMatchAndTeam = 
                    new Map<Id, Map<Id, List<Match_Participation__c>>>();
                for (Match_Participation__c p : allExistingParticipations) {
                    if (!existingParticipationsByMatchAndTeam.containsKey(p.Match__c)) {
                        existingParticipationsByMatchAndTeam.put(p.Match__c, new Map<Id, List<Match_Participation__c>>());
                    }
                    if (!existingParticipationsByMatchAndTeam.get(p.Match__c).containsKey(p.Team__c)) {
                        existingParticipationsByMatchAndTeam.get(p.Match__c).put(p.Team__c, new List<Match_Participation__c>());
                    }
                    existingParticipationsByMatchAndTeam.get(p.Match__c).get(p.Team__c).add(p);
                }
                
                for (ESPNHttpService.ESPNLineup lineup : response.lineups) {
                    Id teamId = teamIdMap.get(lineup.teamId);
                    if (teamId == null) {
                        continue;
                    }
                    
                    // Check if lineup already exists (from bulk query)
                    Lineup__c existingLineup = null;
                    if (existingLineupsMap.containsKey(fixtureId) && 
                        existingLineupsMap.get(fixtureId).containsKey(teamId)) {
                        existingLineup = existingLineupsMap.get(fixtureId).get(teamId);
                    }
                    
                    Map<String, Object> lineupData = ESPNDataParser.parseLineupToLineup(lineup, fixtureId, teamId, uow, espnSport, leagueCode);
                    Lineup__c lineupRecord = (Lineup__c) lineupData.get('lineup');
                    
                    if (lineupRecord != null) {
                        if (existingLineup != null) {
                            lineupRecord.Id = existingLineup.Id;
                            uow.registerDirty(lineupRecord);
                        } else {
                            uow.registerNew(lineupRecord);
                        }
                        
                        // Register Match_Participation__c records
                        List<Match_Participation__c> participations = 
                            (List<Match_Participation__c>) lineupData.get('participations');
                        
                        if (participations != null && !participations.isEmpty()) {
                            // Delete existing participations for this match/team (from bulk query)
                            if (existingParticipationsByMatchAndTeam.containsKey(fixtureId) && 
                                existingParticipationsByMatchAndTeam.get(fixtureId).containsKey(teamId)) {
                                List<Match_Participation__c> existingParticipations = 
                                    existingParticipationsByMatchAndTeam.get(fixtureId).get(teamId);
                                if (!existingParticipations.isEmpty()) {
                                    uow.registerDeleted(existingParticipations);
                                }
                            }
                            
                            // Register new participations
                            for (Match_Participation__c participation : participations) {
                                uow.registerNew(participation);
                            }
                        }
                    }
                }
            }
            
            // 8. Sync commentary and create Match_Moment__c records
            if (response.commentaryItems != null && !response.commentaryItems.isEmpty()) {
                // Bulk query existing moments upfront (FFLIB best practice)
                // Note: Commentary__c is deprecated and uses Fixture__c, not Match__c, so we skip querying existing commentaries
                List<Match_Moment__c> existingMoments = 
                    MatchMomentsSelector.newInstance().selectByMatchIds(new Set<Id>{ fixtureId });
                
                Map<String, Object> commentaryData = ESPNDataParser.parseCommentaryToMatchMoments(
                    response.commentaryItems, 
                    fixtureId
                );
                
                Commentary__c commentary = (Commentary__c) commentaryData.get('commentary');
                if (commentary != null) {
                    // Commentary__c is deprecated - always create new since we can't reliably query by Match__c
                    uow.registerNew(commentary);
                    
                    // Register Match_Moment__c records
                    List<Match_Moment__c> moments = (List<Match_Moment__c>) commentaryData.get('moments');
                    if (moments != null && !moments.isEmpty()) {
                        // Delete existing moments for this match (from bulk query)
                        if (!existingMoments.isEmpty()) {
                            uow.registerDeleted(existingMoments);
                        }
                        
                        // Link moments to commentary and register
                        for (Match_Moment__c moment : moments) {
                            moment.Commentary__c = commentary.Id;
                            uow.registerNew(moment);
                        }
                    }
                }
            }
            
            // 9. Sync periods
            if (response.periods != null && !response.periods.isEmpty()) {
                // Bulk query existing periods upfront (FFLIB best practice)
                List<Match_Period__c> existingPeriods = 
                    MatchPeriodsSelector.newInstance().selectByFixtureId(new Set<Id>{ fixtureId });
                
                List<Match_Period__c> periods = ESPNDataParser.parsePeriodsToMatchPeriods(response.periods, fixtureId);
                
                if (!periods.isEmpty()) {
                    // Delete existing periods for this match (from bulk query)
                    if (!existingPeriods.isEmpty()) {
                        uow.registerDeleted(existingPeriods);
                    }
                    
                    // Register new periods
                    for (Match_Period__c period : periods) {
                        uow.registerNew(period);
                    }
                }
            }
            
            // Build success message
            Integer lineupCount = response.lineups != null ? response.lineups.size() : 0;
            Integer commentaryCount = response.commentaryItems != null ? response.commentaryItems.size() : 0;
            Integer periodCount = response.periods != null ? response.periods.size() : 0;
            
            String successMsg = 'Match synced completely. Lineups: ' + lineupCount + 
                ', Commentary events: ' + commentaryCount + 
                ', Periods: ' + periodCount;
            
            return ESPNSyncResult.success(successMsg, fixtureId)
                .withData(JSON.serialize(response));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNSyncService.syncMatchComplete error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + e.getStackTraceString());
            return ESPNSyncResult.failure('Error syncing match: ' + e.getMessage(), fixtureId);
        }
    }
    
    /**
     * @description Sync lineups for a match
     * @param fixtureId Match__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncMatchLineups(Id fixtureId, fflib_ISObjectUnitOfWork uow) {
        try {
            List<Match__c> fixtureList = MatchesSelector.newInstance().selectByIdWithDetails(new Set<Id>{ fixtureId });
            
            if (fixtureList.isEmpty()) {
                return ESPNSyncResult.failure('Fixture not found', fixtureId);
            }
            
            Match__c fixture = fixtureList[0];
            String eventId = fixture.ESPN_Event_ID__c;
            
            if (String.isBlank(eventId)) {
                return ESPNSyncResult.failure('ESPN Event ID not found', fixtureId);
            }
            
            String sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                ? fixture.Competition__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = (fixture.Competition__c != null && fixture.Competition__r.ESPN_League_ID__c != null)
                ? fixture.Competition__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            ESPNHttpService.ESPNMatchSummaryResponse response = ESPNHttpService.getMatchSummaryDetailed(espnSport, leagueCode, eventId);
            
            if (!response.success || response.lineups == null || response.lineups.isEmpty()) {
                return ESPNSyncResult.failure('No lineup data available', fixtureId);
            }
            
            Map<String, Id> teamIdMap = new Map<String, Id>();
            if (fixture.Home_Team__c != null) teamIdMap.put(response.homeTeamId, fixture.Home_Team__c);
            if (fixture.Away_Team__c != null) teamIdMap.put(response.awayTeamId, fixture.Away_Team__c);
            
            Integer lineupCount = 0;
            for (ESPNHttpService.ESPNLineup lineup : response.lineups) {
                Id teamId = teamIdMap.get(lineup.teamId);
                if (teamId == null) continue;
                
                Map<String, Object> lineupData = ESPNDataParser.parseLineupToLineup(lineup, fixtureId, teamId, uow, espnSport, leagueCode);
                Lineup__c lineupRecord = (Lineup__c) lineupData.get('lineup');
                
                if (lineupRecord != null) {
                    // Bulk query existing lineups upfront (FFLIB best practice)
                    Map<Id, Map<Id, Lineup__c>> existingLineupsMap = 
                        LineupsSelector.newInstance().selectByMatchAndTeamIds(
                            new Set<Id>{ fixtureId }, 
                            new Set<Id>{ teamId }
                        );
                    
                    Lineup__c existingLineup = null;
                    if (existingLineupsMap.containsKey(fixtureId) && 
                        existingLineupsMap.get(fixtureId).containsKey(teamId)) {
                        existingLineup = existingLineupsMap.get(fixtureId).get(teamId);
                    }
                    
                    if (existingLineup != null) {
                        lineupRecord.Id = existingLineup.Id;
                        uow.registerDirty(lineupRecord);
                    } else {
                        uow.registerNew(lineupRecord);
                    }
                    
                    // Handle Match_Participation__c records
                    List<Match_Participation__c> participations = 
                        (List<Match_Participation__c>) lineupData.get('participations');
                    
                    if (participations != null && !participations.isEmpty()) {
                        // Register new participations
                        for (Match_Participation__c participation : participations) {
                            if (participation.Player__c != null) {
                                uow.registerNew(participation);
                            }
                        }
                    }
                    
                    lineupCount++;
                }
            }
            
            return ESPNSyncResult.success('Synced ' + lineupCount + ' lineups', fixtureId);
            
        } catch (Exception e) {
            return ESPNSyncResult.failure('Error syncing lineups: ' + e.getMessage(), fixtureId);
        }
    }
    
    /**
     * @description Sync commentary/moments for a match
     * @param fixtureId Match__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncMatchCommentary(Id fixtureId, fflib_ISObjectUnitOfWork uow) {
        try {
            List<Match__c> fixtureList = MatchesSelector.newInstance().selectByIdWithDetails(new Set<Id>{ fixtureId });
            
            if (fixtureList.isEmpty()) {
                return ESPNSyncResult.failure('Fixture not found', fixtureId);
            }
            
            Match__c fixture = fixtureList[0];
            String eventId = fixture.ESPN_Event_ID__c;
            
            if (String.isBlank(eventId)) {
                return ESPNSyncResult.failure('ESPN Event ID not found', fixtureId);
            }
            
            String sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                ? fixture.Competition__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = (fixture.Competition__c != null && fixture.Competition__r.ESPN_League_ID__c != null)
                ? fixture.Competition__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            ESPNHttpService.ESPNMatchSummaryResponse response = ESPNHttpService.getMatchSummaryDetailed(espnSport, leagueCode, eventId);
            
            if (!response.success || response.commentaryItems == null || response.commentaryItems.isEmpty()) {
                return ESPNSyncResult.failure('No commentary data available', fixtureId);
            }
            
            Map<String, Object> commentaryData = ESPNDataParser.parseCommentaryToMatchMoments(
                response.commentaryItems, 
                fixtureId
            );
            
            Commentary__c commentary = (Commentary__c) commentaryData.get('commentary');
            if (commentary != null) {
                // Bulk query existing moments upfront (FFLIB best practice)
                // Note: Commentary__c is deprecated and uses Fixture__c, not Match__c, so we skip querying existing commentaries
                List<Match_Moment__c> existingMoments = 
                    MatchMomentsSelector.newInstance().selectByMatchIds(new Set<Id>{ fixtureId });
                
                // Commentary__c is deprecated - always create new since we can't reliably query by Match__c
                uow.registerNew(commentary);
                
                List<Match_Moment__c> moments = (List<Match_Moment__c>) commentaryData.get('moments');
                if (moments != null && !moments.isEmpty()) {
                    if (!existingMoments.isEmpty()) {
                        uow.registerDeleted(existingMoments);
                    }
                    
                    for (Match_Moment__c moment : moments) {
                        moment.Commentary__c = commentary.Id;
                        uow.registerNew(moment);
                    }
                }
            }
            
            return ESPNSyncResult.success('Synced ' + response.commentaryItems.size() + ' commentary events', fixtureId);
            
        } catch (Exception e) {
            return ESPNSyncResult.failure('Error syncing commentary: ' + e.getMessage(), fixtureId);
        }
    }
    
    /**
     * @description Sync periods for a match
     * @param fixtureId Match__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    public ESPNSyncResult syncMatchPeriods(Id fixtureId, fflib_ISObjectUnitOfWork uow) {
        try {
            List<Match__c> fixtureList = MatchesSelector.newInstance().selectByIdWithDetails(new Set<Id>{ fixtureId });
            
            if (fixtureList.isEmpty()) {
                return ESPNSyncResult.failure('Fixture not found', fixtureId);
            }
            
            Match__c fixture = fixtureList[0];
            String eventId = fixture.ESPN_Event_ID__c;
            
            if (String.isBlank(eventId)) {
                return ESPNSyncResult.failure('ESPN Event ID not found', fixtureId);
            }
            
            String sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                ? fixture.Competition__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = (fixture.Competition__c != null && fixture.Competition__r.ESPN_League_ID__c != null)
                ? fixture.Competition__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            ESPNHttpService.ESPNMatchSummaryResponse response = ESPNHttpService.getMatchSummaryDetailed(espnSport, leagueCode, eventId);
            
            if (!response.success || response.periods == null || response.periods.isEmpty()) {
                return ESPNSyncResult.failure('No period data available', fixtureId);
            }
            
            // Bulk query existing periods upfront (FFLIB best practice)
            List<Match_Period__c> existingPeriods = 
                MatchPeriodsSelector.newInstance().selectByFixtureId(new Set<Id>{ fixtureId });
            
            List<Match_Period__c> periods = ESPNDataParser.parsePeriodsToMatchPeriods(response.periods, fixtureId);
            
            if (!periods.isEmpty()) {
                if (!existingPeriods.isEmpty()) {
                    uow.registerDeleted(existingPeriods);
                }
                
                for (Match_Period__c period : periods) {
                    uow.registerNew(period);
                }
            }
            
            return ESPNSyncResult.success('Synced ' + periods.size() + ' periods', fixtureId);
            
        } catch (Exception e) {
            return ESPNSyncResult.failure('Error syncing periods: ' + e.getMessage(), fixtureId);
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
                    fixture.Match_Level__c = 'Professional'; // ESPN-synced matches are always Professional
                    created++;
                }
                
                fixture.ESPN_Event_ID__c = event.id;
                fixture.Match_Date_Time__c = Matches.parseESPNDate(event.eventDate);
                fixture.Status__c = Matches.mapESPNStatus(event.status);
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
     * @description Sync or find team by ESPN ID
     * @param espnTeamId ESPN team ID
     * @param teamName Team name
     * @param espnSport ESPN sport code
     * @param leagueCode ESPN league code
     * @param uow Unit of Work instance
     * @return Salesforce Account ID
     */
    private Id syncOrFindTeam(String espnTeamId, String teamName, String espnSport, String leagueCode, fflib_ISObjectUnitOfWork uow) {
        // Try to find existing team
        List<Account> existingTeams = [
            SELECT Id 
            FROM Account 
            WHERE ESPN_Team_ID__c = :espnTeamId 
            LIMIT 1
        ];
        
        if (!existingTeams.isEmpty()) {
            return existingTeams[0].Id;
        }
        
        // Try to find by name
        if (String.isNotBlank(teamName)) {
            List<Account> teamsByName = [
                SELECT Id, ESPN_Team_ID__c 
                FROM Account 
                WHERE Name = :teamName 
                LIMIT 1
            ];
            
            if (!teamsByName.isEmpty()) {
                // Update with ESPN ID
                Account team = teamsByName[0];
                team.ESPN_Team_ID__c = espnTeamId;
                uow.registerDirty(team);
                return team.Id;
            }
        }
        
        // Create new team
        Account newTeam = new Account();
        newTeam.Name = teamName != null ? teamName : 'Team ' + espnTeamId;
        newTeam.ESPN_Team_ID__c = espnTeamId;
        newTeam.Sport__c = espnSport == 'soccer' ? 'Soccer' : espnSport;
        
        uow.registerNew(newTeam);
        return newTeam.Id;
    }
}

