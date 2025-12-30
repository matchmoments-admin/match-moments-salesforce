/**
 * @description Interface for Article Generation Service
 * FFLib Service pattern for Article__c creation and management
 * @author Brendan Milton
 * @date 2025-12-30
 */
public interface IArticleGeneratorService {
    
    /**
     * @description Generate and create article for a match
     * @param matchId Match__c record ID
     * @param contentType Type of content (preview, recap, highlights)
     * @param uow Unit of Work for transaction management
     * @return Article__c record ID
     */
    Id generateMatchArticle(Id matchId, String contentType, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Generate and create article from custom topic
     * @param topic Article topic
     * @param context Contextual data map
     * @param relatedRecords Related record IDs
     * @param uow Unit of Work
     * @return Article__c record ID
     */
    Id generateCustomArticle(String topic, Map<String, Object> context, Map<String, Id> relatedRecords, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Batch generate articles for competition
     * @param competitionId Competition__c record ID
     * @param daysAhead Days ahead for upcoming matches
     * @param daysBehind Days behind for completed matches
     * @param uow Unit of Work
     * @return Map with generation statistics
     */
    Map<String, Integer> batchGenerateCompetitionArticles(Id competitionId, Integer daysAhead, Integer daysBehind, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Publish articles (set Is_Published__c = true)
     * @param articleIds Set of Article__c record IDs
     * @param uow Unit of Work
     */
    void publishArticles(Set<Id> articleIds, fflib_ISObjectUnitOfWork uow);
}

