/**
 * @description Scheduled job to sync AI-generated sports content daily
 * Runs batch job to generate articles for matches and competitions
 * @author Brendan Milton
 * @date 2025-12-30
 * 
 * Schedule with:
 * AISportsDataDailySync job = new AISportsDataDailySync();
 * String cronExp = '0 0 2 * * ?'; // 2 AM daily (1 hour before ESPN sync)
 * System.schedule('AI Sports Data Daily Sync', cronExp, job);
 */
public class AISportsDataDailySync implements Schedulable {
    
    // Batch size for processing (manages API callout limits)
    private static final Integer BATCH_SIZE = 50;
    
    /**
     * @description Execute method called by scheduler
     * @param sc Schedulable context
     */
    public void execute(SchedulableContext sc) {
        System.debug('=== AISportsDataDailySync: Starting daily AI sync ===');
        
        try {
            // Execute batch job
            AISportsDataSyncBatchable batch = new AISportsDataSyncBatchable();
            Id batchId = Database.executeBatch(batch, BATCH_SIZE);
            
            System.debug('AISportsDataDailySync: Batch job started - ID: ' + batchId);
            System.debug('=== AISportsDataDailySync: Initialization complete ===');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'FATAL ERROR in AI daily sync: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Attempt to send error notification
            sendErrorNotification(e);
        }
    }
    
    /**
     * @description Send error notification email
     * @param e Exception that occurred
     */
    private void sendErrorNotification(Exception e) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            email.setToAddresses(new List<String>{ currentUser.Email });
            
            email.setSubject('ERROR: AI Sports Data Daily Sync Failed');
            
            String body = 'The AI Sports Data Daily Sync job failed to start.\n\n';
            body += 'Error: ' + e.getMessage() + '\n\n';
            body += 'Stack Trace:\n' + e.getStackTraceString() + '\n\n';
            body += 'Time: ' + Datetime.now().format() + '\n';
            body += 'User: ' + UserInfo.getName() + ' (' + UserInfo.getUserEmail() + ')\n';
            
            email.setPlainTextBody(body);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            
        } catch (Exception emailEx) {
            System.debug('Failed to send error notification: ' + emailEx.getMessage());
        }
    }
}

