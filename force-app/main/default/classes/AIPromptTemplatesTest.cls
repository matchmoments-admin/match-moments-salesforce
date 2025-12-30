/**
 * @description Test class for AIPromptTemplates
 * @author Brendan Milton
 * @date 2025-12-30
 */
@IsTest
private class AIPromptTemplatesTest {
    
    @IsTest
    static void testGetMatchPreviewPrompt() {
        // Create test data
        Competition__c comp = new Competition__c(Name = 'Test League', Sport__c = 'Soccer');
        insert comp;
        
        Account homeTeam = new Account(Name = 'Home FC');
        Account awayTeam = new Account(Name = 'Away United');
        insert new List<Account>{ homeTeam, awayTeam };
        
        Match__c match = new Match__c(
            Competition__c = comp.Id,
            Home_Team__c = homeTeam.Id,
            Away_Team__c = awayTeam.Id,
            Match_Date_Time__c = Datetime.now().addDays(1),
            Venue__c = 'Test Stadium'
        );
        insert match;
        
        match = [SELECT Id, Name, Competition__r.Name, Home_Team__r.Name, Away_Team__r.Name,
                 Match_Date_Time__c, Venue__c FROM Match__c WHERE Id = :match.Id];
        
        Test.startTest();
        String prompt = AIPromptTemplates.getMatchPreviewPrompt(match);
        Test.stopTest();
        
        Assert.isNotNull(prompt, 'Prompt should not be null');
        Assert.isTrue(prompt.contains('preview'), 'Should contain preview keyword');
        Assert.isTrue(prompt.contains(homeTeam.Name), 'Should contain home team name');
        Assert.isTrue(prompt.contains(awayTeam.Name), 'Should contain away team name');
    }
    
    @IsTest
    static void testGetMatchRecapPrompt() {
        // Create test data
        Competition__c comp = new Competition__c(Name = 'Test League', Sport__c = 'Soccer');
        insert comp;
        
        Account homeTeam = new Account(Name = 'Home FC');
        Account awayTeam = new Account(Name = 'Away United');
        insert new List<Account>{ homeTeam, awayTeam };
        
        Match__c match = new Match__c(
            Competition__c = comp.Id,
            Home_Team__c = homeTeam.Id,
            Away_Team__c = awayTeam.Id,
            Match_Date_Time__c = Datetime.now(),
            Home_Score_Final__c = 2,
            Away_Score_Final__c = 1,
            Status__c = 'Completed'
        );
        insert match;
        
        match = [SELECT Id, Name, Competition__r.Name, Home_Team__r.Name, Away_Team__r.Name,
                 Home_Score_Final__c, Away_Score_Final__c, Venue__c FROM Match__c WHERE Id = :match.Id];
        
        Test.startTest();
        String prompt = AIPromptTemplates.getMatchRecapPrompt(match);
        Test.stopTest();
        
        Assert.isNotNull(prompt, 'Prompt should not be null');
        Assert.isTrue(prompt.contains('recap'), 'Should contain recap keyword');
        Assert.isTrue(prompt.contains('2'), 'Should contain home score');
        Assert.isTrue(prompt.contains('1'), 'Should contain away score');
    }
    
    @IsTest
    static void testGetArticleGenerationPrompt() {
        String topic = 'Women in Sports';
        Map<String, Object> context = new Map<String, Object>{
            'sport' => 'Soccer',
            'league' => 'WSL',
            'focus' => 'Growth and viewership'
        };
        
        Test.startTest();
        String prompt = AIPromptTemplates.getArticleGenerationPrompt(topic, context);
        Test.stopTest();
        
        Assert.isNotNull(prompt, 'Prompt should not be null');
        Assert.isTrue(prompt.contains(topic), 'Should contain topic');
        Assert.isTrue(prompt.contains('Soccer'), 'Should contain context data');
    }
    
    @IsTest
    static void testGetCompetitionNewsPrompt() {
        Test.startTest();
        String prompt = AIPromptTemplates.getCompetitionNewsPrompt('Premier League', 'last 7 days');
        Test.stopTest();
        
        Assert.isNotNull(prompt, 'Prompt should not be null');
        Assert.isTrue(prompt.contains('Premier League'), 'Should contain competition name');
        Assert.isTrue(prompt.contains('last 7 days'), 'Should contain date range');
    }
    
    @IsTest
    static void testGetSocialMediaPrompt() {
        Test.startTest();
        String prompt = AIPromptTemplates.getSocialMediaPrompt('Match result', 'Twitter', 280);
        Test.stopTest();
        
        Assert.isNotNull(prompt, 'Prompt should not be null');
        Assert.isTrue(prompt.contains('280'), 'Should contain character limit');
        Assert.isTrue(prompt.contains('Twitter'), 'Should contain platform');
    }
}

