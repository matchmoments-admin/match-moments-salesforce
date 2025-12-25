# Generic CSV Importer - Implementation Summary

## Overview

I've created a **generic, reusable CSV importer** for Salesforce instead of creating dataset-specific importers. This approach is more maintainable and flexible for importing any CSV data into Salesforce.

## What Was Created

### 1. Core Classes

#### `GenericCSVImporter` (Generic Engine)
**Location**: `force-app/main/default/classes/GenericCSVImporter.cls`

A fully generic CSV import engine that can handle any CSV file with configurable mappings.

**Key Features**:
- Dynamic CSV parsing (handles quotes, commas in values)
- Configurable field mappings (CSV column → Salesforce field)
- Automatic type conversion (String, Integer, Decimal, Boolean, Date, DateTime)
- Lookup relationship support (query related records before import)
- Upsert capability (use external IDs)
- Detailed error reporting
- Works with any Salesforce object

**Main Methods**:
- `parseCSV(String csvContent)` - Parse CSV into list of rows
- `importRecords(List<Map<String, String>> rows, ImportConfig config)` - Import records
- `getCSVColumns(String csvContent)` - Inspect CSV structure

#### `NRLDataImportHelper` (Domain-Specific Helper)
**Location**: `force-app/main/default/classes/NRLDataImportHelper.cls`

A convenience wrapper that uses `GenericCSVImporter` with pre-configured mappings for NRL data.

**Key Features**:
- Pre-configured field mappings for NRL CSV structure
- Handles multi-object CSV (Season, Competition, Team, Player, Match, Award, Article)
- Imports in correct dependency order
- Aggregates results across all object types

**Main Method**:
- `importNRLData(String csvContent)` - Import entire NRL dataset

### 2. Documentation

#### `GENERIC_CSV_IMPORTER_GUIDE.md`
Comprehensive usage guide with:
- Basic usage examples
- Advanced lookup handling
- Complete multi-object import workflow
- Error handling strategies
- Best practices
- Type conversion reference

### 3. Example Scripts

#### `scripts/apex/test-generic-importer.apex`
Simple test script demonstrating:
- Basic contact import
- CSV column inspection
- Team import
- Player import with team lookup

#### `scripts/apex/import-nrl-simple.apex`
Simplified NRL import using the helper class

#### `scripts/apex/import-nrl-generic.apex`
Detailed example showing how to use the generic importer directly with NRL data

## How to Use

### Quick Start (NRL Data)

```apex
// Load CSV content
String csvContent = '...'; // Your CSV content

// Import using helper
NRLDataImportHelper.ImportSummary summary = NRLDataImportHelper.importNRLData(csvContent);

// Check results
System.debug(summary.getSummary());
```

### Generic Usage (Any CSV)

```apex
// 1. Parse CSV
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);

// 2. Configure mappings
GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');
config.fieldMappings.put('FirstName', 'FirstName');
config.fieldMappings.put('LastName', 'LastName');
config.fieldMappings.put('Email', 'Email');
config.externalIdField = 'Email'; // For upsert

// 3. Import
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);

// 4. Check results
System.debug(result.getSummary());
```

### With Lookups

```apex
// Configure import
GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');
config.fieldMappings.put('FirstName', 'FirstName');
config.fieldMappings.put('LastName', 'LastName');

// Add Account lookup
GenericCSVImporter.LookupConfig accountLookup = new GenericCSVImporter.LookupConfig(
    'Account',      // Object to lookup
    'Name',         // Field to match
    'CompanyName'   // CSV column
);
config.lookupMappings.put('AccountId', accountLookup);

// Import
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);
```

## Advantages Over Dataset-Specific Importers

### Before (NRLTestDataImporter)
- ❌ Hard-coded data for specific dataset
- ❌ Need new class for each CSV file
- ❌ Not reusable
- ❌ Maintenance nightmare
- ❌ 700+ lines of hard-coded data

### After (GenericCSVImporter)
- ✅ Works with any CSV file
- ✅ Configurable mappings
- ✅ Fully reusable
- ✅ Easy to maintain
- ✅ Clean separation of data and logic
- ✅ Can create helpers for specific domains if needed

## Architecture

