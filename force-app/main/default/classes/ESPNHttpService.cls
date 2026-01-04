/**
 * @description Centralized HTTP service for all ESPN API interactions
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * Best Practices Implemented:
 * - Centralized HTTP callout logic
 * - Proper error handling and logging
 * - Response wrapper classes for type safety
 * - Separation of concerns (HTTP layer vs business logic)
 * - Reusable utility methods
 * - Named Credential ready (future enhancement)
 */
public with sharing class ESPNHttpService {
    
    // Constants
    private static final String ESPN_BASE_URL = 'https://site.web.api.espn.com/apis/site/v2/sports';
    private static final Integer HTTP_TIMEOUT = 120000; // 120 seconds
    private static final String HTTP_METHOD_GET = 'GET';
    
    // Sport path mappings
    private static final Map<String, String> SPORT_PATH_MAP = new Map<String, String>{
        'soccer' => '/soccer/',
        'football' => '/football/', // American football (NFL)
        'basketball' => '/basketball/',
        'cricket' => '/cricket/'
    };
    
    /**
     * @description Get all teams for a specific league
     * @param sport The sport type (soccer, basketball, cricket, football)
     * @param leagueCode The league code (e.g., eng.1, uefa.champions, nba)
     * @return ESPNTeamsResponse Parsed team data
     */
    public static ESPNTeamsResponse getTeams(String sport, String leagueCode) {
        System.debug('=== ESPNHttpService.getTeams START ===');
        System.debug('Input - sport: ' + sport);
        System.debug('Input - leagueCode: ' + leagueCode);
        
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/teams';
        
        System.debug('Built sportPath: ' + sportPath);
        System.debug('Full ESPN API URL: ' + endpoint);
        
        HttpResponse response = makeCallout(endpoint);
        
        System.debug('HTTP Response Status Code: ' + response.getStatusCode());
        System.debug('HTTP Response Status: ' + response.getStatus());
        
        if (response.getStatusCode() == 200) {
            System.debug('Successfully received response from ESPN API');
            System.debug('Response body length: ' + response.getBody().length());
            ESPNTeamsResponse result = parseTeamsResponse(response.getBody());
            System.debug('Parsed teams count: ' + (result.teams != null ? result.teams.size() : 0));
            System.debug('=== ESPNHttpService.getTeams END (SUCCESS) ===');
            return result;
        } else {
            System.debug('ERROR: Failed to fetch teams - Status: ' + response.getStatus());
            System.debug('Response body: ' + response.getBody());
            System.debug('=== ESPNHttpService.getTeams END (ERROR) ===');
            throw new ESPNException('Failed to fetch teams: ' + response.getStatus());
        }
    }
    
    /**
     * @description Get roster/squad for a specific team
     * @param sport The sport type
     * @param leagueCode The league code
     * @param teamId ESPN team ID
     * @return ESPNRosterResponse Parsed roster data
     */
    public static ESPNRosterResponse getTeamRoster(String sport, String leagueCode, String teamId) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/teams/' + teamId + '/roster';
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseRosterResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch roster for team ' + teamId + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Get fixtures/scoreboard for a specific date
     * @param sport The sport type
     * @param leagueCode The league code
     * @param dateYYYYMMDD Date in YYYYMMDD format (e.g., 20251127)
     * @return ESPNScoreboardResponse Parsed fixture data
     */
    public static ESPNScoreboardResponse getFixtures(String sport, String leagueCode, String dateYYYYMMDD) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/scoreboard?dates=' + dateYYYYMMDD;
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseScoreboardResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch fixtures for ' + dateYYYYMMDD + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Get scoreboard for date range
     * @param sport The sport type
     * @param leagueCode The league code
     * @param startDateYYYYMMDD Start date in YYYYMMDD format
     * @param endDateYYYYMMDD End date in YYYYMMDD format
     * @return ESPNScoreboardResponse Parsed fixture data
     */
    public static ESPNScoreboardResponse getFixturesForDateRange(String sport, String leagueCode, String startDateYYYYMMDD, String endDateYYYYMMDD) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/scoreboard?dates=' + startDateYYYYMMDD + '-' + endDateYYYYMMDD;
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseScoreboardResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch fixtures for date range ' + startDateYYYYMMDD + '-' + endDateYYYYMMDD + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Format Salesforce Date to ESPN format (YYYYMMDD)
     * @param dt Salesforce Date object
     * @return String Date in YYYYMMDD format
     */
    public static String formatDateForESPN(Date dt) {
        return dt.year() + 
               String.valueOf(dt.month()).leftPad(2, '0') + 
               String.valueOf(dt.day()).leftPad(2, '0');
    }
    
    /**
     * @description Get team's full schedule (all fixtures for the season)
     * @param sport The sport type
     * @param leagueCode The league code
     * @param teamId ESPN team ID
     * @return ESPNScheduleResponse Parsed schedule data
     */
    public static ESPNScheduleResponse getTeamSchedule(String sport, String leagueCode, String teamId) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/teams/' + teamId + '/schedule';
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseScheduleResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch schedule for team ' + teamId + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Get live match summary with real-time events (goals, cards, subs)
     * @param sport The sport type
     * @param leagueCode The league code
     * @param eventId ESPN event/fixture ID
     * @return ESPNLiveFeedResponse Parsed live match data with events
     */
    public static ESPNLiveFeedResponse getLiveFeed(String sport, String leagueCode, String eventId) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/summary?event=' + eventId;
        
        System.debug('ESPNHttpService: Fetching live feed - ' + endpoint);
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseLiveFeedResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch live feed for event ' + eventId + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Get detailed athlete/player information
     * @param sport The sport type
     * @param leagueCode The league code
     * @param athleteId ESPN athlete/player ID
     * @return ESPNAthleteResponse Parsed player data
     */
    public static ESPNAthleteResponse getAthleteDetails(String sport, String leagueCode, String athleteId) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/athletes/' + athleteId;
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseAthleteResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch athlete ' + athleteId + ': ' + response.getStatus());
        }
    }
    
    /**
     * @description Get comprehensive match summary with lineups, commentary, and periods
     * @param sport The sport type
     * @param leagueCode The league code
     * @param eventId ESPN event/fixture ID
     * @return ESPNMatchSummaryResponse Parsed comprehensive match data
     */
    public static ESPNMatchSummaryResponse getMatchSummaryDetailed(String sport, String leagueCode, String eventId) {
        String sportPath = buildSportPath(sport, leagueCode);
        String endpoint = ESPN_BASE_URL + sportPath + '/summary?event=' + eventId;
        
        System.debug('ESPNHttpService: Fetching detailed match summary - ' + endpoint);
        
        HttpResponse response = makeCallout(endpoint);
        
        if (response.getStatusCode() == 200) {
            return parseMatchSummaryResponse(response.getBody());
        } else {
            throw new ESPNException('Failed to fetch match summary for event ' + eventId + ': ' + response.getStatus());
        }
    }
    
    // ========================================
    // PRIVATE HELPER METHODS
    // ========================================
    
    /**
     * @description Make HTTP GET callout to ESPN API
     * @param endpoint Full endpoint URL
     * @return HttpResponse The response object
     */
    @TestVisible
    private static HttpResponse makeCallout(String endpoint) {
        System.debug('=== ESPNHttpService.makeCallout START ===');
        System.debug('Endpoint URL: ' + endpoint);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(endpoint);
        request.setMethod(HTTP_METHOD_GET);
        request.setTimeout(HTTP_TIMEOUT);
        request.setHeader('Accept', 'application/json');
        
        System.debug('ESPNHttpService: Calling - ' + endpoint);
        
        try {
            HttpResponse response = http.send(request);
            System.debug('ESPNHttpService: Response Status - ' + response.getStatusCode());
            return response;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ESPNHttpService: Callout failed - ' + e.getMessage());
            throw new ESPNException('HTTP Callout failed: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Build sport path from sport and league code
     * @param sport The sport type
     * @param leagueCode The league code
     * @return String The path segment (e.g., /soccer/eng.1)
     */
    @TestVisible
    private static String buildSportPath(String sport, String leagueCode) {
        String sportLower = sport.toLowerCase();
        
        if (!SPORT_PATH_MAP.containsKey(sportLower)) {
            throw new ESPNException('Unsupported sport: ' + sport);
        }
        
        return SPORT_PATH_MAP.get(sportLower) + leagueCode;
    }
    
    // ========================================
    // JSON PARSING METHODS
    // ========================================
    
    /**
     * @description Parse teams API response
     */
    private static ESPNTeamsResponse parseTeamsResponse(String jsonBody) {
        ESPNTeamsResponse result = new ESPNTeamsResponse();
        result.teams = new List<ESPNTeam>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> sports = (List<Object>) responseMap.get('sports');
            
            if (sports != null && !sports.isEmpty()) {
                Map<String, Object> sportData = (Map<String, Object>) sports[0];
                List<Object> leagues = (List<Object>) sportData.get('leagues');
                
                if (leagues != null && !leagues.isEmpty()) {
                    Map<String, Object> league = (Map<String, Object>) leagues[0];
                    List<Object> teams = (List<Object>) league.get('teams');
                    
                    if (teams != null) {
                        for (Object teamWrapper : teams) {
                            Map<String, Object> teamData = (Map<String, Object>) teamWrapper;
                            Map<String, Object> team = (Map<String, Object>) teamData.get('team');
                            
                            if (team != null) {
                                ESPNTeam espnTeam = new ESPNTeam();
                                espnTeam.id = (String) team.get('id');
                                espnTeam.name = (String) team.get('displayName');
                                espnTeam.shortName = (String) team.get('shortDisplayName');
                                espnTeam.abbreviation = (String) team.get('abbreviation');
                                
                                // Get logo
                                List<Object> logos = (List<Object>) team.get('logos');
                                if (logos != null && !logos.isEmpty()) {
                                    Map<String, Object> logo = (Map<String, Object>) logos[0];
                                    espnTeam.logoUrl = (String) logo.get('href');
                                }
                                
                                // Get venue (if available)
                                Map<String, Object> venue = (Map<String, Object>) team.get('venue');
                                if (venue != null) {
                                    espnTeam.venueName = (String) venue.get('fullName');
                                }
                                
                                result.teams.add(espnTeam);
                            }
                        }
                    }
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse teams response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse roster API response
     */
    private static ESPNRosterResponse parseRosterResponse(String jsonBody) {
        ESPNRosterResponse result = new ESPNRosterResponse();
        result.athletes = new List<ESPNAthlete>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> athletes = (List<Object>) responseMap.get('athletes');
            
            if (athletes != null) {
                for (Object athleteObj : athletes) {
                    Map<String, Object> athleteData = (Map<String, Object>) athleteObj;
                    
                    ESPNAthlete athlete = new ESPNAthlete();
                    athlete.id = (String) athleteData.get('id');
                    athlete.displayName = (String) athleteData.get('displayName');
                    athlete.fullName = (String) athleteData.get('fullName');
                    
                    // Parse firstName and lastName from fullName or displayName
                    String fullName = athlete.fullName != null ? athlete.fullName : athlete.displayName;
                    if (String.isNotBlank(fullName)) {
                        List<String> nameParts = fullName.split(' ', 2);
                        athlete.firstName = nameParts.size() > 0 ? nameParts[0] : '';
                        athlete.lastName = nameParts.size() > 1 ? nameParts[1] : '';
                    }
                    
                    athlete.jersey = String.valueOf(athleteData.get('jersey'));
                    
                    // Get position
                    Map<String, Object> position = (Map<String, Object>) athleteData.get('position');
                    if (position != null) {
                        athlete.position = (String) position.get('displayName');
                    }
                    
                    // Get headshot
                    Map<String, Object> headshot = (Map<String, Object>) athleteData.get('headshot');
                    if (headshot != null) {
                        athlete.headshotUrl = (String) headshot.get('href');
                    }
                    
                    result.athletes.add(athlete);
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse roster response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse scoreboard API response (fixtures)
     */
    private static ESPNScoreboardResponse parseScoreboardResponse(String jsonBody) {
        ESPNScoreboardResponse result = new ESPNScoreboardResponse();
        result.events = new List<ESPNEvent>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> events = (List<Object>) responseMap.get('events');
            
            if (events != null) {
                for (Object eventObj : events) {
                    Map<String, Object> eventData = (Map<String, Object>) eventObj;
                    ESPNEvent event = parseEventData(eventData);
                    result.events.add(event);
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse scoreboard response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse schedule API response (team fixtures)
     */
    private static ESPNScheduleResponse parseScheduleResponse(String jsonBody) {
        ESPNScheduleResponse result = new ESPNScheduleResponse();
        result.events = new List<ESPNEvent>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> events = (List<Object>) responseMap.get('events');
            
            if (events != null) {
                for (Object eventObj : events) {
                    Map<String, Object> eventData = (Map<String, Object>) eventObj;
                    ESPNEvent event = parseEventData(eventData);
                    result.events.add(event);
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse schedule response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse live feed API response (match summary with events)
     */
    private static ESPNLiveFeedResponse parseLiveFeedResponse(String jsonBody) {
        ESPNLiveFeedResponse result = new ESPNLiveFeedResponse();
        result.matchEvents = new List<ESPNMatchEvent>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            
            // Parse header (basic match info)
            Map<String, Object> header = (Map<String, Object>) responseMap.get('header');
            if (header != null) {
                Map<String, Object> competition = (Map<String, Object>) header.get('competition');
                if (competition != null) {
                    result.matchStatus = (String) competition.get('status');
                    
                    // Get current period/clock
                    Map<String, Object> status = (Map<String, Object>) competition.get('status');
                    if (status != null) {
                        Map<String, Object> period = (Map<String, Object>) status.get('period');
                        if (period != null) {
                            result.currentPeriod = (String) period.get('displayValue');
                        }
                    }
                }
            }
            
            // Parse boxscore (scores)
            Map<String, Object> boxscore = (Map<String, Object>) responseMap.get('boxscore');
            if (boxscore != null) {
                List<Object> teams = (List<Object>) boxscore.get('teams');
                if (teams != null && teams.size() >= 2) {
                    Map<String, Object> homeTeam = (Map<String, Object>) teams[0];
                    Map<String, Object> awayTeam = (Map<String, Object>) teams[1];
                    
                    Map<String, Object> homeTeamInfo = (Map<String, Object>) homeTeam.get('team');
                    Map<String, Object> awayTeamInfo = (Map<String, Object>) awayTeam.get('team');
                    
                    result.homeTeamId = (String) homeTeamInfo.get('id');
                    result.awayTeamId = (String) awayTeamInfo.get('id');
                    
                    List<Object> homeStats = (List<Object>) homeTeam.get('statistics');
                    List<Object> awayStats = (List<Object>) awayTeam.get('statistics');
                    
                    // Find score in statistics
                    if (homeStats != null) {
                        for (Object statObj : homeStats) {
                            Map<String, Object> stat = (Map<String, Object>) statObj;
                            if (stat.get('name') == 'goals') {
                                result.homeScore = String.valueOf(stat.get('displayValue'));
                            }
                        }
                    }
                    
                    if (awayStats != null) {
                        for (Object statObj : awayStats) {
                            Map<String, Object> stat = (Map<String, Object>) statObj;
                            if (stat.get('name') == 'goals') {
                                result.awayScore = String.valueOf(stat.get('displayValue'));
                            }
                        }
                    }
                }
            }
            
            // Parse plays/commentary (match events - goals, cards, subs)
            Map<String, Object> commentary = (Map<String, Object>) responseMap.get('commentary');
            if (commentary != null) {
                List<Object> items = (List<Object>) commentary.get('items');
                if (items != null) {
                    for (Object itemObj : items) {
                        Map<String, Object> item = (Map<String, Object>) itemObj;
                        
                        ESPNMatchEvent matchEvent = new ESPNMatchEvent();
                        matchEvent.description = (String) item.get('text');
                        
                        // Get clock
                        Map<String, Object> clock = (Map<String, Object>) item.get('clock');
                        if (clock != null) {
                            matchEvent.minute = (String) clock.get('displayValue');
                        }
                        
                        // Get type
                        Map<String, Object> type = (Map<String, Object>) item.get('type');
                        if (type != null) {
                            matchEvent.eventType = (String) type.get('text');
                        }
                        
                        // Get team
                        Map<String, Object> team = (Map<String, Object>) item.get('team');
                        if (team != null) {
                            matchEvent.teamId = (String) team.get('id');
                        }
                        
                        result.matchEvents.add(matchEvent);
                    }
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse live feed response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse athlete details API response
     */
    private static ESPNAthleteResponse parseAthleteResponse(String jsonBody) {
        ESPNAthleteResponse result = new ESPNAthleteResponse();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            Map<String, Object> athlete = (Map<String, Object>) responseMap.get('athlete');
            
            if (athlete != null) {
                result.athlete = new ESPNAthlete();
                result.athlete.id = (String) athlete.get('id');
                result.athlete.displayName = (String) athlete.get('displayName');
                result.athlete.fullName = (String) athlete.get('fullName');
                result.athlete.jersey = String.valueOf(athlete.get('jersey'));
                
                Map<String, Object> position = (Map<String, Object>) athlete.get('position');
                if (position != null) {
                    result.athlete.position = (String) position.get('displayName');
                }
                
                Map<String, Object> headshot = (Map<String, Object>) athlete.get('headshot');
                if (headshot != null) {
                    result.athlete.headshotUrl = (String) headshot.get('href');
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse athlete response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse comprehensive match summary response
     */
    private static ESPNMatchSummaryResponse parseMatchSummaryResponse(String jsonBody) {
        ESPNMatchSummaryResponse result = new ESPNMatchSummaryResponse();
        result.lineups = new List<ESPNLineup>();
        result.commentaryItems = new List<ESPNCommentaryItem>();
        result.periods = new List<ESPNPeriod>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            
            // Parse header for basic match info
            Map<String, Object> header = (Map<String, Object>) responseMap.get('header');
            if (header != null) {
                result.eventId = (String) header.get('id');
                
                List<Object> competitions = (List<Object>) header.get('competitions');
                if (competitions != null && !competitions.isEmpty()) {
                    Map<String, Object> competition = (Map<String, Object>) competitions[0];
                    result.eventDate = (String) competition.get('date');
                    
                    // Parse competitors (teams)
                    List<Object> competitors = (List<Object>) competition.get('competitors');
                    if (competitors != null && competitors.size() >= 2) {
                        for (Object compObj : competitors) {
                            Map<String, Object> comp = (Map<String, Object>) compObj;
                            String homeAway = (String) comp.get('homeAway');
                            Map<String, Object> team = (Map<String, Object>) comp.get('team');
                            
                            if (team != null) {
                                if (homeAway == 'home') {
                                    result.homeTeamId = (String) team.get('id');
                                    result.homeTeamName = (String) team.get('displayName');
                                    result.homeScore = (String) comp.get('score');
                                } else if (homeAway == 'away') {
                                    result.awayTeamId = (String) team.get('id');
                                    result.awayTeamName = (String) team.get('displayName');
                                    result.awayScore = (String) comp.get('score');
                                }
                            }
                            
                            // Parse period scores (linescores)
                            List<Object> linescores = (List<Object>) comp.get('linescores');
                            if (linescores != null && homeAway != null) {
                                for (Integer i = 0; i < linescores.size(); i++) {
                                    Map<String, Object> linescore = (Map<String, Object>) linescores[i];
                                    String scoreValue = (String) linescore.get('displayValue');
                                    
                                    // Find or create period
                                    ESPNPeriod period = null;
                                    for (ESPNPeriod p : result.periods) {
                                        if (p.periodNumber == i + 1) {
                                            period = p;
                                            break;
                                        }
                                    }
                                    
                                    if (period == null) {
                                        period = new ESPNPeriod();
                                        period.periodNumber = i + 1;
                                        period.periodType = i == 0 ? 'First Half' : (i == 1 ? 'Second Half' : 'Period ' + (i + 1));
                                        result.periods.add(period);
                                    }
                                    
                                    if (homeAway == 'home' && String.isNotBlank(scoreValue)) {
                                        try {
                                            period.homeScore = Decimal.valueOf(scoreValue);
                                        } catch (Exception e) {
                                            System.debug('Failed to parse home period score: ' + scoreValue);
                                        }
                                    } else if (homeAway == 'away' && String.isNotBlank(scoreValue)) {
                                        try {
                                            period.awayScore = Decimal.valueOf(scoreValue);
                                        } catch (Exception e) {
                                            System.debug('Failed to parse away period score: ' + scoreValue);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Parse status
                    Map<String, Object> status = (Map<String, Object>) competition.get('status');
                    if (status != null) {
                        Map<String, Object> statusType = (Map<String, Object>) status.get('type');
                        if (statusType != null) {
                            result.matchStatus = (String) statusType.get('detail');
                        }
                    }
                }
            }
            
            // Parse rosters (lineups)
            List<Object> rosters = (List<Object>) responseMap.get('rosters');
            if (rosters != null) {
                for (Object rosterObj : rosters) {
                    Map<String, Object> rosterData = (Map<String, Object>) rosterObj;
                    ESPNLineup lineup = new ESPNLineup();
                    
                    String homeAway = (String) rosterData.get('homeAway');
                    lineup.isHome = (homeAway == 'home');
                    
                    Map<String, Object> team = (Map<String, Object>) rosterData.get('team');
                    if (team != null) {
                        lineup.teamId = (String) team.get('id');
                        lineup.teamName = (String) team.get('displayName');
                    }
                    
                    lineup.players = new List<ESPNLineupPlayer>();
                    List<Object> roster = (List<Object>) rosterData.get('roster');
                    if (roster != null) {
                        for (Object playerObj : roster) {
                            Map<String, Object> playerData = (Map<String, Object>) playerObj;
                            ESPNLineupPlayer player = new ESPNLineupPlayer();
                            
                            player.starter = Boolean.valueOf(playerData.get('starter'));
                            player.jersey = String.valueOf(playerData.get('jersey'));
                            
                            Map<String, Object> athlete = (Map<String, Object>) playerData.get('athlete');
                            if (athlete != null) {
                                player.athleteId = (String) athlete.get('id');
                                player.displayName = (String) athlete.get('displayName');
                                player.fullName = (String) athlete.get('fullName');
                                
                                Map<String, Object> headshot = (Map<String, Object>) athlete.get('headshot');
                                if (headshot != null) {
                                    player.headshotUrl = (String) headshot.get('href');
                                }
                            }
                            
                            Map<String, Object> position = (Map<String, Object>) playerData.get('position');
                            if (position != null) {
                                player.position = (String) position.get('displayName');
                                player.positionAbbreviation = (String) position.get('abbreviation');
                            }
                            
                            player.subbedIn = Boolean.valueOf(playerData.get('subbedIn'));
                            player.subbedOut = Boolean.valueOf(playerData.get('subbedOut'));
                            
                            lineup.players.add(player);
                        }
                    }
                    
                    result.lineups.add(lineup);
                }
            }
            
            // Parse commentary
            List<Object> commentary = (List<Object>) responseMap.get('commentary');
            if (commentary != null) {
                for (Object commObj : commentary) {
                    Map<String, Object> commData = (Map<String, Object>) commObj;
                    ESPNCommentaryItem item = new ESPNCommentaryItem();
                    
                    item.sequence = Integer.valueOf(commData.get('sequence'));
                    item.text = (String) commData.get('text');
                    
                    Map<String, Object> time = (Map<String, Object>) commData.get('time');
                    if (time != null) {
                        item.timeDisplay = (String) time.get('displayValue');
                        Object timeValue = time.get('value');
                        if (timeValue != null) {
                            item.timeValue = Decimal.valueOf(String.valueOf(timeValue));
                        }
                    }
                    
                    result.commentaryItems.add(item);
                }
            }
            
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse match summary response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
            System.debug(LoggingLevel.ERROR, 'Stack: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Helper method to parse event data (used by scoreboard and schedule)
     */
    private static ESPNEvent parseEventData(Map<String, Object> eventData) {
        ESPNEvent event = new ESPNEvent();
        
        event.id = (String) eventData.get('id');
        event.name = (String) eventData.get('name');
        event.shortName = (String) eventData.get('shortName');
        event.eventDate = (String) eventData.get('date');
        
        // Get competitions (contains teams and scores)
        List<Object> competitions = (List<Object>) eventData.get('competitions');
        if (competitions != null && !competitions.isEmpty()) {
            Map<String, Object> competition = (Map<String, Object>) competitions[0];
            
            // Get status
            Map<String, Object> status = (Map<String, Object>) competition.get('status');
            if (status != null) {
                Map<String, Object> statusType = (Map<String, Object>) status.get('type');
                if (statusType != null) {
                    event.status = (String) statusType.get('detail');
                    event.statusState = (String) statusType.get('state');
                }
            }
            
            // Get competitors (teams)
            List<Object> competitors = (List<Object>) competition.get('competitors');
            if (competitors != null && competitors.size() >= 2) {
                for (Object competitorObj : competitors) {
                    Map<String, Object> competitor = (Map<String, Object>) competitorObj;
                    String homeAway = (String) competitor.get('homeAway');
                    
                    Map<String, Object> team = (Map<String, Object>) competitor.get('team');
                    if (team != null) {
                        if (homeAway == 'home') {
                            event.homeTeamId = (String) team.get('id');
                            event.homeTeamName = (String) team.get('displayName');
                            event.homeScore = (String) competitor.get('score');
                        } else if (homeAway == 'away') {
                            event.awayTeamId = (String) team.get('id');
                            event.awayTeamName = (String) team.get('displayName');
                            event.awayScore = (String) competitor.get('score');
                        }
                    }
                }
            }
            
            // Get venue
            Map<String, Object> venue = (Map<String, Object>) competition.get('venue');
            if (venue != null) {
                event.venueName = (String) venue.get('fullName');
            }
        }
        
        return event;
    }
    
    // ========================================
    // WRAPPER CLASSES
    // ========================================
    
    public class ESPNTeamsResponse {
        public Boolean success;
        public String errorMessage;
        public List<ESPNTeam> teams;
    }
    
    public class ESPNTeam {
        public String id;
        public String name;
        public String shortName;
        public String abbreviation;
        public String logoUrl;
        public String venueName;
    }
    
    public class ESPNRosterResponse {
        public Boolean success;
        public String errorMessage;
        public List<ESPNAthlete> athletes;
    }
    
    public class ESPNAthlete {
        public String id;
        public String displayName;
        public String fullName;
        public String firstName;
        public String lastName;
        public String jersey;
        public String position;
        public String headshotUrl;
    }
    
    public class ESPNScoreboardResponse {
        public Boolean success;
        public String errorMessage;
        public List<ESPNEvent> events;
    }
    
    public class ESPNScheduleResponse {
        public Boolean success;
        public String errorMessage;
        public List<ESPNEvent> events;
    }
    
    public class ESPNEvent {
        public String id;
        public String name;
        public String shortName;
        public String eventDate; // Can't use 'date' - reserved keyword
        public String status;
        public String statusState;
        public String homeTeamId;
        public String homeTeamName;
        public String homeScore;
        public String awayTeamId;
        public String awayTeamName;
        public String awayScore;
        public String venueName;
    }
    
    public class ESPNLiveFeedResponse {
        public Boolean success;
        public String errorMessage;
        public String matchStatus;
        public String homeTeamId;
        public String awayTeamId;
        public String homeScore;
        public String awayScore;
        public String currentPeriod;
        public List<ESPNMatchEvent> matchEvents;
    }
    
    public class ESPNMatchEvent {
        public String eventType;
        public String minute;
        public String description;
        public String teamId;
        public String playerId;
    }
    
    public class ESPNAthleteResponse {
        public Boolean success;
        public String errorMessage;
        public ESPNAthlete athlete;
    }
    
    public class ESPNMatchSummaryResponse {
        public Boolean success;
        public String errorMessage;
        public String eventId;
        public String eventDate;
        public String homeTeamId;
        public String homeTeamName;
        public String homeScore;
        public String awayTeamId;
        public String awayTeamName;
        public String awayScore;
        public String matchStatus;
        public List<ESPNLineup> lineups;
        public List<ESPNCommentaryItem> commentaryItems;
        public List<ESPNPeriod> periods;
    }
    
    public class ESPNLineup {
        public Boolean isHome;
        public String teamId;
        public String teamName;
        public String formation;
        public List<ESPNLineupPlayer> players;
    }
    
    public class ESPNLineupPlayer {
        public String athleteId;
        public String displayName;
        public String fullName;
        public String jersey;
        public String position;
        public String positionAbbreviation;
        public Boolean starter;
        public Boolean subbedIn;
        public Boolean subbedOut;
        public String headshotUrl;
    }
    
    public class ESPNCommentaryItem {
        public Integer sequence;
        public String text;
        public String timeDisplay;
        public Decimal timeValue;
    }
    
    public class ESPNPeriod {
        public Integer periodNumber;
        public String periodType;
        public Decimal homeScore;
        public Decimal awayScore;
    }
    
    public class ESPNException extends Exception {}
}

