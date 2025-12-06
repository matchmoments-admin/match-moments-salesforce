/**
 * @description Result wrapper for ESPN Sync operations
 * @author Brendan Milton
 * @date 2025-12-05
 */
public class ESPNSyncResult {
    
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    @AuraEnabled public String data { get; set; }
    @AuraEnabled public Id recordId { get; set; }
    @AuraEnabled public Integer recordsProcessed { get; set; }
    @AuraEnabled public Integer recordsCreated { get; set; }
    @AuraEnabled public Integer recordsUpdated { get; set; }
    
    public ESPNSyncResult() {
        this.success = false;
        this.message = '';
        this.errorMessage = '';
        this.data = '';
        this.recordsProcessed = 0;
        this.recordsCreated = 0;
        this.recordsUpdated = 0;
    }
    
    /**
     * @description Create a successful result
     * @param message Success message
     * @return ESPNSyncResult
     */
    public static ESPNSyncResult success(String message) {
        ESPNSyncResult result = new ESPNSyncResult();
        result.success = true;
        result.message = message;
        return result;
    }
    
    /**
     * @description Create a successful result with record ID
     * @param message Success message
     * @param recordId The record ID that was processed
     * @return ESPNSyncResult
     */
    public static ESPNSyncResult success(String message, Id recordId) {
        ESPNSyncResult result = success(message);
        result.recordId = recordId;
        return result;
    }
    
    /**
     * @description Create a failed result
     * @param errorMessage Error message
     * @return ESPNSyncResult
     */
    public static ESPNSyncResult failure(String errorMessage) {
        ESPNSyncResult result = new ESPNSyncResult();
        result.success = false;
        result.errorMessage = errorMessage;
        return result;
    }
    
    /**
     * @description Create a failed result with record ID
     * @param errorMessage Error message
     * @param recordId The record ID that failed
     * @return ESPNSyncResult
     */
    public static ESPNSyncResult failure(String errorMessage, Id recordId) {
        ESPNSyncResult result = failure(errorMessage);
        result.recordId = recordId;
        return result;
    }
    
    /**
     * @description Set the counts for bulk operations
     * @param processed Total records processed
     * @param created Records created
     * @param updated Records updated
     * @return ESPNSyncResult (for chaining)
     */
    public ESPNSyncResult withCounts(Integer processed, Integer created, Integer updated) {
        this.recordsProcessed = processed;
        this.recordsCreated = created;
        this.recordsUpdated = updated;
        return this;
    }
    
    /**
     * @description Set the data JSON
     * @param dataJson JSON string of additional data
     * @return ESPNSyncResult (for chaining)
     */
    public ESPNSyncResult withData(String dataJson) {
        this.data = dataJson;
        return this;
    }
}

