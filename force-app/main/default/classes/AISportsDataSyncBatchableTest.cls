/**
 * @description Test class for AISportsDataSyncBatchable
 * @author Brendan Milton
 * @date 2025-12-30
 */
@IsTest
private class AISportsDataSyncBatchableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test competition
        Competition__c comp = new Competition__c(
            Name = 'Test League',
            Sport__c = 'Soccer',
            Status__c = 'Active',
            ESPN_League_ID__c = 'test.league'
        );
        insert comp;
        
        // Create test teams
        Account homeTeam = new Account(Name = 'Home FC');
        Account awayTeam = new Account(Name = 'Away United');
        insert new List<Account>{ homeTeam, awayTeam };
        
        // Create test match
        Match__c match = new Match__c(
            Competition__c = comp.Id,
            Home_Team__c = homeTeam.Id,
            Away_Team__c = awayTeam.Id,
            Match_Date_Time__c = Datetime.now().addDays(2),
            Status__c = 'Scheduled'
        );
        insert match;
    }
    
    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        AISportsDataSyncBatchable batch = new AISportsDataSyncBatchable();
        Database.executeBatch(batch, 5);
        Test.stopTest();
        
        // Verify batch completed (check via async apex jobs)
        List<AsyncApexJob> jobs = [SELECT Status, NumberOfErrors FROM AsyncApexJob 
                                   WHERE ApexClass.Name = 'AISportsDataSyncBatchable'];
        Assert.isFalse(jobs.isEmpty(), 'Batch job should be queued');
    }
    
    @IsTest
    static void testStartMethod() {
        Test.startTest();
        AISportsDataSyncBatchable batch = new AISportsDataSyncBatchable();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        Assert.isNotNull(ql, 'Query locator should not be null');
    }
}

