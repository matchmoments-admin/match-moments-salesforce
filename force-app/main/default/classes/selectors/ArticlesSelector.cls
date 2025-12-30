/**
 * @description Selector class for Article__c queries
 * Implements FFLib Selector pattern with FLS enforcement
 * @author Brendan Milton
 * @date 2025-12-30
 */
public inherited sharing class ArticlesSelector extends fflib_SObjectSelector implements IArticlesSelector {
    
    /**
     * @description Factory method to get selector instance
     * @return IArticlesSelector
     */
    public static IArticlesSelector newInstance() {
        return (IArticlesSelector) Application.Selector.newInstance(Article__c.SObjectType);
    }
    
    /**
     * @description Get SObjectType
     * @return SObjectType
     */
    public Schema.SObjectType getSObjectType() {
        return Article__c.SObjectType;
    }
    
    /**
     * @description Get default fields for queries
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Article__c.Id,
            Article__c.Name,
            Article__c.Heading__c,
            Article__c.Body__c,
            Article__c.Source__c,
            Article__c.Sport_Type__c,
            Article__c.Article_Date__c,
            Article__c.Is_Published__c,
            Article__c.Reading_Time__c,
            Article__c.Article_URL__c,
            Article__c.Header_Image_URL__c,
            Article__c.Match__c,
            Article__c.Related_Team__c,
            Article__c.Related_Player__c,
            Article__c.CreatedDate,
            Article__c.CreatedById,
            Article__c.LastModifiedDate
        };
    }
    
    /**
     * @description Select articles by IDs
     * @param articleIds Set of Article__c record IDs
     * @return List of Article__c records
     */
    public List<Article__c> selectById(Set<Id> articleIds) {
        return (List<Article__c>) selectSObjectsById(articleIds);
    }
    
    /**
     * @description Select articles by related match IDs
     * @param matchIds Set of Match__c record IDs
     * @return List of Article__c records
     */
    public List<Article__c> selectByMatchId(Set<Id> matchIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Match__r.Name')
            .selectField('Match__r.Home_Team__r.Name')
            .selectField('Match__r.Away_Team__r.Name')
            .selectField('Match__r.Match_Date_Time__c')
            .setCondition('Match__c IN :matchIds')
            .setOrdering('Article_Date__c', fflib_QueryFactory.SortOrder.DESCENDING);
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select recent articles by sport type
     * @param sport Sport type
     * @param days Number of days to look back
     * @return List of Article__c records
     */
    public List<Article__c> selectRecentBySport(String sport, Integer days) {
        Date cutoffDate = Date.today().addDays(-days);
        
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Sport_Type__c = :sport AND Article_Date__c >= :cutoffDate')
            .setOrdering('Article_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
            .setLimit(100);
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select articles by source
     * @param source Article source filter
     * @return List of Article__c records
     */
    public List<Article__c> selectBySource(String source) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Source__c LIKE :source')
            .setOrdering('Article_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
            .setLimit(200);
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select published articles
     * @param limitCount Maximum records to return
     * @return List of Article__c records
     */
    public List<Article__c> selectPublished(Integer limitCount) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Is_Published__c = true')
            .setOrdering('Article_Date__c', fflib_QueryFactory.SortOrder.DESCENDING);
        
        if (limitCount != null && limitCount > 0) {
            query.setLimit(limitCount);
        } else {
            query.setLimit(100);
        }
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select articles by sport and date range
     * @param sport Sport type
     * @param startDate Start date
     * @param endDate End date
     * @return List of Article__c records
     */
    public List<Article__c> selectBySportAndDateRange(String sport, Date startDate, Date endDate) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Sport_Type__c = :sport AND Article_Date__c >= :startDate AND Article_Date__c <= :endDate')
            .setOrdering('Article_Date__c', fflib_QueryFactory.SortOrder.DESCENDING);
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
    
    /**
     * @description Select unpublished articles (drafts)
     * @return List of Article__c records
     */
    public List<Article__c> selectDrafts() {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Is_Published__c = false')
            .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
            .setLimit(100);
        
        return (List<Article__c>) Database.query(query.toSOQL());
    }
}

