/**
 * @description Queueable class for async ESPN Event ID resolution
 * Handles callouts to ESPN API to find and set ESPN_Event_ID__c on Match records
 * @author Brendan Milton
 * @date 2025-12-31
 */
public class ESPNEventIdResolverQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> matchIds;
    
    /**
     * @description Constructor
     * @param matchIds Set of Match__c record IDs to resolve Event IDs for
     */
    public ESPNEventIdResolverQueueable(Set<Id> matchIds) {
        this.matchIds = matchIds;
    }
    
    /**
     * @description Execute method for Queueable interface
     * @param context Queueable context
     */
    public void execute(QueueableContext context) {
        if (matchIds == null || matchIds.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'ESPNEventIdResolverQueueable: No match IDs provided');
            return;
        }
        
        // Query matches with required fields
        List<Match__c> matches = [
            SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, 
                   Competition__c, Competition__r.Sport__c, Competition__r.ESPN_League_ID__c,
                   Home_Team__c, Away_Team__c,
                   Home_Team__r.Name, Home_Team__r.ESPN_Team_ID__c,
                   Away_Team__r.Name, Away_Team__r.ESPN_Team_ID__c
            FROM Match__c
            WHERE Id IN :matchIds
            AND ESPN_Event_ID__c = null
            AND Match_Date_Time__c != null
            AND Competition__c != null
            AND (Home_Team__c != null OR Away_Team__c != null)
        ];
        
        if (matches.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'ESPNEventIdResolverQueueable: No matches found that need Event ID resolution');
            return;
        }
        
        List<Match__c> matchesToUpdate = new List<Match__c>();
        
        for (Match__c match : matches) {
            try {
                // Attempt to resolve Event ID
                String eventId = ESPNEventIdResolver.resolveEventId(match);
                
                if (String.isNotBlank(eventId)) {
                    match.ESPN_Event_ID__c = eventId;
                    matchesToUpdate.add(match);
                    System.debug(LoggingLevel.INFO, 'ESPNEventIdResolverQueueable: Resolved Event ID ' + eventId + ' for match ' + match.Id);
                } else {
                    System.debug(LoggingLevel.WARN, 'ESPNEventIdResolverQueueable: Could not resolve Event ID for match ' + match.Id + ' (' + match.Name + ')');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolverQueueable: Error resolving Event ID for match ' + match.Id + ': ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolverQueueable: Stack trace: ' + e.getStackTraceString());
            }
        }
        
        // Update matches with resolved Event IDs
        if (!matchesToUpdate.isEmpty()) {
            try {
                update matchesToUpdate;
                System.debug(LoggingLevel.INFO, 'ESPNEventIdResolverQueueable: Successfully updated ' + matchesToUpdate.size() + ' match(es) with ESPN Event IDs');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolverQueueable: Error updating matches: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'ESPNEventIdResolverQueueable: Stack trace: ' + e.getStackTraceString());
            }
        }
    }
}

