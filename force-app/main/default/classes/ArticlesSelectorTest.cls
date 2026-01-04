/**
 * @description Test class for ArticlesSelector
 * @author Brendan Milton
 * @date 2025-12-30
 */
@IsTest
private class ArticlesSelectorTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test competition and match
        Competition__c comp = new Competition__c(
            Sport__c = 'Soccer', 
            Status__c = 'Active', 
            Competition_Type__c = 'Domestic League', 
            Season_Year__c = '2024-25',
            ESPN_League_ID__c = 'test.1',
            Season_Start_Date__c = Date.today()
        );
        insert comp;
        
        Account homeTeam = new Account(Name = 'Home FC');
        Account awayTeam = new Account(Name = 'Away United');
        insert new List<Account>{ homeTeam, awayTeam };
        
        Match__c match = new Match__c(
            Competition__c = comp.Id,
            Home_Team__c = homeTeam.Id,
            Away_Team__c = awayTeam.Id,
            Match_Date_Time__c = Datetime.now(),
            Status__c = 'Scheduled'
        );
        insert match;
        
        // Create test articles
        List<Article__c> articles = new List<Article__c>();
        articles.add(new Article__c(
            Heading__c = 'Test Article 1',
            Body__c = 'Test content 1',
            Source__c = 'AI Generated',
            Sport_Type__c = 'Soccer',
            Article_Date__c = Date.today(),
            Is_Published__c = true,
            Match__c = match.Id
        ));
        articles.add(new Article__c(
            Heading__c = 'Test Article 2',
            Body__c = 'Test content 2',
            Source__c = 'Manual',
            Sport_Type__c = 'Basketball',
            Article_Date__c = Date.today().addDays(-5),
            Is_Published__c = false
        ));
        insert articles;
    }
    
    @IsTest
    static void testSelectById() {
        List<Article__c> articles = [SELECT Id FROM Article__c LIMIT 2];
        Set<Id> articleIds = new Set<Id>();
        for (Article__c a : articles) {
            articleIds.add(a.Id);
        }
        
        Test.startTest();
        IArticlesSelector selector = ArticlesSelector.newInstance();
        List<Article__c> results = selector.selectById(articleIds);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return 2 articles');
    }
    
    @IsTest
    static void testSelectByMatchId() {
        Match__c match = [SELECT Id FROM Match__c LIMIT 1];
        
        Test.startTest();
        IArticlesSelector selector = ArticlesSelector.newInstance();
        List<Article__c> results = selector.selectByMatchId(new Set<Id>{ match.Id });
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 article related to match');
        Assert.areEqual(match.Id, results[0].Match__c, 'Should be related to correct match');
    }
    
    @IsTest
    static void testSelectRecentBySport() {
        Test.startTest();
        IArticlesSelector selector = ArticlesSelector.newInstance();
        List<Article__c> results = selector.selectRecentBySport('Soccer', 7);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 soccer article from last 7 days');
        Assert.areEqual('Soccer', results[0].Sport_Type__c, 'Should be soccer article');
    }
    
    @IsTest
    static void testSelectBySource() {
        Test.startTest();
        IArticlesSelector selector = ArticlesSelector.newInstance();
        List<Article__c> results = selector.selectBySource('%AI Generated%');
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 AI-generated article');
    }
    
    @IsTest
    static void testSelectPublished() {
        Test.startTest();
        IArticlesSelector selector = ArticlesSelector.newInstance();
        List<Article__c> results = selector.selectPublished(10);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 published article');
        Assert.isTrue(results[0].Is_Published__c, 'Article should be published');
    }
    
    @IsTest
    static void testSelectDrafts() {
        Test.startTest();
        ArticlesSelector selector = new ArticlesSelector();
        List<Article__c> results = selector.selectDrafts();
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 draft article');
        Assert.isFalse(results[0].Is_Published__c, 'Article should not be published');
    }
}

