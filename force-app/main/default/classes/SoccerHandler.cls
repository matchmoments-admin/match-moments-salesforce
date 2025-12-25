/**
 * @description Sport-specific handler for Soccer/Football
 * @author Brendan Milton
 * @date 2025-11-27
 */
public class SoccerHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'Soccer';
    }
    
    public Opportunity mapFixture(Map<String, Object> apiData, Id leagueId) {
        Opportunity opp = new Opportunity();
        
        // Map ESPN ID
        opp.ESPN_ID__c = safeString(apiData, 'id');
        opp.Name = safeString(apiData, 'name');
        opp.Opportunity_Group__c = leagueId;
        
        // Parse date
        String dateStr = safeString(apiData, 'date');
        if (String.isNotBlank(dateStr)) {
            opp.Start_Date_Time__c = parseIsoDate(dateStr);
        }
        
        // Soccer scoring: Goals go to Total Score, Sub Score is null
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
                        opp.Home_Score_Total__c = score;
                        opp.Home_Sub_Score__c = null; // Soccer doesn't use sub-score
                    } else if (homeAway == 'away') {
                        opp.Away_Score_Total__c = score;
                        opp.Away_Sub_Score__c = null;
                    }
                }
            }
        }
        
        // Set stage based on status
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Striker", "Midfielder"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Roster_Status__c = 'Active'; // Default
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // Soccer: Total score is just goals
        return safeDecimal(scoreData, 'score');
    }
}

