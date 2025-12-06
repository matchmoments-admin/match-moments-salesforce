/**
 * @description Domain class for Social_Engagement__c
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class SocialEngagements extends fflib_SObjectDomain implements ISocialEngagements {
    
    public static final String TYPE_SHARE = 'Share';
    public static final String TYPE_VIEW = 'View';
    public static final String TYPE_CLICK = 'Click';
    
    public static final String PLATFORM_TWITTER = 'Twitter';
    public static final String PLATFORM_FACEBOOK = 'Facebook';
    public static final String PLATFORM_WHATSAPP = 'WhatsApp';
    public static final String PLATFORM_LINKEDIN = 'LinkedIn';
    
    public SocialEngagements(List<Social_Engagement__c> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new SocialEngagements((List<Social_Engagement__c>) records);
        }
    }
    
    public static ISocialEngagements newInstance(List<Social_Engagement__c> records) {
        return (ISocialEngagements) Application.Domain.newInstance(records);
    }
    
    public List<Social_Engagement__c> getEngagements() {
        return (List<Social_Engagement__c>) getRecords();
    }
    
    public void setEngagementType(String engagementType) {
        for (Social_Engagement__c engagement : getEngagements()) {
            engagement.Engagement_Type__c = engagementType;
        }
    }
    
    public void setPlatform(String platform) {
        for (Social_Engagement__c engagement : getEngagements()) {
            engagement.Platform__c = platform;
        }
    }
}

