# Generic CSV Importer - Quick Start

## 🎯 What You Have Now

A **generic, reusable CSV importer** that works with ANY CSV file - no more creating custom importers for each dataset!

## 📦 Files Created

### Core Classes (Deployed ✅)
- `GenericCSVImporter.cls` - The generic import engine
- `NRLDataImportHelper.cls` - Pre-configured helper for NRL data

### Documentation
- `GENERIC_CSV_IMPORTER_GUIDE.md` - Complete usage guide
- `CSV_IMPORTER_SUMMARY.md` - Detailed implementation summary
- This file - Quick start guide

### Example Scripts
- `scripts/apex/test-generic-importer.apex` - Simple test examples
- `scripts/apex/import-nrl-simple.apex` - NRL import (simplified)
- `scripts/apex/import-nrl-generic.apex` - NRL import (detailed)

## 🚀 Import NRL Data in 3 Steps

### Step 1: Prepare CSV Content
```apex
// Option A: From uploaded file
String csvContent = [
    SELECT VersionData 
    FROM ContentVersion 
    WHERE Title = 'nrl_2024_test_data' 
    AND IsLatest = true 
    LIMIT 1
].VersionData.toString();

// Option B: Inline for testing
String csvContent = 'object_type,name...\n...';
```

### Step 2: Import
```apex
NRLDataImportHelper.ImportSummary summary = 
    NRLDataImportHelper.importNRLData(csvContent);
```

### Step 3: Check Results
```apex
System.debug(summary.getSummary());

// Check for errors
for (String objectType : summary.resultsByType.keySet()) {
    GenericCSVImporter.ImportResult result = summary.resultsByType.get(objectType);
    if (!result.errors.isEmpty()) {
        System.debug(objectType + ' Errors:');
        for (String error : result.errors) {
            System.debug('  - ' + error);
        }
    }
}
```

## 💡 Import Any Other CSV

### Basic Example
```apex
// 1. Parse CSV
String csvContent = 'FirstName,LastName,Email\nJohn,Doe,john@test.com';
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);

// 2. Configure
GenericCSVImporter.ImportConfig config = 
    new GenericCSVImporter.ImportConfig('Contact');
config.fieldMappings.put('FirstName', 'FirstName');
config.fieldMappings.put('LastName', 'LastName');
config.fieldMappings.put('Email', 'Email');

// 3. Import
GenericCSVImporter.ImportResult result = 
    GenericCSVImporter.importRecords(rows, config);

// 4. Check
System.debug(result.getSummary());
```

### With Lookups
```apex
// Add lookup after basic configuration
GenericCSVImporter.LookupConfig teamLookup = 
    new GenericCSVImporter.LookupConfig(
        'Account',      // Object to lookup
        'Name',         // Field to match
        'TeamName'      // CSV column
    );
config.lookupMappings.put('Current_Team__c', teamLookup);
```

## 📋 Common Patterns

### Pattern 1: Simple Import (No Lookups)
```apex
String csv = '...';
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csv);

GenericCSVImporter.ImportConfig config = 
    new GenericCSVImporter.ImportConfig('ObjectName');
config.fieldMappings.put('CSVColumn', 'SalesforceField');

GenericCSVImporter.ImportResult result = 
    GenericCSVImporter.importRecords(rows, config);
```

### Pattern 2: Upsert (Update or Insert)
```apex
// Add external ID field
config.externalIdField = 'External_ID__c';

// Now import will upsert instead of insert only
```

### Pattern 3: Multi-Object Import
```apex
// Group by type
Map<String, List<Map<String, String>>> byType = new Map<String, List<Map<String, String>>>();
for (Map<String, String> row : allRows) {
    String type = row.get('object_type');
    if (!byType.containsKey(type)) {
        byType.put(type, new List<Map<String, String>>());
    }
    byType.get(type).add(row);
}

// Import each type with its own config
// (Import parents before children!)
```

## 🔍 Testing

Run the test script to verify everything works:
```bash
sf apex run --file scripts/apex/test-generic-importer.apex
```

Expected output:
```
=== TEST 1: SIMPLE CONTACT IMPORT ===
Parsed 2 contact rows
Result: Processed: 2, Created: 2, Updated: 0, Failed: 0
Success: true

=== TEST 2: INSPECT CSV COLUMNS ===
CSV Columns: (object_type, name, external_id, sport, gender, position)

=== TEST 3: TEAM IMPORT ===
...
```

## 📚 More Information

- **Full Guide**: See `GENERIC_CSV_IMPORTER_GUIDE.md`
- **Implementation Details**: See `CSV_IMPORTER_SUMMARY.md`
- **NRL CSV Structure**: See `nrl_2024_test_data.csv`

## 🎓 Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Field Mapping** | Map CSV column to SF field | `config.fieldMappings.put('FirstName', 'FirstName')` |
| **Lookup** | Reference another object | `new LookupConfig('Account', 'Name', 'CompanyName')` |
| **External ID** | Enable upsert | `config.externalIdField = 'Email'` |
| **Type Conversion** | Automatic | '2024-03-01' → Date |

## ⚡ Pro Tips

1. **Test Small First**: Start with 2-3 rows to validate mappings
2. **Check Columns**: Use `getCSVColumns()` to inspect CSV structure
3. **Parent First**: Import parent objects before children
4. **Error Details**: Always check `result.errors` for failures
5. **Picklist Values**: Ensure CSV values match Salesforce exactly

## 🆘 Common Errors

| Error | Fix |
|-------|-----|
| "Field not writeable" | Remove auto-number fields from mappings |
| "Invalid picklist value" | Update CSV or Salesforce picklist |
| "Required field missing" | Add field to mappings |
| "Lookup not found" | Import parent records first |

## 🎉 You're Ready!

You now have a production-ready CSV importer that works with ANY CSV file. No more custom importers!

**Next**: Open `GENERIC_CSV_IMPORTER_GUIDE.md` for detailed examples and patterns.

