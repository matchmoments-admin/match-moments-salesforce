/**
 * @description Sport-specific handler for AFL (Australian Rules Football)
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * AFL Scoring: 6 points for a Goal, 1 for a Behind
 * Total Score = (goals * 6) + behinds
 * Display Score = "goals.behinds" (e.g., "10.5")
 */
public class AFLHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'AFL';
    }
    
    public Opportunity mapFixture(Map<String, Object> apiData, Id leagueId) {
        Opportunity opp = new Opportunity();
        
        opp.ESPN_ID__c = safeString(apiData, 'id');
        opp.Name = safeString(apiData, 'name');
        opp.Start_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        opp.Opportunity_Group__c = leagueId;
        
        // AFL Specific Logic: 6 points for a Goal, 1 for a Behind
        List<Object> competitions = (List<Object>)apiData.get('competitions');
        if (competitions != null && !competitions.isEmpty()) {
            Map<String, Object> competition = (Map<String, Object>)competitions[0];
            List<Object> competitors = (List<Object>)competition.get('competitors');
            
            if (competitors != null) {
                for (Object c : competitors) {
                    Map<String, Object> teamData = (Map<String, Object>)c;
                    String homeAway = safeString(teamData, 'homeAway');
                    
                    // Assume API returns goals and behinds separately or in score object
                    Map<String, Object> scoreData = (Map<String, Object>)teamData.get('score');
                    if (scoreData == null) {
                        scoreData = teamData; // Fallback to teamData itself
                    }
                    
                    Integer goals = Integer.valueOf(safeDecimal(scoreData, 'goals'));
                    Integer behinds = Integer.valueOf(safeDecimal(scoreData, 'behinds'));
                    
                    Decimal totalScore = (goals * 6) + behinds; // The actual winning score
                    String displayScore = goals + '.' + behinds; // The display score "10.5"
                    
                    if (homeAway == 'home') {
                        opp.Home_Score_Total__c = totalScore;
                        opp.Home_Sub_Score__c = displayScore; // Goals.Behinds format
                    } else if (homeAway == 'away') {
                        opp.Away_Score_Total__c = totalScore;
                        opp.Away_Sub_Score__c = displayScore;
                    }
                }
            }
        }
        
        // Set stage
        Map<String, Object> status = (Map<String, Object>)apiData.get('status');
        if (status != null) {
            String statusType = safeString(status, 'type');
            if (statusType == 'STATUS_FINAL') {
                opp.StageName = 'Completed';
            } else if (statusType == 'STATUS_IN_PROGRESS') {
                opp.StageName = 'In Progress';
            } else {
                opp.StageName = 'Scheduled';
            }
        }
        
        return opp;
    }
    
    public Contact mapPlayer(Map<String, Object> playerData, Id teamId) {
        Contact c = new Contact();
        c.AccountId = teamId;
        c.FirstName = safeString(playerData, 'firstName');
        c.LastName = safeString(playerData, 'lastName');
        c.Position__c = safeString(playerData, 'position'); // e.g., "Ruckman", "Forward"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Roster_Status__c = 'Active';
        
        // AFL specific: DreamTeam points could be stored in Description or Rating_Points__c
        Decimal fantasyAvg = safeDecimal(playerData, 'fantasyAvg');
        if (fantasyAvg > 0) {
            c.Description = 'Avg Fantasy Points: ' + fantasyAvg;
        }
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // AFL: (goals * 6) + behinds
        Integer goals = Integer.valueOf(safeDecimal(scoreData, 'goals'));
        Integer behinds = Integer.valueOf(safeDecimal(scoreData, 'behinds'));
        return (goals * 6) + behinds;
    }
}

