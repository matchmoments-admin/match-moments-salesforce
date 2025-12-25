/**
 * @description Service class for tracking and analyzing social engagement
 * Provides utility methods for engagement calculations and analytics
 * @author Brendan Milton
 * @date 2025-12
 */
public with sharing class EngagementTracker {
    
    /**
     * @description Track an engagement event
     * @param recordId The Match_Moment__c record Id
     * @param engagementType Type of engagement
     * @param platform Social platform
     * @param additionalData Optional additional data map
     */
    public static void trackEngagement(
        Id recordId,
        String engagementType,
        String platform,
        Map<String, Object> additionalData
    ) {
        try {
            Social_Engagement__c engagement = new Social_Engagement__c(
                Commentary_Event__c = recordId,
                Engagement_Type__c = engagementType,
                Platform__c = platform,
                Engagement_DateTime__c = System.now()
            );
            
            if (additionalData != null) {
                if (additionalData.containsKey('referrerUrl')) {
                    engagement.Referrer_URL__c = (String)additionalData.get('referrerUrl');
                }
                if (additionalData.containsKey('deviceType')) {
                    engagement.Device_Type__c = (String)additionalData.get('deviceType');
                }
                if (additionalData.containsKey('sessionId')) {
                    engagement.Session_ID__c = (String)additionalData.get('sessionId');
                }
                if (additionalData.containsKey('city')) {
                    engagement.City__c = (String)additionalData.get('city');
                }
                if (additionalData.containsKey('country')) {
                    engagement.Country__c = (String)additionalData.get('country');
                }
                if (additionalData.containsKey('campaignSource')) {
                    engagement.Campaign_Source__c = (String)additionalData.get('campaignSource');
                }
                if (additionalData.containsKey('campaignMedium')) {
                    engagement.Campaign_Medium__c = (String)additionalData.get('campaignMedium');
                }
                if (additionalData.containsKey('campaignName')) {
                    engagement.Campaign_Name__c = (String)additionalData.get('campaignName');
                }
            }
            
            engagement.User_Identifier__c = generateUserHash();
            
            insert engagement;
            
        } catch (Exception e) {
            System.debug('Error tracking engagement: ' + e.getMessage());
        }
    }
    
    /**
     * @description Calculate engagement value based on type and platform
     * @param engagementType The type of engagement
     * @param platform The social platform
     * @return Decimal calculated value
     */
    public static Decimal calculateEngagementValue(String engagementType, String platform) {
        Map<String, Decimal> typeValues = new Map<String, Decimal>{
            'View' => 0.01,
            'Share' => 0.50,
            'Like' => 0.10,
            'Comment' => 0.25,
            'Click' => 0.05,
            'Embed_View' => 0.15
        };
        
        Map<String, Decimal> platformMultipliers = new Map<String, Decimal>{
            'Twitter' => 1.2,
            'Facebook' => 1.0,
            'Instagram' => 1.3,
            'LinkedIn' => 1.5,
            'WhatsApp' => 0.8,
            'Website' => 1.0,
            'Mobile_App' => 1.1
        };
        
        Decimal baseValue = typeValues.get(engagementType) != null ? typeValues.get(engagementType) : 0.01;
        Decimal multiplier = platformMultipliers.get(platform) != null ? platformMultipliers.get(platform) : 1.0;
        
        return baseValue * multiplier;
    }
    
    /**
     * @description Get top moments by engagement within a date range
     * @param startDate Start of date range
     * @param endDate End of date range
     * @param limitCount Maximum number of results
     * @return List of AggregateResult with engagement data
     */
    public static List<AggregateResult> getTopMomentsByEngagement(
        Date startDate,
        Date endDate,
        Integer limitCount
    ) {
        return [
            SELECT Commentary_Event__c eventId,
                   COUNT(Id) totalEngagements
            FROM Social_Engagement__c
            WHERE Engagement_DateTime__c >= :startDate
            AND Engagement_DateTime__c <= :endDate
            GROUP BY Commentary_Event__c
            ORDER BY COUNT(Id) DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get engagement breakdown by platform
     * @param eventId The Match_Moment__c record Id
     * @return Map of platform to engagement count
     */
    public static Map<String, Integer> getEngagementByPlatform(Id eventId) {
        Map<String, Integer> result = new Map<String, Integer>();
        
        List<AggregateResult> aggregates = [
            SELECT Platform__c platform, COUNT(Id) cnt
            FROM Social_Engagement__c
            WHERE Commentary_Event__c = :eventId
            GROUP BY Platform__c
        ];
        
        for (AggregateResult ar : aggregates) {
            result.put((String)ar.get('platform'), (Integer)ar.get('cnt'));
        }
        
        return result;
    }
    
    /**
     * @description Get engagement breakdown by type
     * @param eventId The Match_Moment__c record Id
     * @return Map of engagement type to count
     */
    public static Map<String, Integer> getEngagementByType(Id eventId) {
        Map<String, Integer> result = new Map<String, Integer>();
        
        List<AggregateResult> aggregates = [
            SELECT Engagement_Type__c engType, COUNT(Id) cnt
            FROM Social_Engagement__c
            WHERE Commentary_Event__c = :eventId
            GROUP BY Engagement_Type__c
        ];
        
        for (AggregateResult ar : aggregates) {
            result.put((String)ar.get('engType'), (Integer)ar.get('cnt'));
        }
        
        return result;
    }
    
    /**
     * @description Detect viral moments based on recent engagement spike
     * @param minutesWindow Time window in minutes to check
     * @param threshold Minimum engagements to be considered viral
     * @return List of Match_Moment__c Ids that are trending
     */
    public static List<Id> detectViralMoments(Integer minutesWindow, Integer threshold) {
        DateTime cutoffTime = System.now().addMinutes(-minutesWindow);
        
        List<AggregateResult> aggregates = [
            SELECT Commentary_Event__c eventId, COUNT(Id) cnt
            FROM Social_Engagement__c
            WHERE Engagement_DateTime__c >= :cutoffTime
            GROUP BY Commentary_Event__c
            HAVING COUNT(Id) >= :threshold
            ORDER BY COUNT(Id) DESC
        ];
        
        List<Id> viralEventIds = new List<Id>();
        for (AggregateResult ar : aggregates) {
            viralEventIds.add((Id)ar.get('eventId'));
        }
        
        return viralEventIds;
    }
    
    /**
     * @description Get engagement trends over time
     * @param eventId The Match_Moment__c record Id
     * @param hoursBack Number of hours to look back
     * @return List of hourly engagement counts
     */
    public static List<Map<String, Object>> getEngagementTrends(Id eventId, Integer hoursBack) {
        List<Map<String, Object>> trends = new List<Map<String, Object>>();
        
        DateTime startTime = System.now().addHours(-hoursBack);
        
        // Get all engagements in the time period
        List<Social_Engagement__c> engagements = [
            SELECT Id, Engagement_DateTime__c
            FROM Social_Engagement__c
            WHERE Commentary_Event__c = :eventId
            AND Engagement_DateTime__c >= :startTime
            ORDER BY Engagement_DateTime__c ASC
        ];
        
        // Group by hour
        Map<Integer, Integer> hourlyCount = new Map<Integer, Integer>();
        for (Social_Engagement__c eng : engagements) {
            Integer hour = eng.Engagement_DateTime__c.hour();
            hourlyCount.put(hour, (hourlyCount.get(hour) != null ? hourlyCount.get(hour) : 0) + 1);
        }
        
        for (Integer hour : hourlyCount.keySet()) {
            trends.add(new Map<String, Object>{
                'hour' => hour,
                'count' => hourlyCount.get(hour)
            });
        }
        
        return trends;
    }
    
    // =========================================
    // Private Helper Methods
    // =========================================
    
    private static String generateUserHash() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = String.valueOf(System.now().getTime()) + String.valueOf(Math.random());
        }
        Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(sessionId));
        return EncodingUtil.convertToHex(hash).substring(0, 32);
    }
}

