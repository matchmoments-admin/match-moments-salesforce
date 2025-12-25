/**
 * @description Rate limiter for API quota management
 * @author Match Moments
 */
public with sharing class RateLimiter {
    
    /**
     * @description Check if user has remaining quota
     * @param userIdentifier JWT subject or IP
     * @param endpoint API endpoint path
     * @return Boolean true if quota available
     */
    public static Boolean checkQuota(String userIdentifier, String endpoint) {
        try {
            List<API_Usage__c> usageList = [
                SELECT Id, Requests_Today__c, Quota_Limit__c, Reset_Date__c, Is_Blocked__c
                FROM API_Usage__c
                WHERE User_Identifier__c = :userIdentifier
                AND Endpoint__c = :endpoint
                LIMIT 1
            ];
            
            API_Usage__c usage;
            if (usageList.isEmpty()) {
                usage = new API_Usage__c(
                    User_Identifier__c = userIdentifier,
                    Endpoint__c = endpoint,
                    Quota_Limit__c = 1000,
                    Reset_Date__c = Date.today(),
                    Requests_Today__c = 0
                );
            } else {
                usage = usageList[0];
            }
            
            // Reset if new day
            if (usage.Reset_Date__c < Date.today()) {
                usage.Requests_Today__c = 0;
                usage.Reset_Date__c = Date.today();
            }
            
            // Check blocks
            if (usage.Is_Blocked__c == true) {
                return false;
            }
            
            // Check quota
            if (usage.Requests_Today__c >= usage.Quota_Limit__c) {
                return false;
            }
            
            // Increment
            usage.Requests_Today__c = (usage.Requests_Today__c == null ? 0 : usage.Requests_Today__c) + 1;
            usage.Last_Request__c = System.now();
            
            upsert usage User_Identifier__c;
            return true;
            
        } catch (Exception e) {
            System.debug('RateLimiter error: ' + e.getMessage());
            return false; // Fail closed for security
        }
    }
    
    /**
     * @description Reset daily quotas (scheduled daily at midnight)
     */
    public static void resetDailyQuotas() {
        List<API_Usage__c> allUsage = [
            SELECT Id, Requests_Today__c, Reset_Date__c
            FROM API_Usage__c
            WHERE Reset_Date__c < TODAY
            LIMIT 10000
        ];
        
        for (API_Usage__c usage : allUsage) {
            usage.Requests_Today__c = 0;
            usage.Reset_Date__c = Date.today();
        }
        
        if (!allUsage.isEmpty()) {
            update allUsage;
        }
        
        System.debug('Reset ' + allUsage.size() + ' API usage records');
    }
}

