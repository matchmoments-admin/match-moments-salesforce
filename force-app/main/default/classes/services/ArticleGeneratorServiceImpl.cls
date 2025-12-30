/**
 * @description Article Generator Service Implementation
 * FFLib Service for creating Article__c records from AI-generated content
 * @author Brendan Milton
 * @date 2025-12-30
 */
public inherited sharing class ArticleGeneratorServiceImpl implements IArticleGeneratorService {
    
    /**
     * @description Factory method to get service instance
     * @return IArticleGeneratorService
     */
    public static IArticleGeneratorService newInstance() {
        return (IArticleGeneratorService) Application.Service.newInstance(IArticleGeneratorService.class);
    }
    
    /**
     * @description Generate and create article for a match
     * @param matchId Match__c record ID
     * @param contentType Type of content
     * @param uow Unit of Work
     * @return Article__c record ID
     */
    public Id generateMatchArticle(Id matchId, String contentType, fflib_ISObjectUnitOfWork uow) {
        // Get AI service
        IAIService aiService = AIServiceFactory.getInstance();
        
        // Generate content
        AIResponse response = aiService.generateMatchContent(matchId, contentType);
        
        if (response.success && String.isNotBlank(response.content)) {
            // Query match for article metadata
            Match__c match = [
                SELECT Id, Name, Competition__r.Sport__c, Match_Date_Time__c,
                       Home_Team__r.Name, Away_Team__r.Name, Home_Score_Final__c, Away_Score_Final__c
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            // Create article
            Article__c article = buildMatchArticle(match, response, contentType);
            
            // Register with UOW
            uow.registerNew(article);
            
            // Return temporary ID (will be assigned after uow.commitWork())
            return article.Id;
        }
        
        return null;
    }
    
    /**
     * @description Generate custom article
     * @param topic Article topic
     * @param context Context data
     * @param relatedRecords Related record IDs
     * @param uow Unit of Work
     * @return Article__c record ID
     */
    public Id generateCustomArticle(String topic, Map<String, Object> context, Map<String, Id> relatedRecords, fflib_ISObjectUnitOfWork uow) {
        // Get AI service
        IAIService aiService = AIServiceFactory.getInstance();
        
        // Generate content
        AIResponse response = aiService.generateArticle(topic, context);
        
        if (response.success && String.isNotBlank(response.content)) {
            // Create article
            Article__c article = buildCustomArticle(topic, response, context, relatedRecords);
            
            // Register with UOW
            uow.registerNew(article);
            
            return article.Id;
        }
        
        return null;
    }
    
    /**
     * @description Batch generate articles for a competition
     * @param competitionId Competition__c record ID
     * @param daysAhead Days ahead
     * @param daysBehind Days behind
     * @param uow Unit of Work
     * @return Statistics map
     */
    public Map<String, Integer> batchGenerateCompetitionArticles(Id competitionId, Integer daysAhead, Integer daysBehind, fflib_ISObjectUnitOfWork uow) {
        Map<String, Integer> stats = new Map<String, Integer>{
            'previews' => 0,
            'recaps' => 0,
            'errors' => 0
        };
        
        Date startDate = Date.today().addDays(-daysBehind);
        Date endDate = Date.today().addDays(daysAhead);
        
        // Query matches
        List<Match__c> matches = [
            SELECT Id, Name, Status__c, Match_Date_Time__c,
                   Competition__r.Sport__c, Home_Team__r.Name, Away_Team__r.Name,
                   Home_Score_Final__c, Away_Score_Final__c
            FROM Match__c
            WHERE Competition__c = :competitionId
            AND Match_Date_Time__c >= :startDate
            AND Match_Date_Time__c <= :endDate
            ORDER BY Match_Date_Time__c ASC
            LIMIT 100
        ];
        
        // Get existing articles to avoid duplicates
        Set<Id> matchesWithArticles = getMatchIdsWithArticles(matches);
        
        IAIService aiService = AIServiceFactory.getInstance();
        
        for (Match__c match : matches) {
            // Skip if article exists
            if (matchesWithArticles.contains(match.Id)) {
                continue;
            }
            
            try {
                String contentType = determineContentType(match);
                if (String.isNotBlank(contentType)) {
                    AIResponse response = aiService.generateMatchContent(match.Id, contentType);
                    
                    if (response.success && String.isNotBlank(response.content)) {
                        Article__c article = buildMatchArticle(match, response, contentType);
                        uow.registerNew(article);
                        
                        if (contentType == 'preview') {
                            stats.put('previews', stats.get('previews') + 1);
                        } else {
                            stats.put('recaps', stats.get('recaps') + 1);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error generating article for match ' + match.Name + ': ' + e.getMessage());
                stats.put('errors', stats.get('errors') + 1);
            }
        }
        
        return stats;
    }
    
    /**
     * @description Publish articles
     * @param articleIds Article IDs to publish
     * @param uow Unit of Work
     */
    public void publishArticles(Set<Id> articleIds, fflib_ISObjectUnitOfWork uow) {
        List<Article__c> articles = [
            SELECT Id, Is_Published__c
            FROM Article__c
            WHERE Id IN :articleIds
        ];
        
        for (Article__c article : articles) {
            article.Is_Published__c = true;
            uow.registerDirty(article);
        }
    }
    
    // =========================================================================
    // PRIVATE HELPER METHODS
    // =========================================================================
    
    /**
     * @description Build article record for match content
     */
    private Article__c buildMatchArticle(Match__c match, AIResponse response, String contentType) {
        String heading = extractOrGenerateHeading(response.content, match, contentType);
        
        Article__c article = new Article__c(
            Heading__c = heading,
            Body__c = response.content,
            Source__c = 'AI: ' + response.provider + ' (' + response.model + ')',
            Sport_Type__c = match.Competition__r.Sport__c,
            Match__c = match.Id,
            Article_Date__c = Date.today(),
            Is_Published__c = false,
            Reading_Time__c = calculateReadingTime(response.content)
        );
        
        return article;
    }
    
    /**
     * @description Build article for custom content
     */
    private Article__c buildCustomArticle(String topic, AIResponse response, Map<String, Object> context, Map<String, Id> relatedRecords) {
        String heading = extractHeadingFromContent(response.content);
        if (String.isBlank(heading)) {
            heading = topic;
        }
        
        Article__c article = new Article__c(
            Heading__c = heading.abbreviate(255),
            Body__c = response.content,
            Source__c = 'AI: ' + response.provider + ' (' + response.model + ')',
            Article_Date__c = Date.today(),
            Is_Published__c = false,
            Reading_Time__c = calculateReadingTime(response.content)
        );
        
        // Set related records
        if (relatedRecords != null) {
            if (relatedRecords.containsKey('Match__c')) {
                article.Match__c = relatedRecords.get('Match__c');
            }
            if (relatedRecords.containsKey('Account')) {
                article.Related_Team__c = relatedRecords.get('Account');
            }
            if (relatedRecords.containsKey('Contact')) {
                article.Related_Player__c = relatedRecords.get('Contact');
            }
        }
        
        // Set sport type from context
        if (context != null && context.containsKey('sport')) {
            article.Sport_Type__c = String.valueOf(context.get('sport'));
        }
        
        return article;
    }
    
    /**
     * @description Determine content type based on match status
     */
    private String determineContentType(Match__c match) {
        if (match.Status__c == 'Completed' || match.Status__c == 'Final') {
            return 'recap';
        } else if (match.Status__c == 'Scheduled') {
            return 'preview';
        }
        return null;
    }
    
    /**
     * @description Get match IDs that already have articles
     */
    private Set<Id> getMatchIdsWithArticles(List<Match__c> matches) {
        Set<Id> matchesWithArticles = new Set<Id>();
        
        List<Article__c> existingArticles = [
            SELECT Match__c
            FROM Article__c
            WHERE Match__c IN :matches
        ];
        
        for (Article__c article : existingArticles) {
            matchesWithArticles.add(article.Match__c);
        }
        
        return matchesWithArticles;
    }
    
    /**
     * @description Extract or generate heading
     */
    private String extractOrGenerateHeading(String content, Match__c match, String contentType) {
        String heading = extractHeadingFromContent(content);
        
        if (String.isBlank(heading)) {
            // Generate default heading
            if (contentType == 'preview') {
                heading = 'Preview: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name;
            } else {
                heading = 'Recap: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name;
            }
        }
        
        return heading.abbreviate(255);
    }
    
    /**
     * @description Extract heading from content
     */
    private String extractHeadingFromContent(String content) {
        if (String.isBlank(content)) {
            return null;
        }
        
        List<String> lines = content.split('\n');
        for (String line : lines) {
            line = line.trim().replaceAll('[#*]', '').trim();
            if (String.isNotBlank(line) && line.length() > 10 && line.length() < 200) {
                return line;
            }
        }
        
        return null;
    }
    
    /**
     * @description Calculate reading time
     */
    private Integer calculateReadingTime(String content) {
        if (String.isBlank(content)) {
            return 1;
        }
        
        Integer wordCount = content.split('\\s+').size();
        return Math.max(1, (Integer) Math.ceil(wordCount / 225.0));
    }
}

