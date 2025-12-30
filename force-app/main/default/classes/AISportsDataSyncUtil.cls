/**
 * @description Utility class for AI-powered sports data synchronization
 * Orchestrates data gathering from web sources and CRM updates
 * @author Brendan Milton
 * @date 2025-12-30
 * 
 * Key Methods:
 * - syncCompetitionData() - Get latest competition news
 * - syncMatchData() - Generate match previews/recaps
 * - syncTeamData() - Enrich team information
 * - syncPlayerData() - Update player stats/news
 * - generateArticle() - Create Article__c records
 */
public class AISportsDataSyncUtil {
    
    /**
     * @description Sync competition data - gather latest news and standings
     * @param competitionId Competition__c record ID
     * @return Number of articles created
     */
    public static Integer syncCompetitionData(Id competitionId) {
        Competition__c comp = [
            SELECT Id, Name, Sport__c, Status__c, ESPN_League_ID__c
            FROM Competition__c
            WHERE Id = :competitionId
            LIMIT 1
        ];
        
        IAIService aiService = AIServiceFactory.getInstance();
        
        // Search for competition news
        String dateRange = 'last 7 days';
        String prompt = AIPromptTemplates.getCompetitionNewsPrompt(comp.Name, dateRange);
        
        AIResponse response = aiService.generateFromPrompt(prompt, 1000);
        
        if (response.success) {
            // Create article record
            Article__c article = new Article__c(
                Heading__c = 'Latest News: ' + comp.Name,
                Body__c = response.content,
                Source__c = 'AI Generated - ' + response.provider,
                Sport_Type__c = comp.Sport__c,
                Article_Date__c = Date.today(),
                Is_Published__c = false
            );
            
            insert article;
            return 1;
        }
        
        return 0;
    }
    
    /**
     * @description Sync match data - generate preview or recap
     * @param matchId Match__c record ID
     * @param contentType 'preview' or 'recap'
     * @return Article__c record ID if created, null otherwise
     */
    public static Id syncMatchData(Id matchId, String contentType) {
        IAIService aiService = AIServiceFactory.getInstance();
        
        AIResponse response = aiService.generateMatchContent(matchId, contentType);
        
        if (response.success && String.isNotBlank(response.content)) {
            // Query match to get related data for article
            Match__c match = [
                SELECT Id, Name, Competition__r.Sport__c, Match_Date_Time__c,
                       Home_Team__r.Name, Away_Team__r.Name
                FROM Match__c
                WHERE Id = :matchId
                LIMIT 1
            ];
            
            // Extract headline from content (first line) or generate one
            String heading = extractHeading(response.content, match, contentType);
            
            Article__c article = new Article__c(
                Heading__c = heading,
                Body__c = response.content,
                Source__c = 'AI Generated - ' + response.provider,
                Sport_Type__c = match.Competition__r.Sport__c,
                Match__c = matchId,
                Article_Date__c = Date.today(),
                Is_Published__c = false,
                Reading_Time__c = calculateReadingTime(response.content)
            );
            
            insert article;
            return article.Id;
        }
        
        return null;
    }
    
    /**
     * @description Sync team data - enrich team information
     * @param teamId Account (Team) record ID
     * @return Success indicator
     */
    public static Boolean syncTeamData(Id teamId) {
        Account team = [
            SELECT Id, Name, Sport_Type__c, Description
            FROM Account
            WHERE Id = :teamId
            LIMIT 1
        ];
        
        IAIService aiService = AIServiceFactory.getInstance();
        
        // Generate team form analysis
        String prompt = AIPromptTemplates.getTeamFormPrompt(team.Name, 5);
        AIResponse response = aiService.generateFromPrompt(prompt, 500);
        
        if (response.success) {
            // Update team description with AI-generated summary
            team.Description = response.content + '\n\n(Last updated: ' + Datetime.now().format() + ')';
            update team;
            return true;
        }
        
        return false;
    }
    
    /**
     * @description Sync player data - update player summary
     * @param playerId Contact (Player) record ID
     * @return Success indicator
     */
    public static Boolean syncPlayerData(Id playerId) {
        Contact player = [
            SELECT Id, Name, Description, Department
            FROM Contact
            WHERE Id = :playerId
            LIMIT 1
        ];
        
        IAIService aiService = AIServiceFactory.getInstance();
        
        String prompt = AIPromptTemplates.getPlayerSummaryPrompt(player);
        AIResponse response = aiService.generateFromPrompt(prompt, 400);
        
        if (response.success) {
            player.Description = response.content + '\n\n(AI Summary - ' + Date.today().format() + ')';
            update player;
            return true;
        }
        
        return false;
    }
    
