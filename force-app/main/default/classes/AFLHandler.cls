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
    
    public Match__c mapFixture(Map<String, Object> apiData, Id competitionId) {
        Match__c match = new Match__c();
        
        match.ESPN_Event_ID__c = safeString(apiData, 'id');
        match.Match_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        match.Competition__c = competitionId;
        
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
                    
                    if (homeAway == 'home') {
                        match.Home_Score_Final__c = totalScore;
                        match.Home_Sub_Score__c = behinds; // Store behinds as number
                    } else if (homeAway == 'away') {
                        match.Away_Score_Final__c = totalScore;
                        match.Away_Sub_Score__c = behinds; // Store behinds as number
                    }
                }
            }
        }
        
        // Set status
        Map<String, Object> status = (Map<String, Object>)apiData.get('status');
        if (status != null) {
            String statusType = safeString(status, 'type');
            if (statusType == 'STATUS_FINAL') {
                match.Status__c = 'Completed';
            } else if (statusType == 'STATUS_IN_PROGRESS') {
                match.Status__c = 'Live';
            } else {
                match.Status__c = 'Scheduled';
            }
        }
        
        return match;
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
        c.Player_Role__c = 'Active'; // Using Player_Role__c instead of Roster_Status__c
        
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

