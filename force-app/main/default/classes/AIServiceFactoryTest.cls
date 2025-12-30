/**
 * @description Test class for AIServiceFactory
 * @author Brendan Milton
 * @date 2025-12-30
 */
@IsTest
private class AIServiceFactoryTest {
    
    @IsTest
    static void testGetInstanceReturnsGemini() {
        // Test getting Gemini instance (default active provider)
        Test.startTest();
        IAIService service = AIServiceFactory.getInstance();
        Test.stopTest();
        
        Assert.isNotNull(service, 'Service should not be null');
        Assert.isTrue(service instanceof GeminiAIServiceImpl, 'Should return Gemini implementation');
    }
    
    @IsTest
    static void testGetInstanceByProviderName() {
        // Test getting specific provider by name
        Test.startTest();
        IAIService geminiService = AIServiceFactory.getInstance('Gemini');
        Test.stopTest();
        
        Assert.isNotNull(geminiService, 'Gemini service should not be null');
        Assert.isTrue(geminiService instanceof GeminiAIServiceImpl, 'Should return Gemini implementation');
    }
    
    @IsTest
    static void testGetInstanceOpenAI() {
        // Test getting OpenAI instance
        Test.startTest();
        IAIService openaiService = AIServiceFactory.getInstance('OpenAI');
        Test.stopTest();
        
        Assert.isNotNull(openaiService, 'OpenAI service should not be null');
        Assert.isTrue(openaiService instanceof OpenAIServiceImpl, 'Should return OpenAI implementation');
    }
    
    @IsTest
    static void testClearCache() {
        // Test cache clearing
        IAIService service1 = AIServiceFactory.getInstance();
        
        Test.startTest();
        AIServiceFactory.clearCache();
        IAIService service2 = AIServiceFactory.getInstance();
        Test.stopTest();
        
        Assert.isNotNull(service1, 'First service should not be null');
        Assert.isNotNull(service2, 'Second service should not be null');
    }
    
    @IsTest
    static void testUnknownProvider() {
        // Test error handling for unknown provider
        Test.startTest();
        try {
            IAIService service = AIServiceFactory.getInstance('UnknownProvider');
            Assert.fail('Should throw exception for unknown provider');
        } catch (AIServiceFactory.AIServiceException e) {
            Assert.isTrue(e.getMessage().contains('Unknown'), 'Should mention unknown provider');
        }
        Test.stopTest();
    }
}

