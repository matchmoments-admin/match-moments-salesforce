/**
 * @description Implementation of Social Sharing Service
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class SocialSharingServiceImpl implements ISocialSharingService {
    
    public static ISocialSharingService newInstance() {
        return (ISocialSharingService) Application.Service.newInstance(ISocialSharingService.class);
    }
    
    public void recordShare(Id commentaryEventId, String platform, fflib_ISObjectUnitOfWork uow) {
        Social_Engagement__c engagement = new Social_Engagement__c(
            Commentary_Event__c = commentaryEventId,
            Platform__c = platform,
            Engagement_Type__c = SocialEngagements.TYPE_SHARE
        );
        uow.registerNew(engagement);
    }
    
    public void recordView(Id commentaryEventId, fflib_ISObjectUnitOfWork uow) {
        Social_Engagement__c engagement = new Social_Engagement__c(
            Commentary_Event__c = commentaryEventId,
            Engagement_Type__c = SocialEngagements.TYPE_VIEW
        );
        uow.registerNew(engagement);
    }
    
    public void updateShareCounts(Set<Id> commentaryEventIds, fflib_ISObjectUnitOfWork uow) {
        List<Match_Moment__c> events = MatchMomentsSelector.newInstance().selectById(commentaryEventIds);
        IMatchMoments domain = MatchMoments.newInstance(events);
        domain.incrementShareCount();
        
        for (Match_Moment__c event : events) {
            uow.registerDirty(event);
        }
    }
}

