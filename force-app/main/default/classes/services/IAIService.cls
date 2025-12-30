/**
 * @description Interface for AI service implementations
 * Enables switching between different AI providers (Gemini, OpenAI, Anthropic)
 * Follows FFLib Service pattern for dependency injection
 * @author Brendan Milton
 * @date 2025-12-30
 */
public interface IAIService {
    
    /**
     * @description Search sports websites for data (scores, standings, news)
     * Uses AI provider's web search capability (Gemini grounding with Google Search)
     * @param query The search query
     * @param sport Sport type (Soccer, Basketball, Cricket, etc.)
     * @param searchDate Date to focus search on (for fixtures/results)
     * @return AIResponse with search results and extracted data
     */
    AIResponse searchSportsData(String query, String sport, Date searchDate);
    
    /**
     * @description Generate article content from topic and context
     * Can be used for match previews, recaps, blog posts, news articles
     * @param topic Article topic/title
     * @param context Map of contextual data (teams, scores, players, etc.)
     * @return AIResponse with generated article content
     */
    AIResponse generateArticle(String topic, Map<String, Object> context);
    
    /**
     * @description Summarize a Salesforce record (Account, Contact, Match__c, etc.)
     * Uses AI to create concise, human-readable summaries
     * @param recordId Salesforce record ID
     * @param objectType SObjectType of the record
     * @return AIResponse with summary text
     */
    AIResponse summarizeRecord(Id recordId, SObjectType objectType);
    
    /**
     * @description Generate match-specific content (preview, recap, highlights)
     * @param matchId Match__c record ID
     * @param contentType Type of content ("preview", "recap", "highlights", "tweet")
     * @return AIResponse with generated content
     */
    AIResponse generateMatchContent(Id matchId, String contentType);
    
    /**
     * @description Generate content from a custom prompt
     * Allows maximum flexibility for various use cases
     * @param prompt The AI prompt
     * @param maxTokens Optional token limit (uses provider default if null)
     * @return AIResponse with generated content
     */
    AIResponse generateFromPrompt(String prompt, Integer maxTokens);
    
    /**
     * @description Extract structured data from unstructured text
     * Useful for parsing web pages, PDFs, or other content
     * @param text The unstructured text
     * @param schema Expected data schema (field names and types)
     * @return AIResponse with structured data in structuredData map
     */
    AIResponse extractStructuredData(String text, Map<String, String> schema);
}

