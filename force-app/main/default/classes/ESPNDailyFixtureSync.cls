/**
 * @description Scheduled job to sync ESPN fixtures daily
 * Runs automatically to keep fixture data up-to-date
 * @author Brendan Milton
 * @date 2025-12-20
 * 
 * Schedule with:
 * ESPNDailyFixtureSync job = new ESPNDailyFixtureSync();
 * String cronExp = '0 0 3 * * ?'; // 3 AM daily
 * System.schedule('ESPN Daily Fixture Sync', cronExp, job);
 */
public class ESPNDailyFixtureSync implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        System.debug('=== ESPNDailyFixtureSync: Starting daily fixture sync ===');
        
        try {
            // Get all active competitions with ESPN League IDs
            List<Competition__c> competitions = [
                SELECT Id, Name, ESPN_League_ID__c, Sport__c 
                FROM Competition__c 
                WHERE Status__c = 'Active' 
                AND ESPN_League_ID__c != null
            ];
            
            System.debug('Found ' + competitions.size() + ' active competitions to sync');
            
            // Sync fixtures for next 7 days
            Date startDate = Date.today();
            Date endDate = startDate.addDays(7);
            
            Integer totalFixtures = 0;
            
            for (Competition__c comp : competitions) {
                try {
                    // Determine sport type based on ESPN League ID
                    String sport = determineSportType(comp.ESPN_League_ID__c);
                    
                    System.debug('Syncing ' + comp.Name + ' (' + comp.ESPN_League_ID__c + ')');
                    
                    // Sync fixtures for date range
                    Integer fixturesForComp = ESPNSyncService.syncFixturesForDateRange(
                        sport, 
                        comp.ESPN_League_ID__c, 
                        startDate, 
                        endDate, 
                        comp.Id
                    );
                    
                    totalFixtures += fixturesForComp;
                    System.debug('Synced ' + fixturesForComp + ' fixtures for ' + comp.Name);
                    
                } catch (Exception e) {
                    System.debug('ERROR syncing ' + comp.Name + ': ' + e.getMessage());
                    // Continue with next competition
                }
            }
            
            System.debug('=== ESPNDailyFixtureSync: Complete - ' + totalFixtures + ' total fixtures synced ===');
            
        } catch (Exception e) {
            System.debug('FATAL ERROR in daily sync: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Determine sport type from ESPN League ID
     * @param leagueId ESPN League ID (e.g., 'eng.wsl', 'usa.nwsl', 'wnba')
     * @return String Sport type for ESPN API ('soccer' or 'basketball')
     */
    private String determineSportType(String leagueId) {
        if (leagueId.contains('wsl') || leagueId.contains('nwsl') || leagueId.contains('soccer')) {
            return 'soccer';
        } else if (leagueId.contains('wnba') || leagueId.contains('basketball')) {
            return 'basketball';
        }
        
        // Default to soccer
        return 'soccer';
    }
}

