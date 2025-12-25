/**
 * Apex Controller for CSV Import LWC
 * Provides methods to import CSV data through Lightning Web Components
 */
public with sharing class CSVImportController {
    
    /**
     * Get available Salesforce objects for import
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectOption> getAvailableObjects() {
        List<ObjectOption> options = new List<ObjectOption>();
        
        // Common objects for sports data
        Map<String, String> commonObjects = new Map<String, String>{
            'Contact' => 'Players',
            'Account' => 'Teams',
            'Season__c' => 'Seasons',
            'Competition__c' => 'Competitions',
            'Match__c' => 'Matches',
            'Award__c' => 'Awards',
            'Article__c' => 'Articles',
            'Team_Membership__c' => 'Team Memberships',
            'Player_Season_Stats__c' => 'Player Stats'
        };
        
        for (String objName : commonObjects.keySet()) {
            options.add(new ObjectOption(objName, commonObjects.get(objName)));
        }
        
        return options;
    }
    
    /**
     * Get fields for a specific object
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldOption> getObjectFields(String objectName) {
        List<FieldOption> fields = new List<FieldOption>();
        
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
                
                for (String fieldName : fieldMap.keySet()) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    
                    // Only include editable fields
                    if (fieldDescribe.isCreateable() || fieldDescribe.isUpdateable()) {
                        fields.add(new FieldOption(
                            fieldDescribe.getName(),
                            fieldDescribe.getLabel(),
                            String.valueOf(fieldDescribe.getType())
                        ));
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error getting fields: ' + e.getMessage());
        }
        
        return fields;
    }
    
    /**
     * Parse CSV and return column headers
     */
    @AuraEnabled
    public static List<String> parseCSVHeaders(String csvContent) {
        try {
            return GenericCSVImporter.getCSVColumns(csvContent);
        } catch (Exception e) {
            throw new AuraHandledException('Error parsing CSV: ' + e.getMessage());
        }
    }
    
    /**
     * Import CSV data using configured mappings
     */
    @AuraEnabled
    public static ImportResultWrapper importCSVData(
        String csvContent,
        String objectName,
        String fieldMappingsJson,
        String lookupMappingsJson,
        String externalIdField
    ) {
        try {
            // Parse CSV
            List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);
            
            // Build import config
            GenericCSVImporter.ImportConfig config = 
                new GenericCSVImporter.ImportConfig(objectName);
            
            // Add field mappings
            if (String.isNotBlank(fieldMappingsJson)) {
                Map<String, String> fieldMappings = 
                    (Map<String, String>) JSON.deserialize(fieldMappingsJson, Map<String, String>.class);
                config.fieldMappings = fieldMappings;
            }
            
            // Add lookup mappings
            if (String.isNotBlank(lookupMappingsJson)) {
                List<LookupMappingWrapper> lookupWrappers = 
                    (List<LookupMappingWrapper>) JSON.deserialize(
                        lookupMappingsJson, List<LookupMappingWrapper>.class
                    );
                
                for (LookupMappingWrapper wrapper : lookupWrappers) {
                    GenericCSVImporter.LookupConfig lookupConfig = 
                        new GenericCSVImporter.LookupConfig(
                            wrapper.lookupObject,
                            wrapper.lookupField,
                            wrapper.csvColumn
                        );
                    config.lookupMappings.put(wrapper.salesforceField, lookupConfig);
                }
            }
            
            // Set external ID field
            if (String.isNotBlank(externalIdField)) {
                config.externalIdField = externalIdField;
            }
            
            // Execute import
            GenericCSVImporter.ImportResult result = 
                GenericCSVImporter.importRecords(rows, config);
            
            // Convert to wrapper
            return new ImportResultWrapper(result);
            
        } catch (Exception e) {
            throw new AuraHandledException('Import failed: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    /**
     * Import NRL data using pre-configured helper
     */
    @AuraEnabled
    public static ImportSummaryWrapper importNRLData(String csvContent) {
        try {
            NRLDataImportHelper.ImportSummary summary = 
                NRLDataImportHelper.importNRLData(csvContent);
            
            return new ImportSummaryWrapper(summary);
            
        } catch (Exception e) {
            throw new AuraHandledException('NRL Import failed: ' + e.getMessage());
        }
    }
    
    // Wrapper Classes
    
    public class ObjectOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        
        public ObjectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    public class FieldOption {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        
        public FieldOption(String name, String label, String type) {
            this.name = name;
            this.label = label;
            this.type = type;
        }
    }
    
    public class ImportResultWrapper {
        @AuraEnabled public Integer recordsProcessed;
        @AuraEnabled public Integer recordsCreated;
        @AuraEnabled public Integer recordsUpdated;
        @AuraEnabled public Integer recordsFailed;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String summary;
        
        public ImportResultWrapper(GenericCSVImporter.ImportResult result) {
            this.recordsProcessed = result.recordsProcessed;
            this.recordsCreated = result.recordsCreated;
            this.recordsUpdated = result.recordsUpdated;
            this.recordsFailed = result.recordsFailed;
            this.errors = result.errors;
            this.success = result.success;
            this.summary = result.getSummary();
        }
    }
    
    public class ImportSummaryWrapper {
        @AuraEnabled public Map<String, ImportResultWrapper> resultsByType;
        @AuraEnabled public Boolean overallSuccess;
        @AuraEnabled public Integer totalRecordsCreated;
        @AuraEnabled public Integer totalRecordsFailed;
        @AuraEnabled public String summary;
        
        public ImportSummaryWrapper(NRLDataImportHelper.ImportSummary summary) {
            this.overallSuccess = summary.overallSuccess;
            this.totalRecordsCreated = summary.totalRecordsCreated;
            this.totalRecordsFailed = summary.totalRecordsFailed;
            this.summary = summary.getSummary();
            
            this.resultsByType = new Map<String, ImportResultWrapper>();
            for (String objType : summary.resultsByType.keySet()) {
                this.resultsByType.put(
                    objType, 
                    new ImportResultWrapper(summary.resultsByType.get(objType))
                );
            }
        }
    }
    
    public class LookupMappingWrapper {
        @AuraEnabled public String salesforceField;
        @AuraEnabled public String lookupObject;
        @AuraEnabled public String lookupField;
        @AuraEnabled public String csvColumn;
    }
}