    /**
     * @description Generate article from custom topic and context
     * @param topic Article topic
     * @param context Map of contextual data
     * @param relatedRecords Map of related record IDs (Match__c, Team, Player, etc.)
     * @return Article__c record ID if created
     */
    public static Id generateArticle(String topic, Map<String, Object> context, Map<String, Id> relatedRecords) {
        IAIService aiService = AIServiceFactory.getInstance();
        
        String prompt = AIPromptTemplates.getArticleGenerationPrompt(topic, context);
        AIResponse response = aiService.generateArticle(topic, context);
        
        if (response.success && String.isNotBlank(response.content)) {
            // Extract heading from generated content
            String heading = extractHeadingFromContent(response.content);
            if (String.isBlank(heading)) {
                heading = topic;
            }
            
            Article__c article = new Article__c(
                Heading__c = heading.abbreviate(255),
                Body__c = response.content,
                Source__c = 'AI Generated - ' + response.provider,
                Article_Date__c = Date.today(),
                Is_Published__c = false,
                Reading_Time__c = calculateReadingTime(response.content)
            );
            
            // Set related records if provided
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
                if (relatedRecords.containsKey('Sport_Type__c')) {
                    article.Sport_Type__c = String.valueOf(context.get('sport'));
                }
            }
            
            insert article;
            return article.Id;
        }
        
        return null;
    }
    
    /**
     * @description Batch sync matches for a competition
     * @param competitionId Competition__c record ID
     * @param daysAhead Number of days ahead for upcoming matches
     * @param daysBehind Number of days behind for recent matches
     * @return Map with counts of previews and recaps created
     */
    public static Map<String, Integer> batchSyncMatchesForCompetition(Id competitionId, Integer daysAhead, Integer daysBehind) {
        Map<String, Integer> results = new Map<String, Integer>{
            'previews' => 0,
            'recaps' => 0,
            'errors' => 0
        };
        
        Date startDate = Date.today().addDays(-daysBehind);
        Date endDate = Date.today().addDays(daysAhead);
        
        // Query matches in date range
        List<Match__c> matches = [
            SELECT Id, Name, Status__c, Match_Date_Time__c,
                   Competition__r.Sport__c, Home_Team__r.Name, Away_Team__r.Name
            FROM Match__c
            WHERE Competition__c = :competitionId
            AND Match_Date_Time__c >= :startDate
            AND Match_Date_Time__c <= :endDate
            ORDER BY Match_Date_Time__c ASC
        ];
        
        // Check for existing articles to avoid duplicates
        Set<Id> matchIdsWithArticles = new Set<Id>();
        for (Article__c existingArticle : [SELECT Match__c FROM Article__c WHERE Match__c IN :matches]) {
            matchIdsWithArticles.add(existingArticle.Match__c);
        }
        
        for (Match__c match : matches) {
            // Skip if article already exists
            if (matchIdsWithArticles.contains(match.Id)) {
                continue;
            }
            
            try {
                if (match.Status__c == 'Completed' || match.Status__c == 'Final') {
                    // Generate recap for completed matches
                    Id articleId = syncMatchData(match.Id, 'recap');
                    if (articleId != null) {
                        results.put('recaps', results.get('recaps') + 1);
                    }
                } else if (match.Status__c == 'Scheduled') {
                    // Generate preview for upcoming matches
                    Id articleId = syncMatchData(match.Id, 'preview');
                    if (articleId != null) {
                        results.put('previews', results.get('previews') + 1);
                    }
                }
            } catch (Exception e) {
                System.debug('Error syncing match ' + match.Name + ': ' + e.getMessage());
                results.put('errors', results.get('errors') + 1);
            }
        }
        
        return results;
    }
    
    // =========================================================================
    // PRIVATE HELPER METHODS
    // =========================================================================
    
    /**
     * @description Extract heading from AI-generated content
     */
    private static String extractHeading(String content, Match__c match, String contentType) {
        // Try to find heading markers in content
        if (String.isNotBlank(content)) {
            List<String> lines = content.split('\n');
            if (!lines.isEmpty() && lines[0].length() < 150) {
                return lines[0].replaceAll('[#*]', '').trim();
            }
        }
        
        // Generate default heading
        String heading = '';
        if (contentType == 'preview') {
            heading = 'Match Preview: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name;
        } else if (contentType == 'recap') {
            heading = 'Match Recap: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name;
        }
        
        return heading.abbreviate(255);
    }
    
    /**
     * @description Extract heading from generated article content
     */
    private static String extractHeadingFromContent(String content) {
        if (String.isBlank(content)) {
            return null;
        }
        
        List<String> lines = content.split('\n');
        for (String line : lines) {
            line = line.trim();
            // Look for heading markers or first substantial line
            if (String.isNotBlank(line) && line.length() > 10 && line.length() < 200) {
                return line.replaceAll('[#*]', '').trim();
            }
        }
        
        return null;
    }
    
    /**
     * @description Calculate reading time in minutes based on word count
     */
    private static Integer calculateReadingTime(String content) {
        if (String.isBlank(content)) {
            return 1;
        }
        
        // Average reading speed: 200-250 words per minute
        Integer wordCount = content.split('\\s+').size();
        Integer readingTime = Math.max(1, (Integer) Math.ceil(wordCount / 225.0));
        
        return readingTime;
    }
    
    /**
     * @description Result wrapper class
     */
    public class SyncResult {
        public Boolean success { get; set; }
        public String message { get; set; }
        public Id recordId { get; set; }
        public Integer recordsProcessed { get; set; }
        
        public SyncResult() {
            this.success = false;
            this.recordsProcessed = 0;
        }
    }
}

