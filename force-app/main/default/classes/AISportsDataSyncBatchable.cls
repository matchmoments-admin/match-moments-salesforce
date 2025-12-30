/**
 * @description Batchable job for AI-powered sports data synchronization
 * Generates articles for matches, competition news, and enriches CRM data
 * @author Brendan Milton
 * @date 2025-12-30
 * 
 * Usage:
 * Database.executeBatch(new AISportsDataSyncBatchable(), 50);
 */
public class AISportsDataSyncBatchable implements 
    Database.Batchable<SObject>, 
    Database.AllowsCallouts, 
    Database.Stateful {
    
    // Stateful counters
    private Integer totalCompetitions = 0;
    private Integer totalArticles = 0;
    private Integer totalPreviews = 0;
    private Integer totalRecaps = 0;
    private Integer totalErrors = 0;
    private List<String> errors = new List<String>();
    private Datetime startTime;
    
    /**
     * @description Start method - query active competitions
     * @param bc Batch context
     * @return Database.QueryLocator for competitions to process
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = Datetime.now();
        System.debug('=== AISportsDataSyncBatchable: Start ===');
        
        // Query active competitions with ESPN integration
        String query = 'SELECT Id, Name, Sport__c, Status__c, ESPN_League_ID__c ' +
                      'FROM Competition__c ' +
                      'WHERE Status__c = \'Active\' ' +
                      'AND ESPN_League_ID__c != null ' +
                      'ORDER BY Name';
        
        System.debug('AISportsDataSyncBatchable: Query - ' + query);
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method - process batch of competitions
     * @param bc Batch context
     * @param scope List of Competition__c records to process
     */
    public void execute(Database.BatchableContext bc, List<Competition__c> scope) {
        System.debug('AISportsDataSyncBatchable: Processing batch of ' + scope.size() + ' competitions');
        
        for (Competition__c comp : scope) {
            try {
                totalCompetitions++;
                
                // Create UOW for this competition's articles
                fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
                
                // Get article generator service
                IArticleGeneratorService articleService = ArticleGeneratorServiceImpl.newInstance();
                
                // Generate articles for matches in this competition
                // Next 7 days (previews) and last 3 days (recaps)
                Map<String, Integer> stats = articleService.batchGenerateCompetitionArticles(
                    comp.Id,
                    7,  // days ahead
                    3,  // days behind
                    uow
                );
                
                // Commit articles
                uow.commitWork();
                
                // Update counters
                totalPreviews += stats.get('previews');
                totalRecaps += stats.get('recaps');
                totalErrors += stats.get('errors');
                totalArticles += (stats.get('previews') + stats.get('recaps'));
                
                System.debug('AISportsDataSyncBatchable: Competition ' + comp.Name + 
                           ' - Previews: ' + stats.get('previews') + 
                           ', Recaps: ' + stats.get('recaps') + 
                           ', Errors: ' + stats.get('errors'));
                
            } catch (Exception e) {
                totalErrors++;
                String errorMsg = 'Competition: ' + comp.Name + ' - ' + e.getMessage();
                errors.add(errorMsg);
                System.debug(LoggingLevel.ERROR, 'AISportsDataSyncBatchable: ERROR - ' + errorMsg);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            }
        }
    }
    
    /**
     * @description Finish method - log results and send summary
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('=== AISportsDataSyncBatchable: Finish ===');
        System.debug('Total competitions processed: ' + totalCompetitions);
        System.debug('Total articles generated: ' + totalArticles);
        System.debug('Total previews: ' + totalPreviews);
        System.debug('Total recaps: ' + totalRecaps);
        System.debug('Total errors: ' + totalErrors);
        
        Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
        System.debug('Duration: ' + duration + ' seconds');
        
        // Send summary email (optional)
        if (totalArticles > 0 || totalErrors > 0) {
            sendSummaryEmail();
        }
        
        System.debug('=== AISportsDataSyncBatchable: Complete ===');
    }
    
    /**
     * @description Send summary email to admin
     */
    private void sendSummaryEmail() {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Get current user
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            email.setToAddresses(new List<String>{ currentUser.Email });
            
            email.setSubject('AI Sports Data Sync - Daily Summary');
            
            String body = 'AI Sports Data Synchronization Summary\n';
            body += '=====================================\n\n';
            body += 'Competitions Processed: ' + totalCompetitions + '\n';
            body += 'Total Articles Generated: ' + totalArticles + '\n';
            body += '  - Match Previews: ' + totalPreviews + '\n';
            body += '  - Match Recaps: ' + totalRecaps + '\n';
            body += 'Errors: ' + totalErrors + '\n\n';
            
            if (!errors.isEmpty()) {
                body += 'Error Details:\n';
                body += '-------------\n';
                Integer maxErrors = Math.min(10, errors.size());
                for (Integer i = 0; i < maxErrors; i++) {
                    body += (i + 1) + '. ' + errors[i] + '\n';
                }
                if (errors.size() > 10) {
                    body += '\n... and ' + (errors.size() - 10) + ' more errors\n';
                }
            }
            
            Decimal duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
            body += '\nExecution Time: ' + duration + ' seconds\n';
            body += 'Completed: ' + Datetime.now().format() + '\n';
            
            email.setPlainTextBody(body);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            
        } catch (Exception e) {
            System.debug('Failed to send summary email: ' + e.getMessage());
        }
    }
}

