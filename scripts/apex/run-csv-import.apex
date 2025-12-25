// Execute CSV Test Data Import
CSVTestDataImporter.ImportResult result = CSVTestDataImporter.importTestData();

if (result.success) {
    System.debug('=== IMPORT SUCCESSFUL ===');
    System.debug('Seasons: ' + result.seasonsCreated);
    System.debug('Competitions: ' + result.competitionsCreated);
    System.debug('Teams: ' + result.teamsCreated);
    System.debug('Players: ' + result.playersCreated);
    System.debug('Matches: ' + result.matchesCreated);
    System.debug('Stats: ' + result.statsCreated);
    System.debug('Awards: ' + result.awardsCreated);
    System.debug('Articles: ' + result.articlesCreated);
} else {
    System.debug('=== IMPORT FAILED ===');
    System.debug('Error: ' + result.errorMessage);
}

