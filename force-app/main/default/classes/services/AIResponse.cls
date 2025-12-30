/**
 * @description Wrapper class for AI API responses
 * Standardizes response format across different AI providers
 * @author Brendan Milton
 * @date 2025-12-30
 */
public class AIResponse {
    
    // Response status
    public Boolean success { get; set; }
    public String errorMessage { get; set; }
    
    // Content fields
    public String content { get; set; }
    public String rawResponse { get; set; }
    
    // Metadata
    public String provider { get; set; }
    public String model { get; set; }
    public Integer tokensUsed { get; set; }
    public Decimal estimatedCost { get; set; }
    public Long responseTimeMs { get; set; }
    
    // Structured data (for web search results)
    public Map<String, Object> structuredData { get; set; }
    public List<SearchResult> searchResults { get; set; }
    
    /**
     * @description Default constructor
     */
    public AIResponse() {
        this.success = false;
        this.structuredData = new Map<String, Object>();
        this.searchResults = new List<SearchResult>();
    }
    
    /**
     * @description Create a successful response
     * @param content The AI-generated content
     * @return AIResponse Success response
     */
    public static AIResponse createSuccess(String content) {
        AIResponse response = new AIResponse();
        response.success = true;
        response.content = content;
        return response;
    }
    
    /**
     * @description Create an error response
     * @param errorMessage The error message
     * @return AIResponse Error response
     */
    public static AIResponse createError(String errorMessage) {
        AIResponse response = new AIResponse();
        response.success = false;
        response.errorMessage = errorMessage;
        return response;
    }
    
    /**
     * @description Inner class for search results
     */
    public class SearchResult {
        public String title { get; set; }
        public String url { get; set; }
        public String snippet { get; set; }
        public Date publishedDate { get; set; }
        public String source { get; set; }
    }
}