```
┌─────────────────────────────────────┐
│     Your CSV File(s)                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  GenericCSVImporter (Core Engine)   │
│  - CSV parsing                      │
│  - Type conversion                  │
│  - Lookup handling                  │
│  - Upsert logic                     │
└──────────────┬──────────────────────┘
               │
               ├─────────────────────────────────┐
               │                                 │
               ▼                                 ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│  NRLDataImportHelper     │    │  Other Domain Helpers    │
│  (Optional)              │    │  (Optional)              │
│  - Pre-configured for    │    │  - Configure for your    │
│    NRL data              │    │    specific use case     │
└──────────────────────────┘    └──────────────────────────┘
```

## Configuration Objects

### ImportConfig
```apex
ImportConfig config = new ImportConfig('ObjectName');
config.fieldMappings.put('CSVColumn', 'SalesforceField');
config.externalIdField = 'External_ID__c'; // Optional
config.lookupMappings.put('LookupField__c', lookupConfig);
```

### LookupConfig
```apex
LookupConfig lookup = new LookupConfig(
    'RelatedObject',        // Object to query
    'FieldToMatch',         // Field to match on
    'CSVColumnName'         // CSV column with value
);
```

### ImportResult
```apex
result.success;             // Overall success
result.recordsProcessed;    // Total records attempted
result.recordsCreated;      // New records created
result.recordsUpdated;      // Existing records updated
result.recordsFailed;       // Failed records
result.errors;              // List of error messages
result.getSummary();        // Formatted summary string
```

## Type Conversions

The importer automatically converts CSV strings to appropriate Salesforce types:

| Salesforce Type | CSV Format | Example |
|-----------------|------------|---------|
| String | Any text | "John Doe" |
| Integer | Whole number | 42 |
| Decimal | Decimal number | 3.14 |
| Boolean | true/false or 1/0 | true |
| Date | YYYY-MM-DD | 2024-03-01 |
| DateTime | YYYY-MM-DD HH:MM:SS | 2024-03-01 19:00:00 |
| Picklist | Exact value | Active |

## Best Practices

1. **Test First**: Start with small CSV samples to validate mappings
2. **Check Picklists**: Ensure CSV values match Salesforce picklist values exactly
3. **Use External IDs**: Enable upsert for idempotent imports
4. **Import Order**: Import parent objects before children
5. **Error Handling**: Always check `result.errors` and log failures
6. **Validate Structure**: Use `getCSVColumns()` to inspect CSV before import
7. **Lookup Pre-creation**: Ensure lookup records exist before importing children

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Field not writeable | Remove auto-number/formula fields from mappings |
| Invalid picklist value | Update CSV to match exact picklist value |
| Required field missing | Add field to `fieldMappings` |
| Invalid date format | Use YYYY-MM-DD or YYYY-MM-DD HH:MM:SS |
| Lookup not found | Create parent records first |

## Next Steps for NRL Import

To import the actual NRL CSV file:

1. **Upload CSV to Salesforce**:
   - Go to Files tab
   - Upload `nrl_2024_test_data.csv`
   - Note the file name

2. **Adjust Picklist Values** (if needed):
   - Check that CSV values match Salesforce picklists
   - Update either CSV or Salesforce picklist values

3. **Run Import**:
   ```apex
   // Load CSV
   String csvContent = [
       SELECT VersionData 
       FROM ContentVersion 
       WHERE Title = 'nrl_2024_test_data' 
       AND IsLatest = true 
       LIMIT 1
   ].VersionData.toString();
   
   // Import
   NRLDataImportHelper.ImportSummary summary = 
       NRLDataImportHelper.importNRLData(csvContent);
   
   // Check results
   System.debug(summary.getSummary());
   ```

4. **Review Results**:
   - Check `summary.overallSuccess`
   - Review `summary.resultsByType` for each object
   - Fix any errors and re-run

## File Reference

- `GenericCSVImporter.cls` - Core importer engine
- `NRLDataImportHelper.cls` - NRL-specific helper
- `GENERIC_CSV_IMPORTER_GUIDE.md` - Comprehensive usage guide
- `scripts/apex/test-generic-importer.apex` - Simple test examples
- `scripts/apex/import-nrl-simple.apex` - NRL import script
- `scripts/apex/import-nrl-generic.apex` - Detailed NRL import example

## Summary

You now have a **production-ready, generic CSV importer** that can:
- ✅ Handle any CSV file
- ✅ Map to any Salesforce object
- ✅ Handle lookups and relationships
- ✅ Provide detailed error reporting
- ✅ Support upsert operations
- ✅ Be extended for specific use cases

No more creating custom importers for each dataset! Just configure the mappings and import.

