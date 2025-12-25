# Generic CSV Importer - Usage Guide

## Overview

The `GenericCSVImporter` class provides a flexible, reusable solution for importing CSV data into Salesforce. Instead of creating custom importers for each dataset, you can configure mappings to handle any CSV file.

## Key Features

- **Dynamic Field Mapping**: Map any CSV column to any Salesforce field
- **Type Conversion**: Automatically converts values to appropriate Salesforce field types
- **Lookup Relationships**: Handle lookup fields by querying related records
- **Upsert Support**: Use external IDs to update existing records
- **Error Handling**: Detailed error reporting for failed records
- **CSV Parsing**: Handles quoted values, commas in fields, and multi-line data

## Basic Usage

### 1. Parse CSV Content

```apex
// Read CSV content (from Static Resource, Document, or inline)
String csvContent = 'Name,Email,Phone\nJohn Doe,john@example.com,555-1234\nJane Smith,jane@example.com,555-5678';

// Parse into rows
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);
```

### 2. Configure Import

```apex
// Create import configuration
GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');

// Map CSV columns to Salesforce fields
config.fieldMappings.put('Name', 'LastName');
config.fieldMappings.put('Email', 'Email');
config.fieldMappings.put('Phone', 'Phone');

// Optional: Set external ID field for upsert
config.externalIdField = 'Email';
```

### 3. Execute Import

```apex
// Import records
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);

// Check results
System.debug('Success: ' + result.success);
System.debug(result.getSummary());
if (!result.errors.isEmpty()) {
    for (String error : result.errors) {
        System.debug('Error: ' + error);
    }
}
```

## Advanced: Handling Lookups

For fields that reference other objects, use `LookupConfig`:

```apex
// Import contacts with Account lookup
GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');

// Map simple fields
config.fieldMappings.put('FirstName', 'FirstName');
config.fieldMappings.put('LastName', 'LastName');
config.fieldMappings.put('Email', 'Email');

// Configure Account lookup
// CSV column 'CompanyName' will be matched against Account.Name
GenericCSVImporter.LookupConfig accountLookup = new GenericCSVImporter.LookupConfig(
    'Account',      // Object to lookup
    'Name',         // Field to match on
    'CompanyName'   // CSV column with value
);
config.lookupMappings.put('AccountId', accountLookup);

// Execute import
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);
```

## Example: NRL Player Import

Here's how to use the generic importer for NRL player data:

```apex
// Sample CSV content
String csvContent = 
    'FirstName,LastName,Nationality,DateOfBirth,JerseyNumber,TeamName\n' +
    'Nathan,Cleary,Australia,1997-11-14,7,Penrith Panthers\n' +
    'Jahrome,Hughes,New Zealand,1994-05-18,7,Melbourne Storm';

// Parse CSV
List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);

// Configure import for Contact (Players)
GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');

// Map player fields
config.fieldMappings.put('FirstName', 'FirstName');
config.fieldMappings.put('LastName', 'LastName');
config.fieldMappings.put('Nationality', 'Nationality__c');
config.fieldMappings.put('DateOfBirth', 'Date_of_Birth__c');
config.fieldMappings.put('JerseyNumber', 'Jersey_Number__c');

// Configure team lookup
GenericCSVImporter.LookupConfig teamLookup = new GenericCSVImporter.LookupConfig(
    'Account',   // Teams are stored as Accounts
    'Name',      // Match on Account Name
    'TeamName'   // CSV column containing team name
);
config.lookupMappings.put('Current_Team__c', teamLookup);

// Execute import
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);

// Display results
System.debug('Import completed: ' + result.getSummary());
System.debug('Created: ' + result.recordsCreated);
System.debug('Updated: ' + result.recordsUpdated);
System.debug('Failed: ' + result.recordsFailed);

if (!result.errors.isEmpty()) {
    System.debug('Errors:');
    for (String error : result.errors) {
        System.debug('  - ' + error);
    }
}
```

## Example: Match Results Import

```apex
String csvContent = 
    'MatchDate,HomeTeam,AwayTeam,HomeScore,AwayScore,Venue\n' +
    '2024-10-06,Penrith Panthers,Melbourne Storm,14,6,Accor Stadium\n' +
    '2024-09-28,Penrith Panthers,Cronulla Sharks,26,6,Accor Stadium';

List<Map<String, String>> rows = GenericCSVImporter.parseCSV(csvContent);

GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Match__c');

// Map direct fields
config.fieldMappings.put('MatchDate', 'Match_Date_Time__c');
config.fieldMappings.put('HomeScore', 'Home_Score_Final__c');
config.fieldMappings.put('AwayScore', 'Away_Score_Final__c');
config.fieldMappings.put('Venue', 'Venue__c');

// Configure lookups for teams
GenericCSVImporter.LookupConfig homeTeamLookup = new GenericCSVImporter.LookupConfig(
    'Account', 'Name', 'HomeTeam'
);
config.lookupMappings.put('Home_Team__c', homeTeamLookup);

GenericCSVImporter.LookupConfig awayTeamLookup = new GenericCSVImporter.LookupConfig(
    'Account', 'Name', 'AwayTeam'
);
config.lookupMappings.put('Away_Team__c', awayTeamLookup);

// Import
GenericCSVImporter.ImportResult result = GenericCSVImporter.importRecords(rows, config);
```

