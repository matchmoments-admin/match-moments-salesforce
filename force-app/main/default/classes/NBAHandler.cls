/**
 * @description Sport-specific handler for NBA/Basketball
 * @author Brendan Milton
 * @date 2025-11-27
 */
public class NBAHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'Basketball';
    }
    
    public Match__c mapFixture(Map<String, Object> apiData, Id competitionId) {
        Match__c match = new Match__c();
        
        match.ESPN_Event_ID__c = safeString(apiData, 'id');
        match.Match_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        match.Competition__c = competitionId;
        
        // NBA scoring: Points go to Final Score
        List<Object> competitions = (List<Object>)apiData.get('competitions');
        if (competitions != null && !competitions.isEmpty()) {
            Map<String, Object> competition = (Map<String, Object>)competitions[0];
            List<Object> competitors = (List<Object>)competition.get('competitors');
            
            if (competitors != null) {
                for (Object c : competitors) {
                    Map<String, Object> teamData = (Map<String, Object>)c;
                    String homeAway = safeString(teamData, 'homeAway');
                    Decimal points = safeDecimal(teamData, 'score');
                    
                    if (homeAway == 'home') {
                        match.Home_Score_Final__c = points;
                        match.Home_Sub_Score__c = null; // NBA doesn't use sub-score
                    } else if (homeAway == 'away') {
                        match.Away_Score_Final__c = points;
                        match.Away_Sub_Score__c = null;
                    }
                }
            }
            
            // Handle quarters/periods
            Map<String, Object> status = (Map<String, Object>)competition.get('status');
            if (status != null) {
                String period = safeString(status, 'period');
                if (String.isNotBlank(period)) {
                    match.Current_Period__c = 'Q' + period; // e.g., "Q1", "Q2"
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Point Guard", "Center"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Player_Role__c = 'Active'; // Using Player_Role__c instead of Roster_Status__c
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // NBA: Total score is just points
        return safeDecimal(scoreData, 'score');
    }
}

