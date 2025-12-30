/**
 * @description Gemini AI Service Implementation
 * Implements IAIService for Google Gemini API
 * Uses Gemini's grounding feature for web search capability
 * @author Brendan Milton
 * @date 2025-12-30
 */
public inherited sharing class GeminiAIServiceImpl implements IAIService {
    
    // Gemini API constants
    private static final String GEMINI_GENERATE_ENDPOINT = '/v1beta/models/{model}:generateContent';
    private static final String DEFAULT_MODEL = 'gemini-1.5-flash';
    
    // Configuration
    private AI_Provider_Config__mdt config;
    private String apiKey;
    
    /**
     * @description Constructor - loads config from Custom Metadata
     */
    public GeminiAIServiceImpl() {
        loadConfiguration();
    }
    
    /**
     * @description Search sports websites for data using Gemini with Google Search grounding
     * @param query The search query
     * @param sport Sport type
     * @param searchDate Date to focus search on
     * @return AIResponse with search results
     */
    public AIResponse searchSportsData(String query, String sport, Date searchDate) {
        String enhancedPrompt = buildSportsSearchPrompt(query, sport, searchDate);
        return generateFromPrompt(enhancedPrompt, null);
    }
    
    /**
     * @description Generate article content
     * @param topic Article topic
     * @param context Contextual data
     * @return AIResponse with article content
     */
    public AIResponse generateArticle(String topic, Map<String, Object> context) {
        String prompt = buildArticlePrompt(topic, context);
        Integer maxTokens = Integer.valueOf(config.Max_Tokens__c);
        return generateFromPrompt(prompt, maxTokens);
    }
    
    /**
     * @description Summarize a Salesforce record
     * @param recordId Record ID
     * @param objectType SObject type
     * @return AIResponse with summary
     */
    public AIResponse summarizeRecord(Id recordId, SObjectType objectType) {
        // Query record data
        String recordData = queryRecordForSummary(recordId, objectType);
        
        String prompt = 'Summarize the following ' + objectType.getDescribe().getLabel() + ' record in 2-3 sentences:\n\n' + recordData;
        
        return generateFromPrompt(prompt, 500);
    }
    
    /**
     * @description Generate match-specific content
     * @param matchId Match__c record ID
     * @param contentType Type of content
     * @return AIResponse with content
     */
    public AIResponse generateMatchContent(Id matchId, String contentType) {
        // Query match data
        Match__c match = queryMatchForContent(matchId);
        
        String prompt;
        Integer maxTokens;
        
        switch on contentType.toLowerCase() {
            when 'preview' {
                prompt = AIPromptTemplates.getMatchPreviewPrompt(match);
                maxTokens = 1000;
            }
            when 'recap' {
                prompt = AIPromptTemplates.getMatchRecapPrompt(match);
                maxTokens = 1200;
            }
            when 'tweet' {
                prompt = buildTweetPrompt(match);
                maxTokens = 100;
            }
            when else {
                prompt = 'Generate content about this match: ' + match.Name;
                maxTokens = 800;
            }
        }
        
        return generateFromPrompt(prompt, maxTokens);
    }
    
    /**
     * @description Generate content from custom prompt
     * @param prompt The prompt
     * @param maxTokens Token limit
     * @return AIResponse with generated content
     */
    public AIResponse generateFromPrompt(String prompt, Integer maxTokens) {
        Long startTime = System.currentTimeMillis();
        AIResponse response = new AIResponse();
        
        try {
            // Use grounding for sports data searches (if prompt contains keywords)
            Boolean useGrounding = shouldUseGrounding(prompt);
            
            // Set max tokens from config if not provided
            if (maxTokens == null) {
                maxTokens = Integer.valueOf(config.Max_Tokens__c);
            }
            
            // Build request
            String requestBody = AIHttpService.buildGeminiRequest(prompt, maxTokens, useGrounding);
            
            // Get API key (in production, retrieve from Named Credential or Custom Setting)
            String apiKey = getApiKey();
            
            // Build endpoint
            String model = config.Model_Name__c;
            String endpoint = GEMINI_GENERATE_ENDPOINT.replace('{model}', model);
            
            // Make callout
            HttpResponse httpResponse = AIHttpService.callGemini(endpoint, requestBody, apiKey);
            
            // Parse response
            if (httpResponse.getStatusCode() == 200) {
                AIHttpService.GeminiResponse geminiResp = AIHttpService.parseGeminiResponse(httpResponse.getBody());
                
                if (geminiResp.success) {
                    response.success = true;
                    response.content = geminiResp.content;
                    response.tokensUsed = geminiResp.totalTokens;
                    response.provider = 'Gemini';
                    response.model = model;
                    response.rawResponse = httpResponse.getBody();
                    
                    // Calculate estimated cost
                    if (geminiResp.totalTokens != null) {
                        Decimal costPer1K = config.Cost_Per_1K_Tokens__c;
                        response.estimatedCost = (geminiResp.totalTokens / 1000.0) * costPer1K;
                    }
                } else {
                    response.success = false;
                    response.errorMessage = geminiResp.errorMessage;
                }
            } else {
                response.success = false;
                response.errorMessage = 'HTTP ' + httpResponse.getStatusCode() + ': ' + httpResponse.getStatus();
                System.debug('Gemini API error: ' + httpResponse.getBody());
            }
            
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = 'Gemini AI error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, response.errorMessage + '\n' + e.getStackTraceString());
        }
        
        response.responseTimeMs = System.currentTimeMillis() - startTime;
        return response;
    }
    
    /**
     * @description Extract structured data from text
     * @param text Unstructured text
     * @param schema Expected data schema
     * @return AIResponse with structured data
     */
    public AIResponse extractStructuredData(String text, Map<String, String> schema) {
        String prompt = buildExtractionPrompt(text, schema);
        AIResponse response = generateFromPrompt(prompt, 2000);
        
        // Parse JSON response into structured data map
        if (response.success && String.isNotBlank(response.content)) {
            try {
                response.structuredData = (Map<String, Object>) JSON.deserializeUntyped(response.content);
            } catch (Exception e) {
                System.debug('Failed to parse structured data: ' + e.getMessage());
            }
        }
        
        return response;
    }
    
    // =========================================================================
    // PRIVATE HELPER METHODS
    // =========================================================================
    
    /**
     * @description Load AI provider configuration from Custom Metadata
     */
    private void loadConfiguration() {
        List<AI_Provider_Config__mdt> configs = [
            SELECT Provider_Name__c, Named_Credential__c, Model_Name__c, 
                   Max_Tokens__c, Is_Active__c, Priority__c, Cost_Per_1K_Tokens__c
            FROM AI_Provider_Config__mdt
            WHERE Provider_Name__c = 'Gemini'
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new GeminiException('No active Gemini configuration found in AI_Provider_Config__mdt');
        }
        
        this.config = configs[0];
    }
    
    /**
     * @description Get API key (placeholder - implement secure retrieval)
     * TODO: Implement secure API key retrieval from Named Credential or Protected Custom Setting
     */
    private String getApiKey() {
        // In production, retrieve from Named Credential or secure storage
        // For now, return placeholder that will be configured via Named Credential
        return '{!$Credential.Gemini_AI_API.Password}';
    }
    
    /**
     * @description Determine if grounding should be used based on prompt content
     */
    private Boolean shouldUseGrounding(String prompt) {
        String lowerPrompt = prompt.toLowerCase();
        List<String> groundingKeywords = new List<String>{
            'search', 'find', 'latest', 'recent', 'news', 'score', 'result', 'standing', 'fixture'
        };
        
        for (String keyword : groundingKeywords) {
            if (lowerPrompt.contains(keyword)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * @description Build enhanced prompt for sports data search
     */
    private String buildSportsSearchPrompt(String query, String sport, Date searchDate) {
        String dateStr = searchDate != null ? searchDate.format() : Date.today().format();
        
        return 'Search for the latest ' + sport + ' information: ' + query + '\n' +
               'Focus on data from ' + dateStr + ' or the most recent available.\n' +
               'Provide factual, structured information including:\n' +
               '- Match results and scores\n' +
               '- Team standings\n' +
               '- Upcoming fixtures\n' +
               '- Player statistics if relevant\n' +
               'Format the response clearly with sources.';
    }
    
    /**
     * @description Build prompt for article generation
     */
    private String buildArticlePrompt(String topic, Map<String, Object> context) {
        String prompt = 'Write a professional sports article about: ' + topic + '\n\n';
        
        if (context != null && !context.isEmpty()) {
            prompt += 'Context:\n';
            for (String key : context.keySet()) {
                prompt += '- ' + key + ': ' + String.valueOf(context.get(key)) + '\n';
            }
        }
        
        prompt += '\nRequirements:\n';
        prompt += '- Write in a professional, engaging style\n';
        prompt += '- Include relevant statistics and facts\n';
        prompt += '- Target audience: Sports fans and enthusiasts\n';
        prompt += '- Length: 500-800 words\n';
        prompt += '- Include an attention-grabbing headline';
        
        return prompt;
    }
    
    /**
     * @description Build prompt for tweet generation
     */
    private String buildTweetPrompt(Match__c match) {
        String prompt = 'Create an engaging tweet about this match:\n';
        prompt += match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name + '\n';
        
        if (match.Status__c == 'Completed' || match.Status__c == 'Final') {
            prompt += 'Score: ' + match.Home_Score_Final__c + ' - ' + match.Away_Score_Final__c + '\n';
        }
        
        prompt += '\nRequirements:\n';
        prompt += '- Maximum 280 characters\n';
        prompt += '- Include relevant emojis\n';
        prompt += '- Engaging and shareable\n';
        prompt += '- Focus on key highlights';
        
        return prompt;
    }
    
    /**
     * @description Build prompt for data extraction
     */
    private String buildExtractionPrompt(String text, Map<String, String> schema) {
        String prompt = 'Extract the following information from the text and return as JSON:\n\n';
        
        prompt += 'Expected fields:\n';
        for (String fieldName : schema.keySet()) {
            prompt += '- ' + fieldName + ' (' + schema.get(fieldName) + ')\n';
        }
        
        prompt += '\nText to analyze:\n' + text + '\n\n';
        prompt += 'Return only valid JSON with the specified fields. If a field is not found, use null.';
        
        return prompt;
    }
    
    /**
     * @description Query record data for summarization
     */
    private String queryRecordForSummary(Id recordId, SObjectType objectType) {
        // Build dynamic SOQL to get all accessible fields
        String objectName = objectType.getDescribe().getName();
        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        
        List<String> fieldNames = new List<String>();
        for (String fieldName : fields.keySet()) {
            if (fields.get(fieldName).getDescribe().isAccessible()) {
                fieldNames.add(fieldName);
                if (fieldNames.size() >= 20) break; // Limit to 20 fields
            }
        }
        
        String soql = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
        
        SObject record = Database.query(soql);
        return JSON.serializePretty(record);
    }
    
    /**
     * @description Query match data for content generation
     */
    private Match__c queryMatchForContent(Id matchId) {
        return [
            SELECT Id, Name, Match_Date_Time__c, Status__c, Venue__c,
                   Home_Score_Final__c, Away_Score_Final__c,
                   Home_Team__r.Name, Away_Team__r.Name,
                   Competition__r.Name, Competition__r.Sport__c
            FROM Match__c
            WHERE Id = :matchId
            LIMIT 1
        ];
    }
    
    public class GeminiException extends Exception {}
}

