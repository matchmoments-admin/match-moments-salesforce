/**
 * Generic CSV Importer
 * Dynamically imports CSV data into Salesforce using configurable mappings
 * 
 * Usage:
 * 1. Parse CSV content into rows
 * 2. Define field mappings (CSV column -> Salesforce field)
 * 3. Create importer instance with configuration
 * 4. Execute import
 */
public with sharing class GenericCSVImporter {
    
    // Configuration Classes
    public class ImportConfig {
        public String objectType;           // e.g., 'Contact', 'Account'
        public String externalIdField;      // Field to use for upsert
        public Map<String, String> fieldMappings; // CSV column -> SF field
        public Map<String, LookupConfig> lookupMappings; // SF field -> lookup config
        
        public ImportConfig(String objectType) {
            this.objectType = objectType;
            this.fieldMappings = new Map<String, String>();
            this.lookupMappings = new Map<String, LookupConfig>();
        }
    }
    
    public class LookupConfig {
        public String lookupObject;         // Object to lookup (e.g., 'Account')
        public String lookupField;          // Field to match on lookup object
        public String csvColumn;            // CSV column containing lookup value
        
        public LookupConfig(String lookupObject, String lookupField, String csvColumn) {
            this.lookupObject = lookupObject;
            this.lookupField = lookupField;
            this.csvColumn = csvColumn;
        }
    }
    
    public class ImportResult {
        public Integer recordsProcessed = 0;
        public Integer recordsCreated = 0;
        public Integer recordsUpdated = 0;
        public Integer recordsFailed = 0;
        public List<String> errors = new List<String>();
        public Boolean success = false;
        
        public String getSummary() {
            return String.format(
                'Processed: {0}, Created: {1}, Updated: {2}, Failed: {3}',
                new List<String>{
                    String.valueOf(recordsProcessed),
                    String.valueOf(recordsCreated),
                    String.valueOf(recordsUpdated),
                    String.valueOf(recordsFailed)
                }
            );
        }
    }
    
    /**
     * Parse CSV content into list of rows (each row is a map of column -> value)
     */
    public static List<Map<String, String>> parseCSV(String csvContent) {
        List<Map<String, String>> rows = new List<Map<String, String>>();
        
        // Split into lines
        List<String> lines = csvContent.split('\n');
        if (lines.isEmpty()) return rows;
        
        // First line is headers
        List<String> headers = parseCSVLine(lines[0]);
        
        // Parse each data row
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) continue;
            
            List<String> values = parseCSVLine(line);
            Map<String, String> row = new Map<String, String>();
            
            for (Integer j = 0; j < headers.size() && j < values.size(); j++) {
                row.put(headers[j].trim(), values[j].trim());
            }
            
            rows.add(row);
        }
        
        return rows;
    }
    
    /**
     * Parse a single CSV line handling quotes and commas
     */
    private static List<String> parseCSVLine(String line) {
        List<String> values = new List<String>();
        String currentValue = '';
        Boolean inQuotes = false;
        
        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);
            
            if (currentChar == '"') {
                inQuotes = !inQuotes;
            } else if (currentChar == ',' && !inQuotes) {
                values.add(currentValue);
                currentValue = '';
            } else {
                currentValue += currentChar;
            }
        }
        
        // Add last value
        values.add(currentValue);
        
        return values;
    }
    
    /**
     * Import records from CSV rows
     */
    public static ImportResult importRecords(
        List<Map<String, String>> csvRows,
        ImportConfig config
    ) {
        ImportResult result = new ImportResult();
        
        try {
            // Step 1: Prepare lookup maps if needed
            Map<String, Map<String, Id>> lookupMaps = prepareLookupMaps(csvRows, config);
            
            // Step 2: Build SObjects from CSV rows
            List<SObject> records = new List<SObject>();
            
            for (Map<String, String> row : csvRows) {
                try {
                    SObject record = buildRecord(row, config, lookupMaps);
                    if (record != null) {
                        records.add(record);
                    }
                } catch (Exception e) {
                    result.recordsFailed++;
                    result.errors.add('Row error: ' + e.getMessage());
                }
            }
            
            result.recordsProcessed = records.size();
            
            // Step 3: Upsert records
            if (!records.isEmpty()) {
                Database.UpsertResult[] results;
                
                if (String.isNotBlank(config.externalIdField)) {
                    // Upsert using external ID
                    Schema.SObjectField externalIdSField = 
                        Schema.getGlobalDescribe().get(config.objectType)
                        .getDescribe().fields.getMap().get(config.externalIdField);
                    results = Database.upsert(records, externalIdSField, false);
                } else {
                    // Insert only
                    results = Database.upsert(records, false);
                }
                
                // Process results
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult upsertResult = results[i];
                    if (upsertResult.isSuccess()) {
                        if (upsertResult.isCreated()) {
                            result.recordsCreated++;
                        } else {
                            result.recordsUpdated++;
                        }
                    } else {
                        result.recordsFailed++;
                        String errorMsg = 'Record ' + i + ': ';
                        for (Database.Error err : upsertResult.getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        result.errors.add(errorMsg);
                    }
                }
            }
            
            result.success = (result.recordsFailed == 0);
            
        } catch (Exception e) {
            result.success = false;
            result.errors.add('Import error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Prepare lookup maps for relationship fields
     */
    private static Map<String, Map<String, Id>> prepareLookupMaps(
        List<Map<String, String>> csvRows,
        ImportConfig config
    ) {
        Map<String, Map<String, Id>> lookupMaps = new Map<String, Map<String, Id>>();
        
        for (String sfField : config.lookupMappings.keySet()) {
            LookupConfig lookupConfig = config.lookupMappings.get(sfField);
            
            // Collect unique values from CSV
            Set<String> lookupValues = new Set<String>();
            for (Map<String, String> row : csvRows) {
                String value = row.get(lookupConfig.csvColumn);
                if (String.isNotBlank(value)) {
                    lookupValues.add(value);
                }
            }
            
            // Query records
            Map<String, Id> lookupMap = new Map<String, Id>();
            if (!lookupValues.isEmpty()) {
                String soql = String.format(
                    'SELECT Id, {0} FROM {1} WHERE {0} IN :lookupValues',
                    new List<String>{
                        lookupConfig.lookupField,
                        lookupConfig.lookupObject
                    }
                );
                
                List<SObject> lookupRecords = Database.query(soql);
                for (SObject record : lookupRecords) {
                    String keyValue = String.valueOf(record.get(lookupConfig.lookupField));
                    lookupMap.put(keyValue, record.Id);
                }
            }
            
            lookupMaps.put(sfField, lookupMap);
        }
        
        return lookupMaps;
    }
    
    /**
     * Build a single SObject record from CSV row
     */
    private static SObject buildRecord(
        Map<String, String> row,
        ImportConfig config,
        Map<String, Map<String, Id>> lookupMaps
    ) {
        // Create SObject instance
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(config.objectType);
        SObject record = objectType.newSObject();
        
        // Map direct fields
        for (String csvColumn : config.fieldMappings.keySet()) {
            String sfField = config.fieldMappings.get(csvColumn);
            String value = row.get(csvColumn);
            
            if (String.isNotBlank(value)) {
                setFieldValue(record, sfField, value, config.objectType);
            }
        }
        
        // Map lookup fields
        for (String sfField : config.lookupMappings.keySet()) {
            LookupConfig lookupConfig = config.lookupMappings.get(sfField);
            String lookupValue = row.get(lookupConfig.csvColumn);
            
            if (String.isNotBlank(lookupValue)) {
                Map<String, Id> lookupMap = lookupMaps.get(sfField);
                Id lookupId = lookupMap.get(lookupValue);
                
                if (lookupId != null) {
                    record.put(sfField, lookupId);
                }
            }
        }
        
        return record;
    }
    
    /**
     * Set field value with type conversion
     */
    private static void setFieldValue(
        SObject record,
        String fieldName,
        String value,
        String objectType
    ) {
        // Get field type
        Schema.DescribeFieldResult fieldDescribe = 
            Schema.getGlobalDescribe().get(objectType)
            .getDescribe().fields.getMap().get(fieldName)
            .getDescribe();
        
        Schema.DisplayType fieldType = fieldDescribe.getType();
        
        // Convert and set value based on type
        try {
            if (fieldType == Schema.DisplayType.STRING || 
                fieldType == Schema.DisplayType.PICKLIST ||
                fieldType == Schema.DisplayType.TEXTAREA ||
                fieldType == Schema.DisplayType.EMAIL ||
                fieldType == Schema.DisplayType.PHONE ||
                fieldType == Schema.DisplayType.URL) {
                record.put(fieldName, value);
            }
            else if (fieldType == Schema.DisplayType.INTEGER) {
                record.put(fieldName, Integer.valueOf(value));
            }
            else if (fieldType == Schema.DisplayType.DOUBLE ||
                     fieldType == Schema.DisplayType.CURRENCY ||
                     fieldType == Schema.DisplayType.PERCENT) {
                record.put(fieldName, Decimal.valueOf(value));
            }
            else if (fieldType == Schema.DisplayType.BOOLEAN) {
                record.put(fieldName, Boolean.valueOf(value));
            }
            else if (fieldType == Schema.DisplayType.DATE) {
                record.put(fieldName, Date.valueOf(value));
            }
            else if (fieldType == Schema.DisplayType.DATETIME) {
                record.put(fieldName, DateTime.valueOf(value));
            }
            else {
                // Default to string
                record.put(fieldName, value);
            }
        } catch (Exception e) {
            System.debug('Error converting field ' + fieldName + ': ' + e.getMessage());
        }
    }
    
    /**
     * Utility: Read CSV columns from first row
     */
    public static List<String> getCSVColumns(String csvContent) {
        List<String> lines = csvContent.split('\n');
        if (lines.isEmpty()) return new List<String>();
        
        return parseCSVLine(lines[0]);
    }
}

