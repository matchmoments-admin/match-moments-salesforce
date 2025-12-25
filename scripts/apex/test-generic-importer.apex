/**
 * Simple test of GenericCSVImporter with inline CSV data
 * This demonstrates the basic usage without needing to upload files
 */

// Test 1: Import simple contacts
System.debug('=== TEST 1: SIMPLE CONTACT IMPORT ===');
String contactCSV = 
    'FirstName,LastName,Email,Phone\n' +
    'John,Doe,john.doe@test.com,555-1234\n' +
    'Jane,Smith,jane.smith@test.com,555-5678';

List<Map<String, String>> contactRows = GenericCSVImporter.parseCSV(contactCSV);
System.debug('Parsed ' + contactRows.size() + ' contact rows');

GenericCSVImporter.ImportConfig contactConfig = new GenericCSVImporter.ImportConfig('Contact');
contactConfig.fieldMappings.put('FirstName', 'FirstName');
contactConfig.fieldMappings.put('LastName', 'LastName');
contactConfig.fieldMappings.put('Email', 'Email');
contactConfig.fieldMappings.put('Phone', 'Phone');
contactConfig.externalIdField = 'Email';

GenericCSVImporter.ImportResult contactResult = GenericCSVImporter.importRecords(contactRows, contactConfig);
System.debug('Result: ' + contactResult.getSummary());
System.debug('Success: ' + contactResult.success);
if (!contactResult.errors.isEmpty()) {
    System.debug('Errors:');
    for (String error : contactResult.errors) {
        System.debug('  - ' + error);
    }
}

// Test 2: Inspect CSV columns
System.debug('\n=== TEST 2: INSPECT CSV COLUMNS ===');
String nrlSample = 'object_type,name,external_id,sport,gender,position\nPlayer,Nathan Cleary,cleary_001,Rugby League,Men,Halfback';
List<String> columns = GenericCSVImporter.getCSVColumns(nrlSample);
System.debug('CSV Columns: ' + columns);

// Test 3: Import accounts (teams)
System.debug('\n=== TEST 3: TEAM IMPORT ===');
String teamCSV = 
    'TeamName,Sport,Venue\n' +
    'Penrith Panthers,Rugby,BlueBet Stadium\n' +
    'Melbourne Storm,Rugby,AAMI Park';

List<Map<String, String>> teamRows = GenericCSVImporter.parseCSV(teamCSV);
System.debug('Parsed ' + teamRows.size() + ' team rows');

GenericCSVImporter.ImportConfig teamConfig = new GenericCSVImporter.ImportConfig('Account');
teamConfig.fieldMappings.put('TeamName', 'Name');
teamConfig.fieldMappings.put('Sport', 'Sport__c');
teamConfig.fieldMappings.put('Venue', 'Venue_Name__c');

GenericCSVImporter.ImportResult teamResult = GenericCSVImporter.importRecords(teamRows, teamConfig);
System.debug('Result: ' + teamResult.getSummary());
System.debug('Success: ' + teamResult.success);
if (!teamResult.errors.isEmpty()) {
    System.debug('Errors:');
    for (String error : teamResult.errors) {
        System.debug('  - ' + error);
    }
}

// Test 4: Import players with team lookup
System.debug('\n=== TEST 4: PLAYER WITH LOOKUP ===');
String playerCSV = 
    'FirstName,LastName,TeamName,JerseyNumber\n' +
    'Nathan,Cleary,Penrith Panthers,7\n' +
    'Jahrome,Hughes,Melbourne Storm,7';

List<Map<String, String>> playerRows = GenericCSVImporter.parseCSV(playerCSV);
System.debug('Parsed ' + playerRows.size() + ' player rows');

GenericCSVImporter.ImportConfig playerConfig = new GenericCSVImporter.ImportConfig('Contact');
playerConfig.fieldMappings.put('FirstName', 'FirstName');
playerConfig.fieldMappings.put('LastName', 'LastName');
playerConfig.fieldMappings.put('JerseyNumber', 'Jersey_Number__c');

// Add team lookup
GenericCSVImporter.LookupConfig teamLookup = new GenericCSVImporter.LookupConfig(
    'Account',  // Object to lookup
    'Name',     // Field to match on
    'TeamName'  // CSV column
);
playerConfig.lookupMappings.put('Current_Team__c', teamLookup);

GenericCSVImporter.ImportResult playerResult = GenericCSVImporter.importRecords(playerRows, playerConfig);
System.debug('Result: ' + playerResult.getSummary());
System.debug('Success: ' + playerResult.success);
if (!playerResult.errors.isEmpty()) {
    System.debug('Errors:');
    for (String error : playerResult.errors) {
        System.debug('  - ' + error);
    }
}

// Final Summary
System.debug('\n=== ALL TESTS COMPLETE ===');
System.debug('Contacts: ' + contactResult.recordsCreated + ' created, ' + contactResult.recordsUpdated + ' updated');
System.debug('Teams: ' + teamResult.recordsCreated + ' created, ' + teamResult.recordsUpdated + ' updated');
System.debug('Players: ' + playerResult.recordsCreated + ' created, ' + playerResult.recordsUpdated + ' updated');

