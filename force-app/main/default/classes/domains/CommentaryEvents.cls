/**
 * @description Domain class for Commentary_Event__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class CommentaryEvents extends fflib_SObjectDomain implements ICommentaryEvents {
    
    public CommentaryEvents(List<Commentary_Event__c> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new CommentaryEvents((List<Commentary_Event__c>) records);
        }
    }
    
    public static ICommentaryEvents newInstance(List<Commentary_Event__c> records) {
        return (ICommentaryEvents) Application.Domain.newInstance(records);
    }
    
    public List<Commentary_Event__c> getEvents() {
        return (List<Commentary_Event__c>) getRecords();
    }
    
    public void makeShareable() {
        for (Commentary_Event__c event : getEvents()) {
            event.Is_Shareable__c = true;
        }
    }
    
    public void updateViralScore(Decimal score) {
        for (Commentary_Event__c event : getEvents()) {
            event.Viral_Score__c = score;
        }
    }
    
    public void incrementShareCount() {
        for (Commentary_Event__c event : getEvents()) {
            event.Share_Count__c = (event.Share_Count__c != null ? event.Share_Count__c : 0) + 1;
        }
    }
    
    public void incrementViewCount() {
        for (Commentary_Event__c event : getEvents()) {
            event.View_Count__c = (event.View_Count__c != null ? event.View_Count__c : 0) + 1;
        }
    }
}

