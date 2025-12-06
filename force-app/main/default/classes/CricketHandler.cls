/**
 * @description Sport-specific handler for Cricket
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * Handles complex scoring: "245/8" format where:
 * - Total Score = Runs (245)
 * - Sub Score = Wickets (8)
 */
public class CricketHandler extends SportHandlerBase implements ISportDataHandler {
    
    public String getSportType() {
        return 'Cricket';
    }
    
    public Opportunity mapFixture(Map<String, Object> apiData, Id leagueId) {
        Opportunity opp = new Opportunity();
        
        opp.ESPN_ID__c = safeString(apiData, 'id');
        opp.Name = safeString(apiData, 'name'); // e.g., "AUS vs IND"
        opp.Start_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        opp.Opportunity_Group__c = leagueId;
        
        // Cricket Specific Scoring Logic
        List<Object> competitions = (List<Object>)apiData.get('competitions');
        if (competitions != null && !competitions.isEmpty()) {
            Map<String, Object> competition = (Map<String, Object>)competitions[0];
            List<Object> competitors = (List<Object>)competition.get('competitors');
            
            if (competitors != null) {
                for (Object c : competitors) {
                    Map<String, Object> teamData = (Map<String, Object>)c;
                    String scoreStr = safeString(teamData, 'score'); // e.g., "245/8"
                    String homeAway = safeString(teamData, 'homeAway');
                    
                    // Parse "245/8" -> Total: 245, Sub: 8 (Wickets)
                    Decimal runs = 0;
                    String wickets = '';
                    
                    if (String.isNotBlank(scoreStr)) {
                        List<String> parts = scoreStr.split('/');
                        if (parts.size() > 0) {
                            try {
                                runs = Decimal.valueOf(parts[0].trim());
                            } catch (Exception e) {
                                runs = 0;
                            }
                        }
                        if (parts.size() > 1) {
                            wickets = parts[1].trim();
                        }
                    }
                    
                    if (homeAway == 'home') {
                        opp.Home_Score_Total__c = runs;
                        opp.Home_Sub_Score__c = wickets; // Storing wickets in sub-score
                    } else if (homeAway == 'away') {
                        opp.Away_Score_Total__c = runs;
                        opp.Away_Sub_Score__c = wickets;
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Batsman", "Bowler"
        c.ESPN_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_Url__c = safeString(playerData, 'headshotUrl');
        c.Roster_Status__c = 'Active';
        
        return c;
    }
    
    public Decimal calculateTotalScore(Map<String, Object> scoreData) {
        // Cricket: Extract runs from score string or direct value
        String scoreStr = safeString(scoreData, 'score');
        if (String.isNotBlank(scoreStr) && scoreStr.contains('/')) {
            List<String> parts = scoreStr.split('/');
            if (parts.size() > 0) {
                try {
                    return Decimal.valueOf(parts[0].trim());
                } catch (Exception e) {
                    return 0;
                }
            }
        }
        return safeDecimal(scoreData, 'runs');
    }
}

