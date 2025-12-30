/**
 * @description Interface for Articles Selector
 * FFLib Selector pattern for Article__c queries
 * @author Brendan Milton
 * @date 2025-12-30
 */
public interface IArticlesSelector extends fflib_ISObjectSelector {
    
    /**
     * @description Select articles by IDs
     * @param articleIds Set of Article__c record IDs
     * @return List of Article__c records
     */
    List<Article__c> selectById(Set<Id> articleIds);
    
    /**
     * @description Select articles by related match IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Article__c records
     */
    List<Article__c> selectByMatchId(Set<Id> matchIds);
    
    /**
     * @description Select recent articles by sport type
     * @param sport Sport type
     * @param days Number of days to look back
     * @return List of Article__c records
     */
    List<Article__c> selectRecentBySport(String sport, Integer days);
    
    /**
     * @description Select articles by source
     * @param source Article source (e.g., 'AI Generated')
     * @return List of Article__c records
     */
    List<Article__c> selectBySource(String source);
    
    /**
     * @description Select published articles
     * @param limitCount Maximum records to return
     * @return List of Article__c records
     */
    List<Article__c> selectPublished(Integer limitCount);
}