## Utility Methods

### Get CSV Columns

Inspect CSV structure before importing:

```apex
String csvContent = '...';
List<String> columns = GenericCSVImporter.getCSVColumns(csvContent);
System.debug('CSV Columns: ' + columns);
```

## Type Conversions

The importer automatically handles these Salesforce field types:

- **String**: TEXT, PICKLIST, TEXTAREA, EMAIL, PHONE, URL
- **Integer**: NUMBER (whole numbers)
- **Decimal**: NUMBER (decimals), CURRENCY, PERCENT
- **Boolean**: CHECKBOX (true/false, 1/0)
- **Date**: DATE (format: YYYY-MM-DD)
- **DateTime**: DATETIME (format: YYYY-MM-DD HH:MM:SS)

## Best Practices

1. **Test with Small Datasets**: Start with a few rows to validate mappings
2. **Use External IDs**: Enable upsert capability for idempotent imports
3. **Handle Errors**: Always check `result.errors` and log failures
4. **Validate CSV Format**: Use `getCSVColumns()` to verify structure
5. **Pre-create Lookup Records**: Ensure referenced records exist before import
6. **Use Descriptive Names**: Make field mappings clear and maintainable
7. **Batch Large Imports**: For 1000+ records, consider splitting into batches

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| Field not writeable | Trying to set auto-number or formula field | Remove from fieldMappings |
| Invalid picklist value | CSV value doesn't match picklist | Update CSV or add picklist value |
| Required field missing | Required field not populated | Add to fieldMappings |
| Invalid date format | Date string not parseable | Use YYYY-MM-DD format |
| Lookup not found | Referenced record doesn't exist | Create lookup records first |

## Complete Example: Multi-Object Import

```apex
// Import workflow for NRL data with multiple object types

// 1. Import Seasons (no lookups)
String seasonCSV = 'SeasonName,Sport,StartDate\n2024,Rugby,2024-03-01';
List<Map<String, String>> seasonRows = GenericCSVImporter.parseCSV(seasonCSV);

GenericCSVImporter.ImportConfig seasonConfig = new GenericCSVImporter.ImportConfig('Season__c');
seasonConfig.fieldMappings.put('SeasonName', 'Season_Name__c');
seasonConfig.fieldMappings.put('Sport', 'Sport__c');
seasonConfig.fieldMappings.put('StartDate', 'Start_Date__c');
seasonConfig.externalIdField = 'Season_Name__c';

GenericCSVImporter.ImportResult seasonResult = GenericCSVImporter.importRecords(seasonRows, seasonConfig);
System.debug('Seasons: ' + seasonResult.getSummary());

// 2. Import Teams (no lookups)
String teamCSV = 'TeamName,Sport,Venue\nPenrith Panthers,Rugby,BlueBet Stadium';
List<Map<String, String>> teamRows = GenericCSVImporter.parseCSV(teamCSV);

GenericCSVImporter.ImportConfig teamConfig = new GenericCSVImporter.ImportConfig('Account');
teamConfig.fieldMappings.put('TeamName', 'Name');
teamConfig.fieldMappings.put('Sport', 'Sport__c');
teamConfig.fieldMappings.put('Venue', 'Venue_Name__c');

GenericCSVImporter.ImportResult teamResult = GenericCSVImporter.importRecords(teamRows, teamConfig);
System.debug('Teams: ' + teamResult.getSummary());

// 3. Import Players (with team lookup)
String playerCSV = 'FirstName,LastName,TeamName\nNathan,Cleary,Penrith Panthers';
List<Map<String, String>> playerRows = GenericCSVImporter.parseCSV(playerCSV);

GenericCSVImporter.ImportConfig playerConfig = new GenericCSVImporter.ImportConfig('Contact');
playerConfig.fieldMappings.put('FirstName', 'FirstName');
playerConfig.fieldMappings.put('LastName', 'LastName');

GenericCSVImporter.LookupConfig teamLookup = new GenericCSVImporter.LookupConfig(
    'Account', 'Name', 'TeamName'
);
playerConfig.lookupMappings.put('Current_Team__c', teamLookup);

GenericCSVImporter.ImportResult playerResult = GenericCSVImporter.importRecords(playerRows, playerConfig);
System.debug('Players: ' + playerResult.getSummary());
```

## Limitations

- Maximum 10,000 rows per import (Salesforce DML limits)
- Lookup queries limited by SOQL governor limits
- CSV must use comma delimiter (not semicolon or tab)
- No support for multi-select picklists (yet)
- No automatic parent record creation

## Next Steps

- Extend with support for StaticResource loading
- Add batch processing for large files
- Implement rollback on partial failures
- Add support for related list imports (master-detail)

