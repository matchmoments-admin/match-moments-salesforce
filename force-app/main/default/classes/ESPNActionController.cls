/**
 * @description Unified controller for ESPN Action Button - handles all 5 object contexts
 * Uses polymorphic pattern with ISportDataHandler interface for sport-specific logic
 * @author Brendan Milton
 * @date 2025-11-27
 */
public with sharing class ESPNActionController {
    
    /**
     * @description Main entry point for Quick Actions - determines sport type and uses appropriate handler
     * @param recordId The record ID of the triggering record
     * @param objectType The object type (Account, Contact, Opportunity, Opportunity_Group__c)
     * @return ESPNActionResult Result of the operation
     */
    @AuraEnabled
    public static ESPNActionResult getSportData(Id recordId, String objectType) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            // Determine sport type from record
            String sportType = 'Soccer'; // Default
            
            if (objectType == 'Account') {
                System.debug('Processing Account record...');
                Account team = [SELECT Id, Name, Type, Sport__c, ESPN_Team_ID__c 
                               FROM Account WHERE Id = :recordId LIMIT 1];
                System.debug('Account found - Name: ' + team.Name + ', Type: ' + team.Type + ', Sport__c: ' + team.Sport__c);
                return getTeamInformation(recordId);
                
            } else if (objectType == 'Contact') {
                System.debug('Processing Contact record...');
                Contact player = [SELECT Id, Name, Current_Team__c, Current_Team__r.Sport__c FROM Contact WHERE Id = :recordId LIMIT 1];
                System.debug('Contact found - Name: ' + player.Name);
                sportType = (player.Current_Team__c != null && player.Current_Team__r.Sport__c != null) 
                    ? player.Current_Team__r.Sport__c : 'Soccer';
                System.debug('Calling getPlayerInformation with playerName: ' + player.Name);
                return getPlayerInformation(recordId, player.Name);
                
            } else if (objectType == 'Opportunity') {
                System.debug('Processing Opportunity record...');
                Opportunity opp = [SELECT Id, Name, ESPN_ID__c, Opportunity_Group__r.Sport__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
                System.debug('Opportunity found - Name: ' + opp.Name + ', ESPN_ID__c: ' + opp.ESPN_ID__c);
                sportType = (opp.Opportunity_Group__c != null && opp.Opportunity_Group__r.Sport__c != null)
                    ? opp.Opportunity_Group__r.Sport__c : 'Soccer';
                System.debug('Calling getFixtureInformation with ESPN_ID__c: ' + opp.ESPN_ID__c);
                return getFixtureInformation(recordId, opp.ESPN_ID__c);
                
            } else if (objectType == 'Opportunity_Group__c') {
                System.debug('Processing Opportunity_Group__c record...');
                Opportunity_Group__c oppGroup = [SELECT Id, Name, Sport__c, ESPN_League_ID__c FROM Opportunity_Group__c WHERE Id = :recordId LIMIT 1];
                System.debug('Opportunity_Group__c found - Name: ' + oppGroup.Name + ', ESPN_League_ID__c: ' + oppGroup.ESPN_League_ID__c);
                sportType = String.isNotBlank(oppGroup.Sport__c) ? oppGroup.Sport__c : 'Soccer';
                System.debug('Calling getLeagueFixtures with ESPN_League_ID__c: ' + oppGroup.ESPN_League_ID__c);
                return getLeagueFixtures(recordId, oppGroup.ESPN_League_ID__c);
                
            } else if (objectType == 'Match__c') {
                System.debug('Processing Match__c record...');
                Match__c fixture = [SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Competition__r.Sport__c, 
                                      Competition__r.ESPN_League_ID__c
                                      FROM Match__c WHERE Id = :recordId LIMIT 1];
                System.debug('Match__c found - Name: ' + fixture.Name + ', ESPN_Event_ID__c: ' + fixture.ESPN_Event_ID__c);
                sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                    ? fixture.Competition__r.Sport__c : 'Soccer';
                System.debug('Calling getFixtureData with ESPN_Event_ID__c: ' + fixture.ESPN_Event_ID__c);
                return getFixtureData(recordId, fixture.ESPN_Event_ID__c);
                
            } else if (objectType == 'Competition__c') {
                System.debug('Processing Competition__c record...');
                Competition__c comp = [SELECT Id, Name, Sport__c, ESPN_League_ID__c FROM Competition__c WHERE Id = :recordId LIMIT 1];
                System.debug('Competition__c found - Name: ' + comp.Name + ', ESPN_League_ID__c: ' + comp.ESPN_League_ID__c);
                sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
                System.debug('Calling getCompetitionFixtures with ESPN_League_ID__c: ' + comp.ESPN_League_ID__c);
                return getCompetitionFixtures(recordId, comp.ESPN_League_ID__c);
            }
            
            System.debug('ERROR: Unsupported object type: ' + objectType);
            result.success = false;
            result.errorMessage = 'Unsupported object type: ' + objectType;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '=== ESPNActionController.getSportData EXCEPTION ===');
            System.debug(LoggingLevel.ERROR, 'Exception Type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Exception Message: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception Stack Trace: ' + e.getStackTraceString());
            result.success = false;
            result.errorMessage = 'Error syncing sport data: ' + e.getMessage();
        }
        
        System.debug('=== ESPNActionController.getSportData END ===');
        System.debug('Result - success: ' + result.success);
        System.debug('Result - message: ' + result.message);
        System.debug('Result - errorMessage: ' + result.errorMessage);
        return result;
    }
    
    /**
     * @description Get the appropriate sport handler based on sport type
     * @param sportType The sport type (Soccer, Cricket, AFL, Basketball, etc.)
     * @return ISportDataHandler The handler instance
     */
    private static ISportDataHandler getSportHandler(String sportType) {
        if (String.isBlank(sportType)) {
            sportType = 'Soccer'; // Default
        }
        
        switch on sportType {
            when 'Cricket' {
                return new CricketHandler();
            }
            when 'AFL' {
                return new AFLHandler();
            }
            when 'Basketball', 'NBA' {
                return new NBAHandler();
            }
            when else {
                return new SoccerHandler(); // Default
            }
        }
    }
    
    /**
     * @description Get team information from ESPN - validates fields, searches for ESPN Team ID if missing, then fetches details
     * @param recordId Account record ID
     * @return ESPNActionResult with team data
     */
    @AuraEnabled
    public static ESPNActionResult getTeamInformation(Id recordId) {
        System.debug('=== ESPNActionController.getTeamInformation START ===');
        System.debug('Input - recordId: ' + recordId);
        
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            // Step 1: Query Account with all relevant fields
            Account acc = [SELECT Id, Name, Type, Sport__c, ESPN_Team_ID__c,
                          Abbreviation__c, Logo_Url__c, Venue_Name__c
                          FROM Account WHERE Id = :recordId LIMIT 1];
            
            System.debug('Account - Name: ' + acc.Name + ', Type: ' + acc.Type + ', Sport__c: ' + acc.Sport__c);
            System.debug('Account - ESPN_Team_ID__c: ' + acc.ESPN_Team_ID__c);
            
            // Step 2: Validate required fields
            if (String.isBlank(acc.Name)) {
                result.success = false;
                result.errorMessage = 'Account Name is required. Please set the Account Name before syncing with ESPN.';
                System.debug('ERROR: Account Name is blank');
                return result;
            }
            
            if (acc.Type != 'Team') {
                result.success = false;
                result.errorMessage = 'This Account must have Type = "Team" to sync with ESPN. Please update the Account Type.';
                System.debug('ERROR: Account Type is not "Team": ' + acc.Type);
                return result;
            }
            
            if (String.isBlank(acc.Sport__c)) {
                result.success = false;
                result.errorMessage = 'Please set Sport on this Account (e.g., Soccer, Basketball, Cricket) before syncing with ESPN.';
                System.debug('ERROR: Sport__c is blank');
                return result;
            }
            
            String sportType = acc.Sport__c;
            System.debug('Validation passed - Sport Type: ' + sportType);
            
            // Step 3: Resolve ESPN Team ID if missing
            String espnTeamId = acc.ESPN_Team_ID__c;
            
            if (String.isBlank(espnTeamId)) {
                System.debug('ESPN Team ID is missing - searching ESPN by team name...');
                espnTeamId = searchTeamByName(acc.Name, sportType);
                
                if (String.isBlank(espnTeamId)) {
                    result.success = false;
                    result.errorMessage = 'Team "' + acc.Name + '" not found in ESPN database. Please verify the team name matches ESPN\'s database. Common issues: spelling, abbreviations (e.g., "Man United" vs "Manchester United").';
                    System.debug('ERROR: Team not found in ESPN');
                    return result;
                }
                
                // Update Account with ESPN Team ID
                System.debug('Found ESPN Team ID: ' + espnTeamId + ' - updating Account...');
                Account updateAcc = new Account(
                    Id = recordId,
                    ESPN_Team_ID__c = espnTeamId
                );
                update updateAcc;
                System.debug('Account updated with ESPN Team ID');
            } else {
                System.debug('ESPN Team ID already exists: ' + espnTeamId);
            }
            
            // Step 4: Fetch and update team details
            System.debug('Fetching detailed team information from ESPN...');
            return fetchAndUpdateTeamDetails(recordId, espnTeamId, sportType);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error syncing team data: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getTeamInformation EXCEPTION: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        System.debug('=== ESPNActionController.getTeamInformation END ===');
        return result;
    }
    
    /**
     * @description Search ESPN for team by name and return ESPN Team ID
     * @param teamName Team name to search for
     * @param sportType Sport type (Soccer, Basketball, etc.)
     * @return String ESPN Team ID if found, null otherwise
     */
    private static String searchTeamByName(String teamName, String sportType) {
        System.debug('=== searchTeamByName START ===');
        System.debug('Searching for team: ' + teamName + ' in sport: ' + sportType);
        
        try {
            // Normalize sport for ESPN API
            String espnSport = normalizeSportForESPN(sportType);
            String leagueCode = getDefaultLeagueCode(sportType);
            System.debug('ESPN Sport: ' + espnSport + ', League Code: ' + leagueCode);
            
            // Call ESPN API to get all teams for the league
            System.debug('Calling ESPNHttpService.getTeams...');
            ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(espnSport, leagueCode);
            System.debug('ESPN API Response - success: ' + response.success);
            System.debug('ESPN API Response - teams count: ' + (response.teams != null ? response.teams.size() : 0));
            
            if (response.success && response.teams != null) {
                // Find matching team (fuzzy match)
                for (ESPNHttpService.ESPNTeam team : response.teams) {
                    System.debug('Checking team: ' + team.name + ' (ID: ' + team.id + ')');
                    
                    // Try multiple matching strategies
                    if (team.name.equalsIgnoreCase(teamName) ||
                        team.name.containsIgnoreCase(teamName) ||
                        teamName.containsIgnoreCase(team.name) ||
                        (team.shortName != null && team.shortName.equalsIgnoreCase(teamName))) {
                        
                        System.debug('MATCH FOUND: ' + team.name + ' (ID: ' + team.id + ')');
                        return team.id;
                    }
                }
                
                System.debug('No match found for team: ' + teamName);
            } else {
                System.debug('ERROR: ESPN API call failed - ' + response.errorMessage);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'searchTeamByName EXCEPTION: ' + e.getMessage());
        }
        
        System.debug('=== searchTeamByName END (no match) ===');
        return null;
    }
    
    /**
     * @description Fetch detailed team information from ESPN and update Account
     * @param recordId Account record ID
     * @param espnTeamId ESPN Team ID
     * @param sportType Sport type
     * @return ESPNActionResult with update status
     */
    private static ESPNActionResult fetchAndUpdateTeamDetails(Id recordId, String espnTeamId, String sportType) {
        System.debug('=== fetchAndUpdateTeamDetails START ===');
        System.debug('recordId: ' + recordId + ', espnTeamId: ' + espnTeamId + ', sportType: ' + sportType);
        
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            // Normalize sport for ESPN API
            String espnSport = normalizeSportForESPN(sportType);
            String leagueCode = getDefaultLeagueCode(sportType);
            
            // Call ESPN API to get all teams (we'll find our team in the list)
            System.debug('Fetching teams from ESPN...');
            ESPNHttpService.ESPNTeamsResponse response = ESPNHttpService.getTeams(espnSport, leagueCode);
            
            if (response.success && response.teams != null) {
                // Find our team by ESPN ID
                ESPNHttpService.ESPNTeam teamData = null;
                for (ESPNHttpService.ESPNTeam team : response.teams) {
                    if (team.id == espnTeamId) {
                        teamData = team;
                        break;
                    }
                }
                
                if (teamData != null) {
                    System.debug('Found team data: ' + teamData.name);
                    
                    // Update Account with team details
                    Account updatedAcc = new Account(
                        Id = recordId,
                        ESPN_Team_ID__c = teamData.id,
                        Sport__c = sportType, // Ensure it's set
                        Abbreviation__c = teamData.shortName,
                        Logo_Url__c = teamData.logoUrl,
                        Venue_Name__c = teamData.venueName
                    );
                    update updatedAcc;
                    
                    System.debug('Account updated successfully with team details');
                    
                    result.success = true;
                    result.message = 'Team information synced successfully! Updated: ' + teamData.name;
                    result.data = JSON.serialize(teamData);
                } else {
                    result.success = false;
                    result.errorMessage = 'Team data not found in ESPN response for ID: ' + espnTeamId;
                    System.debug('ERROR: Team not found in response');
                }
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage != null ? response.errorMessage : 'Failed to fetch team data from ESPN';
                System.debug('ERROR: ESPN API call failed');
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error fetching team details: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'fetchAndUpdateTeamDetails EXCEPTION: ' + e.getMessage());
        }
        
        System.debug('=== fetchAndUpdateTeamDetails END ===');
        return result;
    }
    
    /**
     * @description Get player information from ESPN based on Contact name
     * @param recordId Contact record ID
     * @param playerName Player name to search for
     * @return ESPNActionResult with player data
     */
    @AuraEnabled
    public static ESPNActionResult getPlayerInformation(Id recordId, String playerName) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting player info for ' + playerName);
            
            // Get Contact to find associated team
            Contact player = [SELECT Id, Name, Current_Team__c, Current_Team__r.ESPN_Team_ID__c, Current_Team__r.Sport__c 
                             FROM Contact 
                             WHERE Id = :recordId LIMIT 1];
            
            if (player.Current_Team__c == null || player.Current_Team__r.ESPN_Team_ID__c == null) {
                result.success = false;
                result.errorMessage = 'Please link this Contact to a Team with ESPN ID first.';
                return result;
            }
            
            // Get sport type and normalize for ESPN API
            String sportType = String.isNotBlank(player.Current_Team__r.Sport__c) 
                ? player.Current_Team__r.Sport__c : 'Soccer';
            String espnSport = normalizeSportForESPN(sportType);
            String leagueCode = getDefaultLeagueCode(sportType);
            
            // Get team roster from ESPN
            String teamId = player.Current_Team__r.ESPN_Team_ID__c;
            ESPNHttpService.ESPNRosterResponse response = ESPNHttpService.getTeamRoster(espnSport, leagueCode, teamId);
            
            if (response.success && response.athletes != null) {
                // Get sport handler for mapping
                ISportDataHandler handler = getSportHandler(sportType);
                
                // Find matching player
                for (ESPNHttpService.ESPNAthlete athlete : response.athletes) {
                    if (athlete.displayName.containsIgnoreCase(playerName) || playerName.containsIgnoreCase(athlete.displayName)) {
                        // Convert athlete to Map for handler
                        Map<String, Object> athleteMap = new Map<String, Object>{
                            'id' => athlete.id,
                            'firstName' => athlete.firstName,
                            'lastName' => athlete.lastName,
                            'position' => athlete.position,
                            'jersey' => athlete.jersey,
                            'headshotUrl' => athlete.headshotUrl
                        };
                        
                        // Use handler to map player data
                        Contact mappedPlayer = handler.mapPlayer(athleteMap, player.Current_Team__c);
                        mappedPlayer.Id = recordId; // Set the record ID
                        
                        update mappedPlayer;
                        
                        result.success = true;
                        result.message = 'Player information updated successfully!';
                        result.data = JSON.serialize(athlete);
                        return result;
                    }
                }
                
                result.success = false;
                result.errorMessage = 'Player "' + playerName + '" not found in team roster.';
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getPlayerInformation error: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get fixtures for a league from ESPN
     * @param recordId Opportunity_Group__c record ID
     * @param leagueCode ESPN League code (e.g., eng.1)
     * @return ESPNActionResult with fixtures data
     */
    @AuraEnabled
    public static ESPNActionResult getLeagueFixtures(Id recordId, String leagueCode) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting fixtures for league ' + leagueCode);
            
            // Get Opportunity_Group__c to determine sport type
            Opportunity_Group__c oppGroup = [SELECT Id, Name, Sport__c, ESPN_League_ID__c 
                                             FROM Opportunity_Group__c 
                                             WHERE Id = :recordId LIMIT 1];
            
            String sportType = String.isNotBlank(oppGroup.Sport__c) ? oppGroup.Sport__c : 'Soccer';
            String espnSport = normalizeSportForESPN(sportType);
            String actualLeagueCode = String.isNotBlank(leagueCode) ? leagueCode : oppGroup.ESPN_League_ID__c;
            
            if (String.isBlank(actualLeagueCode)) {
                actualLeagueCode = getDefaultLeagueCode(sportType);
            }
            
            // Get fixtures for today and next 7 days
            Date today = Date.today();
            String dateStr = today.year() + String.valueOf(today.month()).leftPad(2, '0') + String.valueOf(today.day()).leftPad(2, '0');
            
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, actualLeagueCode, dateStr);
            
            if (response.success && response.events != null && !response.events.isEmpty()) {
                // Get sport handler
                ISportDataHandler handler = getSportHandler(sportType);
                
                // Create Opportunity records for each fixture
                List<Opportunity> fixtures = new List<Opportunity>();
                Map<String, Account> teamCache = new Map<String, Account>();
                
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    // Convert event to Map for handler
                    Map<String, Object> eventMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(event));
                    
                    // Use handler to map fixture
                    Opportunity fixture = handler.mapFixture(eventMap, recordId);
                    
                    // Find or create teams
                    // Note: In production, you'd want to upsert teams first, then link them
                    // For now, we'll set the ESPN IDs and let the system handle team creation
                    
                    fixtures.add(fixture);
                }
                
                if (!fixtures.isEmpty()) {
                    upsert fixtures ESPN_ID__c;
                    result.success = true;
                    result.message = 'Created/Updated ' + fixtures.size() + ' fixtures for ' + oppGroup.Name;
                    result.data = JSON.serialize(fixtures);
                } else {
                    result.success = false;
                    result.errorMessage = 'No fixtures found to create.';
                }
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage != null ? response.errorMessage : 'No fixtures found.';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getLeagueFixtures error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Get live fixture information from ESPN
     * @param recordId Opportunity record ID
     * @param espnEventId ESPN Event ID
     * @return ESPNActionResult with live match data
     */
    @AuraEnabled
    public static ESPNActionResult getFixtureInformation(Id recordId, String espnEventId) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting fixture info for event ' + espnEventId);
            
            // Get Opportunity to determine sport type
            Opportunity opp = [SELECT Id, Name, ESPN_ID__c, Opportunity_Group__r.Sport__c, 
                              Opportunity_Group__r.ESPN_League_ID__c
                              FROM Opportunity WHERE Id = :recordId LIMIT 1];
            
            String sportType = (opp.Opportunity_Group__c != null && opp.Opportunity_Group__r.Sport__c != null)
                ? opp.Opportunity_Group__r.Sport__c : 'Soccer';
            String espnSport = normalizeSportForESPN(sportType);
            String leagueCode = (opp.Opportunity_Group__c != null && opp.Opportunity_Group__r.ESPN_League_ID__c != null)
                ? opp.Opportunity_Group__r.ESPN_League_ID__c : getDefaultLeagueCode(sportType);
            
            // Use ESPN_ID__c if available, otherwise use provided espnEventId
            String eventId = String.isNotBlank(opp.ESPN_ID__c) ? opp.ESPN_ID__c : espnEventId;
            
            if (String.isBlank(eventId)) {
                // Try to search by name and date
                Date today = Date.today();
                String dateStr = today.year() + String.valueOf(today.month()).leftPad(2, '0') + String.valueOf(today.day()).leftPad(2, '0');
                
                ESPNHttpService.ESPNScoreboardResponse scoreboardResponse = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
                
                if (scoreboardResponse.success && scoreboardResponse.events != null) {
                    // Find matching fixture by name
                    for (ESPNHttpService.ESPNEvent event : scoreboardResponse.events) {
                        if (event.name.containsIgnoreCase(opp.Name) || opp.Name.containsIgnoreCase(event.name)) {
                            eventId = event.id;
                            break;
                        }
                    }
                }
            }
            
            if (String.isBlank(eventId)) {
                result.success = false;
                result.errorMessage = 'ESPN Event ID not found. Please set ESPN_ID__c on the Opportunity or provide event ID.';
                return result;
            }
            
            // Get live feed from ESPN
            ESPNHttpService.ESPNLiveFeedResponse response = ESPNHttpService.getLiveFeed(espnSport, leagueCode, eventId);
            
            if (response.success) {
                // Get sport handler
                ISportDataHandler handler = getSportHandler(sportType);
                
                // Update Opportunity with scores using new field names
                Opportunity updatedOpp = new Opportunity(
                    Id = recordId,
                    ESPN_ID__c = eventId,
                    Home_Score_Total__c = response.homeScore != null ? Decimal.valueOf(response.homeScore) : null,
                    Away_Score_Total__c = response.awayScore != null ? Decimal.valueOf(response.awayScore) : null,
                    Match_Status__c = response.matchStatus
                );
                
                // Update current period if available
                if (String.isNotBlank(response.currentPeriod)) {
                    updatedOpp.Current_Period__c = response.currentPeriod;
                }
                
                update updatedOpp;
                
                // TODO: Create Live_Feed__c records for match events (object not yet created)
                // List<Live_Feed__c> feedEvents = new List<Live_Feed__c>();
                // if (response.matchEvents != null) {
                //     for (ESPNHttpService.ESPNMatchEvent event : response.matchEvents) {
                //         Live_Feed__c feedEvent = new Live_Feed__c(
                //             Match__c = recordId,
                //             Event_Type__c = event.eventType,
                //             Event_Minute__c = event.minute != null ? Integer.valueOf(event.minute.replaceAll('[^0-9]', '')) : null,
                //             Event_Description__c = event.description,
                //             Timestamp__c = System.now(),
                //             ESPN_Event_ID__c = eventId + '-' + event.minute // Unique ID
                //         );
                //         feedEvents.add(feedEvent);
                //     }
                // }
                // 
                // if (!feedEvents.isEmpty()) {
                //     upsert feedEvents ESPN_Event_ID__c;
                // }
                
                result.success = true;
                result.message = 'Fixture updated successfully';
                result.data = JSON.serialize(response);
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getFixtureInformation error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Get fixture data from ESPN for Match__c records
     * @param recordId Match__c record ID
     * @param espnEventId ESPN Event ID
     * @return ESPNActionResult with live match data
     */
    @AuraEnabled
    public static ESPNActionResult getFixtureData(Id recordId, String espnEventId) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting fixture data for event ' + espnEventId);
            
            // Get Match__c to determine sport type
            Match__c fixture = [SELECT Id, Name, ESPN_Event_ID__c, Competition__c, Competition__r.Sport__c, 
                                  Competition__r.ESPN_League_ID__c, Home_Team__c, Away_Team__c,
                                  Match_Date_Time__c
                                  FROM Match__c WHERE Id = :recordId LIMIT 1];
            
            String sportType = (fixture.Competition__c != null && fixture.Competition__r.Sport__c != null)
                ? fixture.Competition__r.Sport__c : 'Soccer';
            String espnSport = normalizeSportForESPN(sportType);
            String leagueCode = (fixture.Competition__c != null && fixture.Competition__r.ESPN_League_ID__c != null)
                ? fixture.Competition__r.ESPN_League_ID__c : getDefaultLeagueCode(sportType);
            
            // Use ESPN_Event_ID__c if available, otherwise use provided espnEventId
            String eventId = String.isNotBlank(fixture.ESPN_Event_ID__c) ? fixture.ESPN_Event_ID__c : espnEventId;
            
            if (String.isBlank(eventId)) {
                // Try to search by date and teams using resolver
                eventId = ESPNEventIdResolver.resolveEventId(fixture, espnSport, leagueCode);
            }
            
            if (String.isBlank(eventId)) {
                result.success = false;
                result.errorMessage = 'ESPN Event ID not found. Please set ESPN_Event_ID__c on the Fixture or ensure the fixture date and teams are correct.';
                return result;
            }
            
            // Get live feed from ESPN
            ESPNHttpService.ESPNLiveFeedResponse response = ESPNHttpService.getLiveFeed(espnSport, leagueCode, eventId);
            
            if (response.success) {
                // Update Match__c with scores
                Match__c updatedFixture = new Match__c(
                    Id = recordId,
                    ESPN_Event_ID__c = eventId,
                    Home_Score_Final__c = response.homeScore != null ? Decimal.valueOf(response.homeScore) : null,
                    Away_Score_Final__c = response.awayScore != null ? Decimal.valueOf(response.awayScore) : null,
                    Status__c = mapMatchStatusToFixtureStatus(response.matchStatus)
                );
                
                update updatedFixture;
                
                result.success = true;
                result.message = 'Fixture updated successfully! Score: ' + response.homeScore + ' - ' + response.awayScore;
                result.data = JSON.serialize(response);
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getFixtureData error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Get fixtures for a Competition__c from ESPN
     * @param recordId Competition__c record ID
     * @param leagueCode ESPN League code (e.g., eng.1)
     * @return ESPNActionResult with fixtures data
     */
    @AuraEnabled
    public static ESPNActionResult getCompetitionFixtures(Id recordId, String leagueCode) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting fixtures for Competition ' + recordId);
            
            // Get Competition__c to determine sport type
            Competition__c comp = [SELECT Id, Name, Sport__c, ESPN_League_ID__c 
                                   FROM Competition__c 
                                   WHERE Id = :recordId LIMIT 1];
            
            String sportType = String.isNotBlank(comp.Sport__c) ? comp.Sport__c : 'Soccer';
            String espnSport = normalizeSportForESPN(sportType);
            String actualLeagueCode = String.isNotBlank(leagueCode) ? leagueCode : comp.ESPN_League_ID__c;
            
            if (String.isBlank(actualLeagueCode)) {
                actualLeagueCode = getDefaultLeagueCode(sportType);
            }
            
            // Get fixtures for today and next 7 days
            Date today = Date.today();
            String dateStr = today.year() + String.valueOf(today.month()).leftPad(2, '0') + String.valueOf(today.day()).leftPad(2, '0');
            
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, actualLeagueCode, dateStr);
            
            if (response.success && response.events != null && !response.events.isEmpty()) {
                // Get sport handler
                ISportDataHandler handler = getSportHandler(sportType);
                
                // Create/update Match__c records for each event
                List<Match__c> fixtures = new List<Match__c>();
                Set<String> teamEspnIds = new Set<String>();
                
                // First pass: collect all team ESPN IDs
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    if (event.homeTeamId != null) teamEspnIds.add(event.homeTeamId);
                    if (event.awayTeamId != null) teamEspnIds.add(event.awayTeamId);
                }
                
                // Query existing teams
                Map<String, Id> teamEspnIdToAccountId = new Map<String, Id>();
                for (Account acc : [SELECT Id, ESPN_Team_ID__c FROM Account WHERE ESPN_Team_ID__c IN :teamEspnIds]) {
                    teamEspnIdToAccountId.put(acc.ESPN_Team_ID__c, acc.Id);
                }
                
                // Create missing teams (Home_Team__c and Away_Team__c are required)
                Map<String, ESPNHttpService.ESPNEvent> missingTeamEvents = new Map<String, ESPNHttpService.ESPNEvent>();
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    if (event.homeTeamId != null && !teamEspnIdToAccountId.containsKey(event.homeTeamId)) {
                        missingTeamEvents.put(event.homeTeamId, event);
                    }
                    if (event.awayTeamId != null && !teamEspnIdToAccountId.containsKey(event.awayTeamId)) {
                        missingTeamEvents.put(event.awayTeamId, event);
                    }
                }
                
                // Insert placeholder teams for missing team IDs
                if (!missingTeamEvents.isEmpty()) {
                    List<Account> newTeams = new List<Account>();
                    for (String espnTeamId : missingTeamEvents.keySet()) {
                        ESPNHttpService.ESPNEvent event = missingTeamEvents.get(espnTeamId);
                        // Use team name from event if available
                        String teamName = (espnTeamId == event.homeTeamId && String.isNotBlank(event.homeTeamName)) 
                            ? event.homeTeamName 
                            : (espnTeamId == event.awayTeamId && String.isNotBlank(event.awayTeamName)) 
                                ? event.awayTeamName 
                                : 'Team ' + espnTeamId;
                        
                        newTeams.add(new Account(
                            Name = teamName,
                            Type = 'Team',
                            Sport__c = sportType,
                            ESPN_Team_ID__c = espnTeamId
                        ));
                    }
                    insert newTeams;
                    System.debug('Created ' + newTeams.size() + ' missing teams');
                    
                    // Add new teams to the map
                    for (Account acc : newTeams) {
                        teamEspnIdToAccountId.put(acc.ESPN_Team_ID__c, acc.Id);
                    }
                }
                
                // Second pass: create fixtures (now all teams should exist)
                for (ESPNHttpService.ESPNEvent event : response.events) {
                    // Skip if we still don't have both teams (shouldn't happen but safety check)
                    if (event.homeTeamId == null || event.awayTeamId == null) {
                        System.debug('Skipping fixture - missing team ID: ' + event.name);
                        continue;
                    }
                    if (!teamEspnIdToAccountId.containsKey(event.homeTeamId) || 
                        !teamEspnIdToAccountId.containsKey(event.awayTeamId)) {
                        System.debug('Skipping fixture - team not found: ' + event.name);
                        continue;
                    }
                    
                    Match__c fixture = new Match__c(
                        ESPN_Event_ID__c = event.id,
                        Competition__c = recordId,
                        Match_Date_Time__c = parseESPNDate(event.eventDate),
                        Status__c = mapMatchStatusToFixtureStatus(event.status),
                        Venue__c = event.venueName,
                        Home_Team__c = teamEspnIdToAccountId.get(event.homeTeamId),
                        Away_Team__c = teamEspnIdToAccountId.get(event.awayTeamId)
                    );
                    
                    // Set scores if available
                    if (event.homeScore != null) {
                        fixture.Home_Score_Final__c = Decimal.valueOf(event.homeScore);
                    }
                    if (event.awayScore != null) {
                        fixture.Away_Score_Final__c = Decimal.valueOf(event.awayScore);
                    }
                    
                    fixtures.add(fixture);
                }
                
                if (!fixtures.isEmpty()) {
                    upsert fixtures ESPN_Event_ID__c;
                    result.success = true;
                    result.message = 'Created/Updated ' + fixtures.size() + ' fixtures for ' + comp.Name;
                    result.data = JSON.serialize(fixtures);
                } else {
                    result.success = false;
                    result.errorMessage = 'No fixtures found to create.';
                }
            } else {
                result.success = false;
                result.errorMessage = response.errorMessage != null ? response.errorMessage : 'No fixtures found for this date.';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getCompetitionFixtures error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Map ESPN match status to Match__c Status picklist value
     * @param espnStatus ESPN match status string
     * @return String Match__c Status value
     */
    private static String mapMatchStatusToFixtureStatus(String espnStatus) {
        if (String.isBlank(espnStatus)) {
            return 'Scheduled';
        }
        
        String status = espnStatus.toLowerCase();
        
        if (status.contains('final') || status.contains('ft') || status.contains('completed')) {
            return 'Completed';
        } else if (status.contains('live') || status.contains('in progress') || status.contains('1h') || status.contains('2h') || status.contains('halftime')) {
            return 'In Progress';
        } else if (status.contains('postponed')) {
            return 'Postponed';
        } else if (status.contains('cancelled') || status.contains('canceled')) {
            return 'Cancelled';
        } else {
            return 'Scheduled';
        }
    }
    
    /**
     * @description Parse ESPN date string to Datetime
     * @param espnDate ESPN date string (ISO 8601 format)
     * @return Datetime Parsed datetime or null
     */
    private static Datetime parseESPNDate(String espnDate) {
        if (String.isBlank(espnDate)) {
            return null;
        }
        
        try {
            // ESPN uses ISO 8601 format: 2025-01-15T19:45:00Z
            return (Datetime)JSON.deserialize('"' + espnDate + '"', Datetime.class);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse ESPN date: ' + espnDate);
            return null;
        }
    }
    
    /**
     * @description Get lineup information (load players from team)
     * @param recordId Lineup__c record ID
     * @param teamId Account (Team) ID
     * @return ESPNActionResult with roster data
     */
    @AuraEnabled
    public static ESPNActionResult getLineupInformation(Id recordId, Id teamId) {
        ESPNActionResult result = new ESPNActionResult();
        
        try {
            System.debug('ESPNActionController: Getting lineup info for team ' + teamId);
            
            // Query Contacts linked to this team
            List<Contact> players = [SELECT Id, Name, Jersey_Number__c, Position__c, Profile_Image_URL__c
                                    FROM Contact
                                    WHERE Current_Team__c = :teamId
                                    AND Player_Role__c = 'Player'
                                    ORDER BY Jersey_Number__c];
            
            if (players.isEmpty()) {
                result.success = false;
                result.errorMessage = 'No players found for this team. Please link players first.';
                return result;
            }
            
            result.success = true;
            result.message = 'Found ' + players.size() + ' players';
            result.data = JSON.serialize(players);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'ESPNActionController.getLineupInformation error: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Normalize sport type for ESPN API calls
     * @param sportType Internal sport type (Soccer, Basketball, etc.)
     * @return String ESPN API sport code
     */
    private static String normalizeSportForESPN(String sportType) {
        if (String.isBlank(sportType)) {
            return 'soccer';
        }
        
        switch on sportType.toLowerCase() {
            when 'basketball', 'nba' {
                return 'basketball';
            }
            when 'cricket' {
                return 'cricket';
            }
            when 'afl' {
                return 'afl';
            }
            when 'nfl', 'football' {
                return 'football';
            }
            when else {
                return 'soccer';
            }
        }
    }
    
    /**
     * @description Get default league code for a sport type
     * @param sportType Sport type
     * @return String Default league code
     */
    private static String getDefaultLeagueCode(String sportType) {
        if (String.isBlank(sportType)) {
            return 'eng.1';
        }
        
        switch on sportType.toLowerCase() {
            when 'basketball', 'nba' {
                return 'nba';
            }
            when 'cricket' {
                return 'icc';
            }
            when 'afl' {
                return 'afl';
            }
            when 'nfl', 'football' {
                return 'nfl';
            }
            when else {
                return 'eng.1'; // Premier League default
            }
        }
    }
    
    /**
     * @description Wrapper class for unified API responses
     */
    public class ESPNActionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String data; // JSON string
        @AuraEnabled public String errorMessage;
        
        public ESPNActionResult() {
            this.success = false;
            this.message = '';
            this.data = '';
            this.errorMessage = '';
        }
    }
}

