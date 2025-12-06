/**
 * @description Abstract base class with shared logic for all sport handlers
 * @author Brendan Milton
 * @date 2025-11-27
 */
public virtual class SportHandlerBase {
    
    /**
     * @description Helper to safely parse dates from various APIs
     * @param dateString ISO date string (may include 'Z' or standard ISO format)
     * @return DateTime Parsed DateTime object
     */
    public DateTime parseIsoDate(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }
        
        // Handle 'Z' format or standard ISO
        String formatted = dateString.replace('T', ' ').replace('Z', '');
        
        // Remove milliseconds if present
        if (formatted.contains('.')) {
            formatted = formatted.substring(0, formatted.indexOf('.'));
        }
        
        try {
            return DateTime.valueOfGMT(formatted);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing date: ' + dateString + ' - ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Common logic to find or create a Team (Account)
     * @param espnId ESPN Team ID
     * @param name Team name
     * @param sport Sport type
     * @return Account Account record (not yet upserted)
     */
    public Account upsertTeam(String espnId, String name, String sport) {
        Account acc = new Account(
            ESPN_ID__c = espnId,
            Name = name,
            Sport_Type__c = sport
        );
        
        // In real implementation, add to a List for bulk upsert later
        return acc;
    }
    
    /**
     * @description Safely extract string value from Map
     * @param dataMap Map containing data
     * @param key Key to extract
     * @return String Value or empty string
     */
    protected String safeString(Map<String, Object> dataMap, String key) {
        if (dataMap == null || !dataMap.containsKey(key)) {
            return '';
        }
        Object value = dataMap.get(key);
        return value != null ? String.valueOf(value) : '';
    }
    
    /**
     * @description Safely extract decimal value from Map
     * @param dataMap Map containing data
     * @param key Key to extract
     * @return Decimal Value or 0
     */
    protected Decimal safeDecimal(Map<String, Object> dataMap, String key) {
        if (dataMap == null || !dataMap.containsKey(key)) {
            return 0;
        }
        Object value = dataMap.get(key);
        if (value == null) {
            return 0;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return 0;
        }
    }
}

