/**
 * @description Implementation of Engagement Service
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class EngagementServiceImpl implements IEngagementService {
    
    private static final Decimal VIRAL_THRESHOLD = 100;
    
    public static IEngagementService newInstance() {
        return (IEngagementService) Application.Service.newInstance(IEngagementService.class);
    }
    
    public Map<String, Integer> getEngagementCounts(Id commentaryEventId) {
        List<Match_Moment__c> events = MatchMomentsSelector.newInstance().selectById(new Set<Id>{ commentaryEventId });
        
        Map<String, Integer> counts = new Map<String, Integer>{
            'shares' => 0,
            'views' => 0,
            'total' => 0
        };
        
        if (!events.isEmpty()) {
            Match_Moment__c event = events[0];
            counts.put('shares', event.Share_Count__c != null ? Integer.valueOf(event.Share_Count__c) : 0);
            counts.put('views', event.View_Count__c != null ? Integer.valueOf(event.View_Count__c) : 0);
            counts.put('total', counts.get('shares') + counts.get('views'));
        }
        
        return counts;
    }
    
    public Boolean isViral(Id commentaryEventId) {
        List<Match_Moment__c> events = MatchMomentsSelector.newInstance().selectById(new Set<Id>{ commentaryEventId });
        
        if (!events.isEmpty()) {
            Match_Moment__c event = events[0];
            return event.Viral_Score__c != null && event.Viral_Score__c >= VIRAL_THRESHOLD;
        }
        
        return false;
    }
    
    public void calculateViralScores(Set<Id> commentaryEventIds, fflib_ISObjectUnitOfWork uow) {
        List<Match_Moment__c> events = MatchMomentsSelector.newInstance().selectById(commentaryEventIds);
        
        for (Match_Moment__c event : events) {
            Decimal shares = event.Share_Count__c != null ? event.Share_Count__c : 0;
            Decimal views = event.View_Count__c != null ? event.View_Count__c : 0;
            
            // Simple viral score: shares * 10 + views
            Decimal viralScore = (shares * 10) + views;
            event.Viral_Score__c = viralScore;
            
            uow.registerDirty(event);
        }
    }
}

