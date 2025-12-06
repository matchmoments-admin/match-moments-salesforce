/**
 * @description Domain class for Competition__c business logic
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class Competitions extends fflib_SObjectDomain implements ICompetitions {
    
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_UPCOMING = 'Upcoming';
    
    public static final Set<String> VALID_SPORTS = new Set<String>{
        'Soccer', 'Cricket', 'AFL', 'Rugby', 'Basketball', 'Tennis', 'Padel', 'Olympic'
    };
    
    public Competitions(List<Competition__c> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Competitions((List<Competition__c>) records);
        }
    }
    
    public static ICompetitions newInstance(List<Competition__c> records) {
        return (ICompetitions) Application.Domain.newInstance(records);
    }
    
    public List<Competition__c> getCompetitions() {
        return (List<Competition__c>) getRecords();
    }
    
    public override void onValidate() {
        for (Competition__c comp : getCompetitions()) {
            if (String.isBlank(comp.Sport__c)) {
                comp.addError('Sport is required');
            }
        }
    }
    
    public void validateSport() {
        for (Competition__c comp : getCompetitions()) {
            if (String.isNotBlank(comp.Sport__c) && !VALID_SPORTS.contains(comp.Sport__c)) {
                comp.addError('Invalid Sport. Must be one of: ' + String.join(new List<String>(VALID_SPORTS), ', '));
            }
        }
    }
    
    public void setSeasonDates(Date startDate, Date endDate) {
        for (Competition__c comp : getCompetitions()) {
            comp.Season_Start_Date__c = startDate;
            comp.Season_End_Date__c = endDate;
        }
    }
    
    public void markAsActive() {
        for (Competition__c comp : getCompetitions()) {
            comp.Status__c = STATUS_ACTIVE;
        }
    }
    
    public void markAsCompleted() {
        for (Competition__c comp : getCompetitions()) {
            comp.Status__c = STATUS_COMPLETED;
        }
    }
}

