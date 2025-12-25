/**
 * @description Sport-specific handler for NBA/Basketball
 * @author Brendan Milton
 * @date 2025-11-27
 */
public class NBAHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'Basketball';
    }
    
    public Opportunity mapFixture(Map<String, Object> apiData, Id leagueId) {
        Opportunity opp = new Opportunity();
        
        opp.ESPN_ID__c = safeString(apiData, 'id');
        opp.Name = safeString(apiData, 'name');
        opp.Start_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        opp.Opportunity_Group__c = leagueId;
        
        // NBA scoring: Points go to Total Score
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
                        opp.Home_Score_Total__c = points;
                        opp.Home_Sub_Score__c = null; // NBA doesn't use sub-score
                    } else if (homeAway == 'away') {
                        opp.Away_Score_Total__c = points;
                        opp.Away_Sub_Score__c = null;
                    }
                }
            }
            
            // Handle quarters/periods
            Map<String, Object> status = (Map<String, Object>)competition.get('status');
            if (status != null) {
                String period = safeString(status, 'period');
                if (String.isNotBlank(period)) {
                    opp.Current_Period__c = 'Q' + period; // e.g., "Q1", "Q2"
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Point Guard", "Center"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Roster_Status__c = 'Active';
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // NBA: Total score is just points
        return safeDecimal(scoreData, 'score');
    }
}

