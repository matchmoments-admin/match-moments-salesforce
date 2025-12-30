/**
 * @description Centralized HTTP service for all AI API interactions
 * Similar to ESPNHttpService but for AI providers (Gemini, OpenAI, Anthropic)
 * @author Brendan Milton
 * @date 2025-12-30
 * 
 * Best Practices Implemented:
 * - Centralized HTTP callout logic
 * - Named Credential support
 * - Provider-specific request formatting
 * - Response parsing and error handling
 * - Token usage tracking
 * - Rate limiting support
 */
public with sharing class AIHttpService {
    
    // Constants
    private static final Integer HTTP_TIMEOUT = 120000; // 120 seconds for AI processing
    private static final String HTTP_METHOD_POST = 'POST';
    private static final String CONTENT_TYPE_JSON = 'application/json';
    
    // Rate limiting (simple implementation)
    private static Integer calloutCount = 0;
    private static final Integer MAX_CALLOUTS_PER_TRANSACTION = 10;
    
    /**
     * @description Make callout to Gemini API
     * @param endpoint API endpoint path (e.g., /v1/models/gemini-1.5-flash:generateContent)
     * @param requestBody JSON request body
     * @param apiKey API key for authentication
     * @return HttpResponse
     */
    public static HttpResponse callGemini(String endpoint, String requestBody, String apiKey) {
        String fullUrl = 'callout:Gemini_AI_API' + endpoint + '?key=' + apiKey;
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullUrl);
        request.setMethod(HTTP_METHOD_POST);
        request.setTimeout(HTTP_TIMEOUT);
        request.setHeader('Content-Type', CONTENT_TYPE_JSON);
        request.setBody(requestBody);
        
        return executeCallout(request, 'Gemini');
    }
    
    /**
     * @description Make callout to OpenAI API
     * @param endpoint API endpoint path (e.g., /v1/chat/completions)
     * @param requestBody JSON request body
     * @param apiKey API key for authentication
     * @return HttpResponse
     */
    public static HttpResponse callOpenAI(String endpoint, String requestBody, String apiKey) {
        String fullUrl = 'callout:OpenAI_API' + endpoint;
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullUrl);
        request.setMethod(HTTP_METHOD_POST);
        request.setTimeout(HTTP_TIMEOUT);
        request.setHeader('Content-Type', CONTENT_TYPE_JSON);
        request.setHeader('Authorization', 'Bearer ' + apiKey);
        request.setBody(requestBody);
        
        return executeCallout(request, 'OpenAI');
    }
    
    /**
     * @description Make callout to Anthropic API
     * @param endpoint API endpoint path (e.g., /v1/messages)
     * @param requestBody JSON request body
     * @param apiKey API key for authentication
     * @return HttpResponse
     */
    public static HttpResponse callAnthropic(String endpoint, String requestBody, String apiKey) {
        String fullUrl = 'callout:Anthropic_API' + endpoint;
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullUrl);
        request.setMethod(HTTP_METHOD_POST);
        request.setTimeout(HTTP_TIMEOUT);
        request.setHeader('Content-Type', CONTENT_TYPE_JSON);
        request.setHeader('x-api-key', apiKey);
        request.setHeader('anthropic-version', '2023-06-01');
        request.setBody(requestBody);
        
        return executeCallout(request, 'Anthropic');
    }
    
    /**
     * @description Execute HTTP callout with error handling and logging
     * @param request HttpRequest object
     * @param provider Provider name for logging
     * @return HttpResponse
     */
    @TestVisible
    private static HttpResponse executeCallout(HttpRequest request, String provider) {
        // Rate limiting check
        if (calloutCount >= MAX_CALLOUTS_PER_TRANSACTION) {
            throw new AIHttpException('Rate limit exceeded: Maximum ' + MAX_CALLOUTS_PER_TRANSACTION + ' AI callouts per transaction');
        }
        
        Long startTime = System.currentTimeMillis();
        
        try {
            System.debug('AIHttpService: Calling ' + provider + ' API');
            System.debug('Endpoint: ' + request.getEndpoint());
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            calloutCount++;
            
            Long duration = System.currentTimeMillis() - startTime;
            System.debug('AIHttpService: ' + provider + ' response in ' + duration + 'ms - Status: ' + response.getStatusCode());
            
            return response;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AIHttpService: Callout failed - ' + e.getMessage());
            throw new AIHttpException('HTTP Callout to ' + provider + ' failed: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Parse Gemini API response
     * @param responseBody JSON response body
     * @return Parsed content and metadata
     */
    public static GeminiResponse parseGeminiResponse(String responseBody) {
        GeminiResponse result = new GeminiResponse();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            // Parse candidates array
            List<Object> candidates = (List<Object>) responseMap.get('candidates');
            if (candidates != null && !candidates.isEmpty()) {
                Map<String, Object> candidate = (Map<String, Object>) candidates[0];
                Map<String, Object> content = (Map<String, Object>) candidate.get('content');
                
                if (content != null) {
                    List<Object> parts = (List<Object>) content.get('parts');
                    if (parts != null && !parts.isEmpty()) {
                        Map<String, Object> part = (Map<String, Object>) parts[0];
                        result.content = (String) part.get('text');
                    }
                }
                
                // Parse grounding metadata if available (for web search)
                Map<String, Object> groundingMetadata = (Map<String, Object>) candidate.get('groundingMetadata');
                if (groundingMetadata != null) {
                    result.hasGrounding = true;
                    // Parse grounding sources if needed
                }
            }
            
            // Parse usage metadata
            Map<String, Object> usageMetadata = (Map<String, Object>) responseMap.get('usageMetadata');
            if (usageMetadata != null) {
                result.inputTokens = (Integer) usageMetadata.get('promptTokenCount');
                result.outputTokens = (Integer) usageMetadata.get('candidatesTokenCount');
                result.totalTokens = (Integer) usageMetadata.get('totalTokenCount');
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse Gemini response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Parse OpenAI API response
     * @param responseBody JSON response body
     * @return Parsed content and metadata
     */
    public static OpenAIResponse parseOpenAIResponse(String responseBody) {
        OpenAIResponse result = new OpenAIResponse();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            // Parse choices array
            List<Object> choices = (List<Object>) responseMap.get('choices');
            if (choices != null && !choices.isEmpty()) {
                Map<String, Object> choice = (Map<String, Object>) choices[0];
                Map<String, Object> message = (Map<String, Object>) choice.get('message');
                
                if (message != null) {
                    result.content = (String) message.get('content');
                }
            }
            
            // Parse usage
            Map<String, Object> usage = (Map<String, Object>) responseMap.get('usage');
            if (usage != null) {
                result.inputTokens = (Integer) usage.get('prompt_tokens');
                result.outputTokens = (Integer) usage.get('completion_tokens');
                result.totalTokens = (Integer) usage.get('total_tokens');
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse OpenAI response: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }
        
        return result;
    }
    
    /**
     * @description Build Gemini request body for content generation
     * @param prompt The prompt text
     * @param maxTokens Maximum output tokens
     * @param useGrounding Whether to use Google Search grounding
     * @return JSON request body
     */
    public static String buildGeminiRequest(String prompt, Integer maxTokens, Boolean useGrounding) {
        Map<String, Object> requestMap = new Map<String, Object>();
        
        // Contents array
        List<Object> contents = new List<Object>();
        Map<String, Object> contentPart = new Map<String, Object>{
            'parts' => new List<Object>{
                new Map<String, Object>{ 'text' => prompt }
            }
        };
        contents.add(contentPart);
        requestMap.put('contents', contents);
        
        // Generation config
        Map<String, Object> generationConfig = new Map<String, Object>();
        if (maxTokens != null) {
            generationConfig.put('maxOutputTokens', maxTokens);
        }
        generationConfig.put('temperature', 0.7);
        requestMap.put('generationConfig', generationConfig);
        
        // Google Search grounding (for web search capability)
        if (useGrounding) {
            requestMap.put('tools', new List<Object>{
                new Map<String, Object>{
                    'googleSearchRetrieval' => new Map<String, Object>{
                        'dynamicRetrievalConfig' => new Map<String, Object>{
                            'mode' => 'MODE_DYNAMIC',
                            'dynamicThreshold' => 0.7
                        }
                    }
                }
            });
        }
        
        return JSON.serialize(requestMap);
    }
    
    /**
     * @description Build OpenAI request body for chat completion
     * @param prompt The prompt text
     * @param model Model name
     * @param maxTokens Maximum output tokens
     * @return JSON request body
     */
    public static String buildOpenAIRequest(String prompt, String model, Integer maxTokens) {
        Map<String, Object> requestMap = new Map<String, Object>();
        
        requestMap.put('model', model);
        requestMap.put('messages', new List<Object>{
            new Map<String, Object>{
                'role' => 'user',
                'content' => prompt
            }
        });
        
        if (maxTokens != null) {
            requestMap.put('max_tokens', maxTokens);
        }
        
        requestMap.put('temperature', 0.7);
        
        return JSON.serialize(requestMap);
    }
    
    // ========================================
    // WRAPPER CLASSES
    // ========================================
    
    public class GeminiResponse {
        public Boolean success { get; set; }
        public String errorMessage { get; set; }
        public String content { get; set; }
        public Integer inputTokens { get; set; }
        public Integer outputTokens { get; set; }
        public Integer totalTokens { get; set; }
        public Boolean hasGrounding { get; set; }
        
        public GeminiResponse() {
            this.success = false;
            this.hasGrounding = false;
        }
    }
    
    public class OpenAIResponse {
        public Boolean success { get; set; }
        public String errorMessage { get; set; }
        public String content { get; set; }
        public Integer inputTokens { get; set; }
        public Integer outputTokens { get; set; }
        public Integer totalTokens { get; set; }
        
        public OpenAIResponse() {
            this.success = false;
        }
    }
    
    public class AIHttpException extends Exception {}
}

