/**
 * Simple NRL Import using NRLDataImportHelper
 * 
 * Prerequisites:
 * 1. Upload nrl_2024_test_data.csv to Salesforce Files
 * 2. The file should be named "nrl_2024_test_data"
 * 
 * Alternative: Use the inline CSV approach (see below)
 */

// OPTION 1: Load from ContentVersion (uploaded file)
/*
String csvContent = [
    SELECT VersionData 
    FROM ContentVersion 
    WHERE Title = 'nrl_2024_test_data' 
    AND IsLatest = true 
    LIMIT 1
].VersionData.toString();
*/

// OPTION 2: Inline test data (replace with actual CSV content)
String csvContent = 
    'object_type,name,external_id,sport,gender,venue,nationality,date_of_birth,jersey_number\n' +
    'Season,2024,season_2024,,,,,,,\n' +
    'Team,Penrith Panthers,nrl_penrith,Rugby League,Men,BlueBet Stadium,,,,\n' +
    'Team,Melbourne Storm,nrl_storm,Rugby League,Men,AAMI Park,,,,\n' +
    'Player,Nathan Cleary,cleary_001,Rugby League,Men,,Australia,1997-11-14,7\n' +
    'Player,Jahrome Hughes,hughes_001,Rugby League,Men,,New Zealand,1994-05-18,7';

// Import using helper
NRLDataImportHelper.ImportSummary summary = NRLDataImportHelper.importNRLData(csvContent);

// Display results
System.debug(summary.getSummary());

// Detailed error reporting
for (String objectType : summary.resultsByType.keySet()) {
    GenericCSVImporter.ImportResult result = summary.resultsByType.get(objectType);
    if (!result.errors.isEmpty()) {
        System.debug('\n' + objectType + ' Errors:');
        for (String error : result.errors) {
            System.debug('  - ' + error);
        }
    }
}

