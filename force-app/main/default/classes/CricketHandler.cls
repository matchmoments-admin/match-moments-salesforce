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
    
    public Match__c mapFixture(Map<String, Object> apiData, Id competitionId) {
        Match__c match = new Match__c();
        
        match.ESPN_Event_ID__c = safeString(apiData, 'id');
        match.Match_Date_Time__c = parseIsoDate(safeString(apiData, 'date'));
        match.Competition__c = competitionId;
        
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
                    Decimal wickets = 0;
                    
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
                            try {
                                wickets = Decimal.valueOf(parts[1].trim());
                            } catch (Exception e) {
                                wickets = 0;
                            }
                        }
                    }
                    
                    if (homeAway == 'home') {
                        match.Home_Score_Final__c = runs;
                        match.Home_Sub_Score__c = wickets; // Storing wickets as number
                    } else if (homeAway == 'away') {
                        match.Away_Score_Final__c = runs;
                        match.Away_Sub_Score__c = wickets; // Storing wickets as number
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
        c.Position__c = safeString(playerData, 'position'); // e.g., "Batsman", "Bowler"
        c.ESPN_Player_ID__c = safeString(playerData, 'id');
        c.Jersey_Number__c = safeDecimal(playerData, 'jersey');
        c.Profile_Image_URL__c = safeString(playerData, 'headshotUrl');
        c.Player_Role__c = 'Active'; // Using Player_Role__c instead of Roster_Status__c
        
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

