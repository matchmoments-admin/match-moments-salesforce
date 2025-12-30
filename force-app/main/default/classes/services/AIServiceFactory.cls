/**
 * @description Factory for AI Service implementations
 * Loads provider configuration from Custom Metadata and returns appropriate service
 * Enables easy switching between AI providers (Gemini, OpenAI, Anthropic)
 * @author Brendan Milton
 * @date 2025-12-30
 */
public class AIServiceFactory {
    
    // Cache the service instance
    private static IAIService cachedInstance;
    
    /**
     * @description Get AI service instance based on active provider configuration
     * Returns cached instance if available
     * @return IAIService Active AI service implementation
     */
    public static IAIService getInstance() {
        if (cachedInstance != null) {
            return cachedInstance;
        }
        
        // Query active AI provider configs ordered by priority
        List<AI_Provider_Config__mdt> configs = [
            SELECT Provider_Name__c, Named_Credential__c, Model_Name__c, 
                   Max_Tokens__c, Is_Active__c, Priority__c
            FROM AI_Provider_Config__mdt
            WHERE Is_Active__c = true
            ORDER BY Priority__c ASC NULLS LAST
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            throw new AIServiceException('No active AI provider found. Please configure AI_Provider_Config__mdt.');
        }
        
        AI_Provider_Config__mdt config = configs[0];
        cachedInstance = createServiceInstance(config.Provider_Name__c);
        
        return cachedInstance;
    }
    
    /**
     * @description Get AI service instance for a specific provider
     * @param providerName Provider name (Gemini, OpenAI, Anthropic)
     * @return IAIService Specific AI service implementation
     */
    public static IAIService getInstance(String providerName) {
        return createServiceInstance(providerName);
    }
    
    /**
     * @description Clear cached service instance
     * Useful for testing or forcing re-initialization
     */
    public static void clearCache() {
        cachedInstance = null;
    }
    
    /**
     * @description Create service instance based on provider name
     * @param providerName Provider name
     * @return IAIService Service implementation
     */
    private static IAIService createServiceInstance(String providerName) {
        switch on providerName.toLowerCase() {
            when 'gemini' {
                return new GeminiAIServiceImpl();
            }
            when 'openai' {
                return new OpenAIServiceImpl();
            }
            when 'anthropic' {
                // TODO: Implement AnthropicAIServiceImpl
                throw new AIServiceException('Anthropic provider not yet implemented');
            }
            when 'einstein' {
                // TODO: Implement EinsteinAIServiceImpl
                throw new AIServiceException('Einstein provider not yet implemented');
            }
            when else {
                throw new AIServiceException('Unknown AI provider: ' + providerName);
            }
        }
    }
    
    public class AIServiceException extends Exception {}
}

