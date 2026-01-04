/**
 * ArticleGeneratorController
 * 
 * Apex controller for AI Article Helper LWC component
 * Integrates with deployed AI services (Gemini, OpenAI, Anthropic)
 * 
 * JAVASCRIPT DEVELOPER I EXAM RELEVANCE:
 * - Server-Side JavaScript (8% of exam)
 * - Understanding how LWC communicates with Apex
 * - @AuraEnabled annotation for LWC accessibility
 * - JSON serialization/deserialization
 */
public with sharing class ArticleGeneratorController {
    
    /**
     * Generate AI article based on parameters
     * 
     * @param params Map containing article type, record IDs, and context
     * @return Map with generated article data
     * 
     * EXAM CONCEPT: @AuraEnabled makes method callable from LWC
     * cacheable=false because we want fresh AI generation each time
     */
    @AuraEnabled
    public static Map<String, Object> generateArticle(Map<String, Object> params) {
        try {
            // Extract parameters
            String articleType = (String) params.get('articleType');
            String matchId = (String) params.get('matchId');
            String teamId = (String) params.get('teamId');
            String playerId = (String) params.get('playerId');
            String additionalContext = (String) params.get('additionalContext');
            
            // Build prompt based on article type and context
            String prompt = buildPrompt(articleType, matchId, teamId, playerId, additionalContext);
            
            // Get AI service instance (uses factory pattern from deployment)
            IAIService aiService = AIServiceFactory.getInstance();
            
            // Generate article using AI
            AIResponse response = aiService.generateFromPrompt(prompt, null);
            
            // Parse response and extract article components
            Map<String, Object> articleData = parseAIResponse(response, articleType);
            
            // Add metadata
            articleData.put('provider', response.provider);
            articleData.put('tokensUsed', response.tokensUsed);
            
            return articleData;
            
        } catch (Exception e) {
            // EXAM CONCEPT: Error handling in Apex
            throw new AuraHandledException('Failed to generate article: ' + e.getMessage());
        }
    }
    
    /**
     * Save generated article to Article__c object
     * 
     * @param articleData Map containing article fields
     * @return String Article record ID
     */
    @AuraEnabled
    public static String saveArticle(Map<String, Object> articleData) {
        try {
            // Create Article__c record
            Article__c article = new Article__c();
            article.Heading__c = (String) articleData.get('heading');
            article.Body__c = (String) articleData.get('body');
            article.Article_Type__c = (String) articleData.get('articleType');
            article.Sport_Type__c = (String) articleData.get('sportType');
            article.Reading_Time__c = (Decimal) articleData.get('readingTime');
            article.Source__c = (String) articleData.get('source');
            article.Is_Published__c = false;
            article.Article_Date__c = Date.today();
            
            // Set relationships if provided
            if (articleData.containsKey('matchId') && articleData.get('matchId') != null) {
                article.Related_Match__c = (String) articleData.get('matchId');
            }
            if (articleData.containsKey('teamId') && articleData.get('teamId') != null) {
                article.Related_Team__c = (String) articleData.get('teamId');
            }
            if (articleData.containsKey('playerId') && articleData.get('playerId') != null) {
                article.Related_Player__c = (String) articleData.get('playerId');
            }
            
            insert article;
            
            return article.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to save article: ' + e.getMessage());
        }
    }
    
    // ============================================================================
    // PRIVATE HELPER METHODS
    // ============================================================================
    
    /**
     * Build AI prompt based on article type and context
     */
    private static String buildPrompt(String articleType, String matchId, String teamId, 
                                     String playerId, String additionalContext) {
        String prompt = '';
        
        // Fetch context data based on IDs
        Map<String, Object> contextData = fetchContextData(matchId, teamId, playerId);
        
        switch on articleType {
            when 'matchPreview' {
                prompt = buildMatchPreviewPrompt(contextData, additionalContext);
            }
            when 'matchRecap' {
                prompt = buildMatchRecapPrompt(contextData, additionalContext);
            }
            when 'teamAnalysis' {
                prompt = buildTeamAnalysisPrompt(contextData, additionalContext);
            }
            when 'playerProfile' {
                prompt = buildPlayerProfilePrompt(contextData, additionalContext);
            }
            when 'seasonReview' {
                prompt = buildSeasonReviewPrompt(contextData, additionalContext);
            }
        }
        
        return prompt;
    }
    
    /**
     * Fetch relevant data for AI context
     */
    private static Map<String, Object> fetchContextData(String matchId, String teamId, String playerId) {
        Map<String, Object> context = new Map<String, Object>();
        
        // Fetch match data if provided
        if (String.isNotBlank(matchId)) {
            List<Match__c> matches = [
                SELECT Id, Name, Home_Team__r.Name, Away_Team__r.Name, 
                       Competition__r.Name, Match_Date_Time__c, Status__c,
                       Home_Score_Final__c, Away_Score_Final__c, Venue__c
                FROM Match__c 
                WHERE Id = :matchId 
                LIMIT 1
            ];
            if (!matches.isEmpty()) {
                context.put('match', matches[0]);
            }
        }
        
        // Fetch team data if provided
        if (String.isNotBlank(teamId)) {
            List<Account> teams = [
                SELECT Id, Name, Sport_Type__c, League__c, Description
                FROM Account 
                WHERE Id = :teamId 
                LIMIT 1
            ];
            if (!teams.isEmpty()) {
                context.put('team', teams[0]);
            }
        }
        
        // Fetch player data if provided
        if (String.isNotBlank(playerId)) {
            List<Contact> players = [
                SELECT Id, Name, Position__c, Current_Team__r.Name, 
                       Nationality__c, Date_of_Birth__c
                FROM Contact 
                WHERE Id = :playerId 
                LIMIT 1
            ];
            if (!players.isEmpty()) {
                context.put('player', players[0]);
            }
        }
        
        return context;
    }
    
    /**
     * Build match preview prompt
     */
    private static String buildMatchPreviewPrompt(Map<String, Object> context, String additionalContext) {
        Match__c match = (Match__c) context.get('match');
        
        String prompt = 'Write an engaging match preview article for:\n\n';
        prompt += 'Match: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name + '\n';
        prompt += 'Competition: ' + match.Competition__r.Name + '\n';
        prompt += 'Date: ' + match.Match_Date_Time__c + '\n';
        if (String.isNotBlank(match.Venue__c)) {
            prompt += 'Venue: ' + match.Venue__c + '\n';
        }
        prompt += '\n';
        
        if (String.isNotBlank(additionalContext)) {
            prompt += 'Additional Context: ' + additionalContext + '\n\n';
        }
        
        prompt += 'Please provide:\n';
        prompt += '1. A compelling headline (max 10 words)\n';
        prompt += '2. An article body (400-600 words) covering:\n';
        prompt += '   - Team form and recent performances\n';
        prompt += '   - Key players to watch\n';
        prompt += '   - Tactical matchup analysis\n';
        prompt += '   - Prediction and what\'s at stake\n';
        prompt += '\nFormat: Return as JSON with "headline" and "body" fields.';
        
        return prompt;
    }
    
    /**
     * Build match recap prompt
     */
    private static String buildMatchRecapPrompt(Map<String, Object> context, String additionalContext) {
        Match__c match = (Match__c) context.get('match');
        
        String prompt = 'Write a match recap article for:\n\n';
        prompt += 'Match: ' + match.Home_Team__r.Name + ' ' + match.Home_Score_Final__c + ' - ';
        prompt += match.Away_Score_Final__c + ' ' + match.Away_Team__r.Name + '\n';
        prompt += 'Competition: ' + match.Competition__r.Name + '\n';
        
        if (String.isNotBlank(additionalContext)) {
            prompt += 'Additional Context: ' + additionalContext + '\n\n';
        }
        
        prompt += 'Please provide:\n';
        prompt += '1. A compelling headline (max 10 words)\n';
        prompt += '2. An article body (400-600 words) covering:\n';
        prompt += '   - Match summary and key moments\n';
        prompt += '   - Turning points and crucial plays\n';
        prompt += '   - Player performances and statistics\n';
        prompt += '   - Implications for both teams\n';
        prompt += '\nFormat: Return as JSON with "headline" and "body" fields.';
        
        return prompt;
    }
    
    /**
     * Build team analysis prompt
     */
    private static String buildTeamAnalysisPrompt(Map<String, Object> context, String additionalContext) {
        Account team = (Account) context.get('team');
        
        String prompt = 'Write a team analysis article for:\n\n';
        prompt += 'Team: ' + team.Name + '\n';
        prompt += 'Sport: ' + team.Sport_Type__c + '\n';
        if (String.isNotBlank(team.League__c)) {
            prompt += 'League: ' + team.League__c + '\n';
        }
        
        if (String.isNotBlank(additionalContext)) {
            prompt += 'Additional Context: ' + additionalContext + '\n\n';
        }
        
        prompt += 'Please provide:\n';
        prompt += '1. A compelling headline (max 10 words)\n';
        prompt += '2. An article body (500-700 words) covering:\n';
        prompt += '   - Current season performance\n';
        prompt += '   - Tactical approach and playing style\n';
        prompt += '   - Strengths and weaknesses\n';
        prompt += '   - Outlook for remainder of season\n';
        prompt += '\nFormat: Return as JSON with "headline" and "body" fields.';
        
        return prompt;
    }
    
    /**
     * Build player profile prompt
     */
    private static String buildPlayerProfilePrompt(Map<String, Object> context, String additionalContext) {
        Contact player = (Contact) context.get('player');
        
        String prompt = 'Write a player profile article for:\n\n';
        prompt += 'Player: ' + player.Name + '\n';
        prompt += 'Position: ' + player.Position__c + '\n';
        prompt += 'Team: ' + (player.Current_Team__r != null ? player.Current_Team__r.Name : 'N/A') + '\n';
        if (String.isNotBlank(player.Nationality__c)) {
            prompt += 'Nationality: ' + player.Nationality__c + '\n';
        }
        
        if (String.isNotBlank(additionalContext)) {
            prompt += 'Additional Context: ' + additionalContext + '\n\n';
        }
        
        prompt += 'Please provide:\n';
        prompt += '1. A compelling headline (max 10 words)\n';
        prompt += '2. An article body (500-700 words) covering:\n';
        prompt += '   - Background and career journey\n';
        prompt += '   - Playing style and strengths\n';
        prompt += '   - Season highlights and statistics\n';
        prompt += '   - Impact on team and future outlook\n';
        prompt += '\nFormat: Return as JSON with "headline" and "body" fields.';
        
        return prompt;
    }
    
    /**
     * Build season review prompt
     */
    private static String buildSeasonReviewPrompt(Map<String, Object> context, String additionalContext) {
        Account team = (Account) context.get('team');
        
        String prompt = 'Write a season review article for:\n\n';
        prompt += 'Team: ' + team.Name + '\n';
        prompt += 'Sport: ' + team.Sport_Type__c + '\n';
        
        if (String.isNotBlank(additionalContext)) {
            prompt += 'Additional Context: ' + additionalContext + '\n\n';
        }
        
        prompt += 'Please provide:\n';
        prompt += '1. A compelling headline (max 10 words)\n';
        prompt += '2. An article body (600-800 words) covering:\n';
        prompt += '   - Season summary and final standings\n';
        prompt += '   - Key highlights and memorable moments\n';
        prompt += '   - Player performances and awards\n';
        prompt += '   - Areas of success and improvement\n';
        prompt += '   - Offseason outlook and expectations\n';
        prompt += '\nFormat: Return as JSON with "headline" and "body" fields.';
        
        return prompt;
    }
    
    /**
     * Parse AI response and extract article components
     */
    private static Map<String, Object> parseAIResponse(AIResponse response, String articleType) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // AI should return JSON with headline and body
            Map<String, Object> aiData = (Map<String, Object>) JSON.deserializeUntyped(response.content);
            
            result.put('headline', aiData.get('headline'));
            result.put('body', aiData.get('body'));
            
            // Calculate reading time (assuming 200 words per minute)
            String body = (String) aiData.get('body');
            Integer wordCount = body.split('\\s+').size();
            Integer readingTime = (Integer) Math.ceil(wordCount / 200.0);
            result.put('readingTime', readingTime);
            
            // Determine sport type based on article type
            result.put('sport', determineSportType(articleType));
            
        } catch (Exception e) {
            // Fallback if AI doesn't return proper JSON
            result.put('headline', 'AI Generated Article');
            result.put('body', response.content);
            result.put('readingTime', 5);
            result.put('sport', 'General');
        }
        
        return result;
    }
    
    /**
     * Determine sport type from context
     */
    private static String determineSportType(String articleType) {
        // This is a simplified version - in production you'd extract from actual data
        return 'Soccer'; // Default
    }
}