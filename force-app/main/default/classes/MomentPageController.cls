/**
 * @description Controller for public moment pages and social sharing
 * Provides methods to get event details and track engagement
 * @author Brendan Milton
 * @date 2025-12
 */
public without sharing class MomentPageController {
    
    /**
     * @description Get detailed information about a commentary event for display
     * @param eventId The Commentary_Event__c record Id
     * @return Map containing event, fixture, period, and related moments data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEventDetails(Id eventId) {
        try {
            Commentary_Event__c event = [
                SELECT Id, Name, Event_Type__c, Event_Minute__c, Event_Second__c,
                       Description__c, Event_Importance__c, Video_URL__c,
                       Primary_Player__c, Primary_Player__r.Name, 
                       Primary_Player__r.Position__c, Primary_Player__r.Profile_Image_URL__c,
                       Team__c, Team__r.Name, Team__r.Logo_Url__c,
                       Fixture__c, Fixture__r.Name,
                       Fixture__r.Home_Team__r.Name, Fixture__r.Home_Team__r.Logo_Url__c,
                       Fixture__r.Away_Team__r.Name, Fixture__r.Away_Team__r.Logo_Url__c,
                       Fixture__r.Home_Score_Final__c, Fixture__r.Away_Score_Final__c,
                       Fixture__r.Status__c, Fixture__r.Venue__c,
                       Fixture__r.Fixture_Date_Time__c,
                       Fixture__r.Competition__r.Name, Fixture__r.Competition__r.Sport__c,
                       Fixture_Period__c, Fixture_Period__r.Period_Number__c,
                       Fixture_Period__r.Period_Type__c,
                       Fixture_Period__r.Home_Score_Period__c,
                       Fixture_Period__r.Away_Score_Period__c,
                       Fixture_Period__r.Home_Score_Cumulative__c,
                       Fixture_Period__r.Away_Score_Cumulative__c,
                       Public_URL__c, Social_Share_Title__c, 
                       Social_Share_Description__c, Social_Media_Image_URL__c,
                       QR_Code_URL__c, Embed_Code__c,
                       Total_Shares__c, Total_Views__c, Viral_Score__c
                FROM Commentary_Event__c
                WHERE Id = :eventId
                LIMIT 1
            ];
            
            // Get related moments from same fixture
            List<Commentary_Event__c> relatedMoments = [
                SELECT Id, Event_Type__c, Event_Minute__c, Description__c,
                       Video_URL__c, Social_Share_Title__c, Primary_Player__r.Name
                FROM Commentary_Event__c
                WHERE Fixture__c = :event.Fixture__c
                AND Id != :eventId
                AND Event_Importance__c IN ('Critical', 'Major')
                ORDER BY Event_Minute__c ASC
                LIMIT 6
            ];
            
            // Get all events for timeline
            List<Commentary_Event__c> allEvents = [
                SELECT Id, Event_Type__c, Event_Minute__c, Description__c
                FROM Commentary_Event__c
                WHERE Fixture__c = :event.Fixture__c
                ORDER BY Event_Minute__c ASC
            ];
            
            Map<String, Object> result = new Map<String, Object>{
                'event' => formatEvent(event),
                'fixture' => formatFixture(event),
                'period' => formatPeriod(event.Fixture_Period__r),
                'relatedMoments' => formatMoments(relatedMoments),
                'allEvents' => formatTimelineEvents(allEvents, eventId)
            };
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading moment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Track user engagement (view, share, click, etc.)
     * @param eventId The Commentary_Event__c record Id
     * @param engagementType Type of engagement (View, Share, Like, Click, Embed_View)
     * @param platform Platform where engagement occurred
     * @param referrerUrl Where the user came from
     */
    @AuraEnabled
    public static void trackEngagement(
        Id eventId,
        String engagementType,
        String platform,
        String referrerUrl
    ) {
        try {
            Social_Engagement__c engagement = new Social_Engagement__c(
                Commentary_Event__c = eventId,
                Engagement_Type__c = engagementType,
                Platform__c = platform,
                Referrer_URL__c = referrerUrl,
                Engagement_DateTime__c = System.now(),
                Device_Type__c = 'Unknown',
                User_Identifier__c = generateUserHash()
            );
            
            insert engagement;
            
            // Update counts on Commentary_Event__c
            updateEngagementCounts(eventId, engagementType, platform);
            
        } catch (Exception e) {
            System.debug('Error tracking engagement: ' + e.getMessage());
            // Don't throw - tracking failures shouldn't break the user experience
        }
    }
    
    /**
     * @description Get viral moments based on viral score threshold
     * @param threshold Minimum viral score
     * @return List of viral moment data maps
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getViralMoments(Integer threshold) {
        List<Commentary_Event__c> moments = [
            SELECT Id, Social_Share_Title__c, Total_Shares__c, 
                   Total_Views__c, Viral_Score__c, Twitter_Shares__c,
                   Facebook_Shares__c, Event_Type__c,
                   Fixture__r.Name, CreatedDate
            FROM Commentary_Event__c
            WHERE Viral_Score__c >= :threshold
            ORDER BY Viral_Score__c DESC
            LIMIT 50
        ];
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        for (Commentary_Event__c moment : moments) {
            result.add(new Map<String, Object>{
                'id' => moment.Id,
                'title' => moment.Social_Share_Title__c,
                'totalShares' => moment.Total_Shares__c,
                'totalViews' => moment.Total_Views__c,
                'viralScore' => moment.Viral_Score__c,
                'twitterShares' => moment.Twitter_Shares__c,
                'facebookShares' => moment.Facebook_Shares__c,
                'icon' => getEventIcon(moment.Event_Type__c),
                'matchName' => moment.Fixture__r.Name,
                'timeAgo' => getTimeAgo(moment.CreatedDate)
            });
        }
        
        return result;
    }
    
    // =========================================
    // Private Helper Methods
    // =========================================
    
    private static Map<String, Object> formatEvent(Commentary_Event__c event) {
        String publicUrl = 'https://yoursportscrm.force.com/fans/moment/' + event.Id;
        String qrCodeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=' + EncodingUtil.urlEncode(publicUrl, 'UTF-8');
        String embedCode = '<iframe src="https://yoursportscrm.force.com/fans/embed/moment/' + event.Id + '" width="600" height="400" frameborder="0"></iframe>';
        
        // Build social share title
        String socialTitle = buildSocialTitle(event);
        String socialDescription = event.Event_Minute__c + '\' - ' + event.Description__c;
        
        return new Map<String, Object>{
            'id' => event.Id,
            'name' => event.Name,
            'title' => socialTitle,
            'eventType' => event.Event_Type__c,
            'minute' => event.Event_Minute__c,
            'second' => event.Event_Second__c,
            'description' => event.Description__c,
            'importance' => event.Event_Importance__c,
            'videoUrl' => event.Video_URL__c,
            'playerName' => event.Primary_Player__r?.Name,
            'playerPosition' => event.Primary_Player__r?.Position__c,
            'playerPhoto' => event.Primary_Player__r?.Profile_Image_URL__c,
            'teamName' => event.Team__r?.Name,
            'teamLogo' => event.Team__r?.Logo_Url__c,
            'publicUrl' => publicUrl,
            'socialShareTitle' => socialTitle,
            'socialShareDescription' => socialDescription,
            'socialMediaImageUrl' => getSocialImage(event),
            'qrCodeUrl' => qrCodeUrl,
            'embedCode' => embedCode,
            'totalShares' => event.Total_Shares__c != null ? event.Total_Shares__c : 0,
            'totalViews' => event.Total_Views__c != null ? event.Total_Views__c : 0,
            'viralScore' => event.Viral_Score__c != null ? event.Viral_Score__c : 0,
            'twitterCardType' => String.isNotBlank(event.Video_URL__c) ? 'player' : 'summary_large_image'
        };
    }
    
    private static Map<String, Object> formatFixture(Commentary_Event__c event) {
        return new Map<String, Object>{
            'id' => event.Fixture__c,
            'name' => event.Fixture__r.Name,
            'homeTeamName' => event.Fixture__r.Home_Team__r?.Name,
            'homeTeamLogo' => event.Fixture__r.Home_Team__r?.Logo_Url__c,
            'awayTeamName' => event.Fixture__r.Away_Team__r?.Name,
            'awayTeamLogo' => event.Fixture__r.Away_Team__r?.Logo_Url__c,
            'homeScore' => event.Fixture__r.Home_Score_Final__c,
            'awayScore' => event.Fixture__r.Away_Score_Final__c,
            'status' => event.Fixture__r.Status__c,
            'venue' => event.Fixture__r.Venue__c,
            'formattedDate' => event.Fixture__r.Fixture_Date_Time__c?.format('MMM d, yyyy'),
            'competitionName' => event.Fixture__r.Competition__r?.Name,
            'sportType' => event.Fixture__r.Competition__r?.Sport__c
        };
    }
    
    private static Map<String, Object> formatPeriod(Fixture_Period__c period) {
        if (period == null) return new Map<String, Object>();
        
        return new Map<String, Object>{
            'periodType' => period.Period_Type__c,
            'periodNumber' => period.Period_Number__c,
            'homeScore' => period.Home_Score_Period__c,
            'awayScore' => period.Away_Score_Period__c,
            'cumulativeHomeScore' => period.Home_Score_Cumulative__c,
            'cumulativeAwayScore' => period.Away_Score_Cumulative__c
        };
    }
    
    private static List<Map<String, Object>> formatMoments(List<Commentary_Event__c> moments) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        
        for (Commentary_Event__c moment : moments) {
            formatted.add(new Map<String, Object>{
                'id' => moment.Id,
                'title' => moment.Social_Share_Title__c,
                'minute' => moment.Event_Minute__c,
                'description' => moment.Description__c,
                'thumbnailUrl' => moment.Video_URL__c,
                'eventType' => moment.Event_Type__c,
                'icon' => getEventIcon(moment.Event_Type__c),
                'playerName' => moment.Primary_Player__r?.Name
            });
        }
        
        return formatted;
    }
    
    private static List<Map<String, Object>> formatTimelineEvents(
        List<Commentary_Event__c> events, 
        Id currentEventId
    ) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        
        for (Commentary_Event__c event : events) {
            formatted.add(new Map<String, Object>{
                'id' => event.Id,
                'minute' => event.Event_Minute__c,
                'icon' => getEventIcon(event.Event_Type__c),
                'shortDescription' => event.Description__c?.left(50),
                'isCurrent' => event.Id == currentEventId
            });
        }
        
        return formatted;
    }
    
    private static String buildSocialTitle(Commentary_Event__c event) {
        String emoji = getEventEmoji(event.Event_Type__c);
        String playerPart = event.Primary_Player__r?.Name != null ? event.Primary_Player__r.Name + ' - ' : '';
        String matchPart = event.Fixture__r.Home_Team__r?.Name + ' vs ' + event.Fixture__r.Away_Team__r?.Name;
        
        return emoji + ' ' + event.Event_Type__c.toUpperCase() + '! ' + playerPart + matchPart;
    }
    
    private static String getSocialImage(Commentary_Event__c event) {
        if (String.isNotBlank(event.Video_URL__c)) {
            return event.Video_URL__c;
        }
        if (event.Primary_Player__r?.Profile_Image_URL__c != null) {
            return event.Primary_Player__r.Profile_Image_URL__c;
        }
        if (event.Team__r?.Logo_Url__c != null) {
            return event.Team__r.Logo_Url__c;
        }
        return event.Fixture__r.Home_Team__r?.Logo_Url__c;
    }
    
    private static String getEventIcon(String eventType) {
        Map<String, String> iconMap = new Map<String, String>{
            'Goal' => '⚽',
            'Penalty Goal' => '🎯',
            'Yellow Card' => '🟨',
            'Red Card' => '🟥',
            'Substitution' => '🔄',
            'Try' => '🏉',
            'Wicket' => '🏏',
            'Conversion' => '🏉',
            'Penalty' => '🎯'
        };
        return iconMap.get(eventType) != null ? iconMap.get(eventType) : '📌';
    }
    
    private static String getEventEmoji(String eventType) {
        return getEventIcon(eventType);
    }
    
    private static String getTimeAgo(DateTime dt) {
        if (dt == null) return '';
        Long minutes = (System.now().getTime() - dt.getTime()) / 60000;
        if (minutes < 60) return minutes + 'm ago';
        Long hours = minutes / 60;
        if (hours < 24) return hours + 'h ago';
        Long days = hours / 24;
        return days + 'd ago';
    }
    
    private static String generateUserHash() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = String.valueOf(System.now().getTime());
        }
        Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(sessionId));
        return EncodingUtil.convertToHex(hash).substring(0, 32);
    }
    
    private static void updateEngagementCounts(Id eventId, String engagementType, String platform) {
        Commentary_Event__c event = [
            SELECT Id, Total_Shares__c, Total_Views__c, Twitter_Shares__c, 
                   Facebook_Shares__c, Viral_Score__c
            FROM Commentary_Event__c
            WHERE Id = :eventId
            LIMIT 1
        ];
        
        if (engagementType == 'Share') {
            event.Total_Shares__c = (event.Total_Shares__c != null ? event.Total_Shares__c : 0) + 1;
            
            if (platform == 'Twitter') {
                event.Twitter_Shares__c = (event.Twitter_Shares__c != null ? event.Twitter_Shares__c : 0) + 1;
            } else if (platform == 'Facebook') {
                event.Facebook_Shares__c = (event.Facebook_Shares__c != null ? event.Facebook_Shares__c : 0) + 1;
            }
        } else if (engagementType == 'View') {
            event.Total_Views__c = (event.Total_Views__c != null ? event.Total_Views__c : 0) + 1;
        }
        
        // Recalculate viral score
        Decimal shares = event.Total_Shares__c != null ? event.Total_Shares__c : 0;
        Decimal views = event.Total_Views__c != null ? event.Total_Views__c : 0;
        Decimal twitterShares = event.Twitter_Shares__c != null ? event.Twitter_Shares__c : 0;
        Decimal facebookShares = event.Facebook_Shares__c != null ? event.Facebook_Shares__c : 0;
        
        event.Viral_Score__c = (shares * 10) + (views * 1) + (twitterShares * 5) + (facebookShares * 3);
        
        update event;
    }
}

