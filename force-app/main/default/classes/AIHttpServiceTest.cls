/**
 * @description Test class for AIHttpService
 * @author Brendan Milton
 * @date 2025-12-30
 */
@IsTest
private class AIHttpServiceTest {
    
    @IsTest
    static void testBuildGeminiRequest() {
        // Test building Gemini request with grounding
        String prompt = 'Search for latest soccer scores';
        Integer maxTokens = 1000;
        Boolean useGroounding = true;
        
        Test.startTest();
        String requestBody = AIHttpService.buildGeminiRequest(prompt, maxTokens, useGrounding);
        Test.stopTest();
        
        Assert.isNotNull(requestBody, 'Request body should not be null');
        Assert.isTrue(requestBody.contains('contents'), 'Should contain contents array');
        Assert.isTrue(requestBody.contains(prompt), 'Should contain prompt text');
        Assert.isTrue(requestBody.contains('googleSearchRetrieval'), 'Should contain grounding config');
    }
    
    @IsTest
    static void testBuildGeminiRequestWithoutGrounding() {
        // Test building Gemini request without grounding
        String prompt = 'Generate article content';
        Integer maxTokens = 2000;
        Boolean useGroounding = false;
        
        Test.startTest();
        String requestBody = AIHttpService.buildGeminiRequest(prompt, maxTokens, useGroounding);
        Test.stopTest();
        
        Assert.isNotNull(requestBody, 'Request body should not be null');
        Assert.isTrue(requestBody.contains('contents'), 'Should contain contents array');
        Assert.isFalse(requestBody.contains('googleSearchRetrieval'), 'Should not contain grounding config');
    }
    
    @IsTest
    static void testBuildOpenAIRequest() {
        // Test building OpenAI request
        String prompt = 'Generate match preview';
        String model = 'gpt-4o';
        Integer maxTokens = 1500;
        
        Test.startTest();
        String requestBody = AIHttpService.buildOpenAIRequest(prompt, model, maxTokens);
        Test.stopTest();
        
        Assert.isNotNull(requestBody, 'Request body should not be null');
        Assert.isTrue(requestBody.contains('messages'), 'Should contain messages array');
        Assert.isTrue(requestBody.contains(model), 'Should contain model name');
        Assert.isTrue(requestBody.contains(prompt), 'Should contain prompt text');
    }
    
    @IsTest
    static void testParseGeminiResponse() {
        // Test parsing successful Gemini response
        String mockResponse = '{"candidates": [{"content": {"parts": [{"text": "Generated content here"}]},' +
            '"groundingMetadata": {}}],"usageMetadata": {"promptTokenCount": 10,"candidatesTokenCount": 20,"totalTokenCount": 30}}';
        
        Test.startTest();
        AIHttpService.GeminiResponse result = AIHttpService.parseGeminiResponse(mockResponse);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Should parse successfully');
        Assert.areEqual('Generated content here', result.content, 'Should extract content');
        Assert.areEqual(30, result.totalTokens, 'Should extract token count');
        Assert.isTrue(result.hasGrounding, 'Should detect grounding');
    }
    
    @IsTest
    static void testParseOpenAIResponse() {
        // Test parsing OpenAI response
        String mockResponse = '{"choices": [{"message": {"content": "AI generated text"}}],' +
            '"usage": {"prompt_tokens": 15,"completion_tokens": 25,"total_tokens": 40}}';
        
        Test.startTest();
        AIHttpService.OpenAIResponse result = AIHttpService.parseOpenAIResponse(mockResponse);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Should parse successfully');
        Assert.areEqual('AI generated text', result.content, 'Should extract content');
        Assert.areEqual(40, result.totalTokens, 'Should extract token count');
    }
    
    @IsTest
    static void testParseInvalidResponse() {
        // Test parsing invalid JSON
        String invalidResponse = 'Invalid JSON {{{';
        
        Test.startTest();
        AIHttpService.GeminiResponse result = AIHttpService.parseGeminiResponse(invalidResponse);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail to parse');
        Assert.isNotNull(result.errorMessage, 'Should have error message');
    }
}

