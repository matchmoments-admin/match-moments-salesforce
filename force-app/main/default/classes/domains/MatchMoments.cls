/**
 * @description Domain class for Match_Moment__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class MatchMoments extends fflib_SObjectDomain implements IMatchMoments {
    
    public MatchMoments(List<Match_Moment__c> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new MatchMoments((List<Match_Moment__c>) records);
        }
    }
    
    public static IMatchMoments newInstance(List<Match_Moment__c> records) {
        return (IMatchMoments) Application.Domain.newInstance(records);
    }
    
    public List<Match_Moment__c> getEvents() {
        return (List<Match_Moment__c>) getRecords();
    }
    
    public void makeShareable() {
        for (Match_Moment__c event : getEvents()) {
            event.Is_Shareable__c = true;
        }
    }
    
    public void updateViralScore(Decimal score) {
        for (Match_Moment__c event : getEvents()) {
            event.Viral_Score__c = score;
        }
    }
    
    public void incrementShareCount() {
        for (Match_Moment__c event : getEvents()) {
            event.Share_Count__c = (event.Share_Count__c != null ? event.Share_Count__c : 0) + 1;
        }
    }
    
    public void incrementViewCount() {
        for (Match_Moment__c event : getEvents()) {
            event.View_Count__c = (event.View_Count__c != null ? event.View_Count__c : 0) + 1;
        }
    }
}

