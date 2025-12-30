/**
 * @description Sport-specific handler for Soccer/Football
 * @author Brendan Milton
 * @date 2025-11-27
 */
public class SoccerHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'Soccer';
    }
    
    public Match__c mapFixture(Map<String, Object> apiData, Id competitionId) {
        Match__c match = new Match__c();
        
        // Map ESPN ID
        match.ESPN_Event_ID__c = safeString(apiData, 'id');
        match.Competition__c = competitionId;
        
        // Parse date
        String dateStr = safeString(apiData, 'date');
        if (String.isNotBlank(dateStr)) {
            match.Match_Date_Time__c = parseIsoDate(dateStr);
        }
        
        // Soccer scoring: Goals go to Final Score, Sub Score is null
        List<Object> competitions = (List<Object>)apiData.get('competitions');
        if (competitions != null && !competitions.isEmpty()) {
            Map<String, Object> competition = (Map<String, Object>)competitions[0];
            List<Object> competitors = (List<Object>)competition.get('competitors');
            
            if (competitors != null) {
                for (Object c : competitors) {
                    Map<String, Object> teamData = (Map<String, Object>)c;
                    String homeAway = safeString(teamData, 'homeAway');
                    Decimal score = safeDecimal(teamData, 'score');
                    
                    if (homeAway == 'home') {
                        match.Home_Score_Final__c = score;
                        match.Home_Sub_Score__c = null; // Soccer doesn't use sub-score
                    } else if (homeAway == 'away') {
                        match.Away_Score_Final__c = score;
                        match.Away_Sub_Score__c = null;
                    }
                }
            }
        }
        
        // Set status based on ESPN status
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Striker", "Midfielder"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Player_Role__c = 'Active'; // Using Player_Role__c instead of Roster_Status__c
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // Soccer: Total score is just goals
        return safeDecimal(scoreData, 'score');
    }
}

