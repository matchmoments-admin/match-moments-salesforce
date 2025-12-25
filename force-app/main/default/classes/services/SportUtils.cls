/**
 * @description Utility class for sport-related operations
 * Static helper methods for sport normalization and configuration
 * @author Brendan Milton
 * @date 2025-12-05
 */
public class SportUtils {
    
    // Sport type constants
    public static final String SPORT_SOCCER = 'Soccer';
    public static final String SPORT_CRICKET = 'Cricket';
    public static final String SPORT_AFL = 'AFL';
    public static final String SPORT_BASKETBALL = 'Basketball';
    public static final String SPORT_NBA = 'NBA';
    public static final String SPORT_RUGBY = 'Rugby';
    public static final String SPORT_TENNIS = 'Tennis';
    public static final String SPORT_NFL = 'NFL';
    
    /**
     * @description Normalize sport type for ESPN API calls
     * @param sportType Internal sport type (Soccer, Basketball, etc.)
     * @return String ESPN API sport code
     */
    public static String normalizeSportForESPN(String sportType) {
        if (String.isBlank(sportType)) {
            return 'soccer';
        }
        
        switch on sportType.toLowerCase() {
            when 'basketball', 'nba' {
                return 'basketball';
            }
            when 'cricket' {
                return 'cricket';
            }
            when 'afl' {
                return 'afl';
            }
            when 'nfl', 'football' {
                return 'football';
            }
            when 'rugby' {
                return 'rugby';
            }
            when else {
                return 'soccer';
            }
        }
    }
    
    /**
     * @description Get default league code for a sport type
     * @param sportType Sport type
     * @return String Default league code
     */
    public static String getDefaultLeagueCode(String sportType) {
        if (String.isBlank(sportType)) {
            return 'eng.1';
        }
        
        switch on sportType.toLowerCase() {
            when 'basketball', 'nba' {
                return 'nba';
            }
            when 'cricket' {
                return 'icc';
            }
            when 'afl' {
                return 'afl';
            }
            when 'nfl', 'football' {
                return 'nfl';
            }
            when 'rugby' {
                return 'super-rugby';
            }
            when else {
                return 'eng.1'; // Premier League default
            }
        }
    }
    
    /**
     * @description Get record type developer name for a sport
     * @param sportType Sport type
     * @param objectType Object type (Match__c, Competition__c, etc.)
     * @return String Record type developer name
     */
    public static String getRecordTypeDeveloperName(String sportType, String objectType) {
        if (String.isBlank(sportType)) {
            sportType = SPORT_SOCCER;
        }
        
        Map<String, Map<String, String>> recordTypeMap = new Map<String, Map<String, String>>{
            SPORT_SOCCER => new Map<String, String>{
                'Match__c' => 'Soccer_Match',
                'Competition__c' => 'Soccer_League',
                'Match_Period__c' => 'Soccer'
            },
            SPORT_CRICKET => new Map<String, String>{
                'Match__c' => 'Cricket_Match',
                'Competition__c' => 'Cricket_Tournament',
                'Match_Period__c' => 'Cricket'
            },
            SPORT_AFL => new Map<String, String>{
                'Match__c' => 'AFL_Match',
                'Competition__c' => 'AFL_Season',
                'Match_Period__c' => 'AFL'
            },
            SPORT_RUGBY => new Map<String, String>{
                'Match__c' => 'Rugby_Match',
                'Competition__c' => 'Rugby_Competition',
                'Match_Period__c' => 'Rugby'
            },
            SPORT_BASKETBALL => new Map<String, String>{
                'Match__c' => 'Basketball_Game',
                'Competition__c' => 'Soccer_League', // Reuse
                'Match_Period__c' => 'Basketball'
            }
        };
        
        if (recordTypeMap.containsKey(sportType) && recordTypeMap.get(sportType).containsKey(objectType)) {
            return recordTypeMap.get(sportType).get(objectType);
        }
        
        // Default to Soccer
        return recordTypeMap.get(SPORT_SOCCER).get(objectType);
    }
    
    /**
     * @description Get the appropriate sport handler type
     * @param sportType Sport type string
     * @return Type The handler class type
     */
    public static Type getSportHandlerType(String sportType) {
        if (String.isBlank(sportType)) {
            return SoccerHandler.class;
        }
        
        switch on sportType.toLowerCase() {
            when 'cricket' {
                return CricketHandler.class;
            }
            when 'afl' {
                return AFLHandler.class;
            }
            when 'basketball', 'nba' {
                return NBAHandler.class;
            }
            when else {
                return SoccerHandler.class;
            }
        }
    }
    
    /**
     * @description Create sport handler instance
     * @param sportType Sport type string
     * @return ISportDataHandler Handler instance
     */
    public static ISportDataHandler getSportHandler(String sportType) {
        Type handlerType = getSportHandlerType(sportType);
        return (ISportDataHandler) handlerType.newInstance();
    }
}

