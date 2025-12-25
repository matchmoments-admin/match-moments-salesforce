// Import NRL 2024 Test Data
System.debug('\n=== NRL 2024 DATA IMPORT ===\n');

NRLTestDataImporter.ImportResult result = NRLTestDataImporter.importNRLData();

if (result.success) {
    System.debug('✅ IMPORT SUCCESSFUL!');
    System.debug('Seasons: ' + result.seasonsCreated + ' (reused if exists)');
    System.debug('Competitions: ' + result.competitionsCreated);
    System.debug('Teams: ' + result.teamsCreated);
    System.debug('Players: ' + result.playersCreated);
    System.debug('Team Memberships: ' + result.membershipsCreated);
    System.debug('Matches: ' + result.matchesCreated);
    System.debug('Player Stats: ' + result.statsCreated);
    System.debug('Awards: ' + result.awardsCreated);
    System.debug('Articles: ' + result.articlesCreated);
    System.debug('\nTotal NRL Records: ' + (result.seasonsCreated + result.competitionsCreated + result.teamsCreated + result.playersCreated + result.membershipsCreated + result.matchesCreated + result.statsCreated + result.awardsCreated + result.articlesCreated));
} else {
    System.debug('❌ IMPORT FAILED');
    System.debug('Error: ' + result.errorMessage);
}

