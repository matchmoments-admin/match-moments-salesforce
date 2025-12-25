/**
 * Example: Import NRL 2024 data using GenericCSVImporter
 * This demonstrates importing a multi-object CSV file
 */

// Step 1: Load CSV content (replace with actual file loading)
String csvContent = [
    SELECT VersionData 
    FROM ContentVersion 
    WHERE Title = 'nrl_2024_test_data' 
    AND IsLatest = true 
    LIMIT 1
].VersionData.toString();

// Step 2: Parse CSV
List<Map<String, String>> allRows = GenericCSVImporter.parseCSV(csvContent);
System.debug('Total rows: ' + allRows.size());

// Step 3: Filter rows by object type
Map<String, List<Map<String, String>>> rowsByType = new Map<String, List<Map<String, String>>>();
for (Map<String, String> row : allRows) {
    String objectType = row.get('object_type');
    if (String.isNotBlank(objectType)) {
        if (!rowsByType.containsKey(objectType)) {
            rowsByType.put(objectType, new List<Map<String, String>>());
        }
        rowsByType.get(objectType).add(row);
    }
}

System.debug('Object types found: ' + rowsByType.keySet());

// Step 4: Import Seasons (no dependencies)
System.debug('\n=== IMPORTING SEASONS ===');
GenericCSVImporter.ImportConfig seasonConfig = new GenericCSVImporter.ImportConfig('Season__c');
seasonConfig.fieldMappings.put('name', 'Season_Name__c');
seasonConfig.fieldMappings.put('sport', 'Sport__c');
seasonConfig.externalIdField = 'Season_Name__c';

GenericCSVImporter.ImportResult seasonResult = GenericCSVImporter.importRecords(
    rowsByType.get('Season'), seasonConfig
);
System.debug(seasonResult.getSummary());
if (!seasonResult.errors.isEmpty()) {
    for (String error : seasonResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 5: Import Competitions (depends on Season)
System.debug('\n=== IMPORTING COMPETITIONS ===');
GenericCSVImporter.ImportConfig compConfig = new GenericCSVImporter.ImportConfig('Competition__c');
compConfig.fieldMappings.put('name', 'Competition_Name__c');
compConfig.fieldMappings.put('sport', 'Sport__c');
compConfig.externalIdField = 'ESPN_League_ID__c';
compConfig.fieldMappings.put('external_id', 'ESPN_League_ID__c');

// Add Season lookup
GenericCSVImporter.LookupConfig seasonLookup = new GenericCSVImporter.LookupConfig(
    'Season__c', 'Season_Name__c', 'season_name'
);
compConfig.lookupMappings.put('Season__c', seasonLookup);

GenericCSVImporter.ImportResult compResult = GenericCSVImporter.importRecords(
    rowsByType.get('Competition'), compConfig
);
System.debug(compResult.getSummary());
if (!compResult.errors.isEmpty()) {
    for (String error : compResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 6: Import Teams (no dependencies)
System.debug('\n=== IMPORTING TEAMS ===');
GenericCSVImporter.ImportConfig teamConfig = new GenericCSVImporter.ImportConfig('Account');
teamConfig.fieldMappings.put('name', 'Name');
teamConfig.fieldMappings.put('sport', 'Sport__c');
teamConfig.fieldMappings.put('gender', 'Gender_Class__c');
teamConfig.fieldMappings.put('team_type', 'Type');
teamConfig.fieldMappings.put('venue', 'Venue_Name__c');

GenericCSVImporter.ImportResult teamResult = GenericCSVImporter.importRecords(
    rowsByType.get('Team'), teamConfig
);
System.debug(teamResult.getSummary());
if (!teamResult.errors.isEmpty()) {
    for (String error : teamResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 7: Import Players (no lookups yet - we'll add teams via Team_Membership later)
System.debug('\n=== IMPORTING PLAYERS ===');
GenericCSVImporter.ImportConfig playerConfig = new GenericCSVImporter.ImportConfig('Contact');
playerConfig.fieldMappings.put('name', 'LastName'); // Full name goes to LastName
playerConfig.fieldMappings.put('nationality', 'Nationality__c');
playerConfig.fieldMappings.put('date_of_birth', 'Date_of_Birth__c');
playerConfig.fieldMappings.put('jersey_number', 'Jersey_Number__c');
// Note: Position__c intentionally omitted as rugby positions may not match picklist

GenericCSVImporter.ImportResult playerResult = GenericCSVImporter.importRecords(
    rowsByType.get('Player'), playerConfig
);
System.debug(playerResult.getSummary());
if (!playerResult.errors.isEmpty()) {
    for (String error : playerResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 8: Import Matches (depends on Competition, Season, Teams)
System.debug('\n=== IMPORTING MATCHES ===');
GenericCSVImporter.ImportConfig matchConfig = new GenericCSVImporter.ImportConfig('Match__c');
matchConfig.fieldMappings.put('match_datetime', 'Match_Date_Time__c');
matchConfig.fieldMappings.put('status', 'Status__c');
matchConfig.fieldMappings.put('home_score', 'Home_Score_Final__c');
matchConfig.fieldMappings.put('away_score', 'Away_Score_Final__c');
matchConfig.fieldMappings.put('venue', 'Venue__c');
matchConfig.fieldMappings.put('attendance', 'Attendance__c');

// Add lookups
GenericCSVImporter.LookupConfig compLookup = new GenericCSVImporter.LookupConfig(
    'Competition__c', 'Competition_Name__c', 'competition_name'
);
matchConfig.lookupMappings.put('Competition__c', compLookup);

GenericCSVImporter.LookupConfig matchSeasonLookup = new GenericCSVImporter.LookupConfig(
    'Season__c', 'Season_Name__c', 'season_name'
);
matchConfig.lookupMappings.put('Season__c', matchSeasonLookup);

GenericCSVImporter.LookupConfig homeTeamLookup = new GenericCSVImporter.LookupConfig(
    'Account', 'Name', 'home_team'
);
matchConfig.lookupMappings.put('Home_Team__c', homeTeamLookup);

GenericCSVImporter.LookupConfig awayTeamLookup = new GenericCSVImporter.LookupConfig(
    'Account', 'Name', 'away_team'
);
matchConfig.lookupMappings.put('Away_Team__c', awayTeamLookup);

GenericCSVImporter.ImportResult matchResult = GenericCSVImporter.importRecords(
    rowsByType.get('Match'), matchConfig
);
System.debug(matchResult.getSummary());
if (!matchResult.errors.isEmpty()) {
    for (String error : matchResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 9: Import Awards (depends on Player, Team, Season, Competition)
System.debug('\n=== IMPORTING AWARDS ===');
GenericCSVImporter.ImportConfig awardConfig = new GenericCSVImporter.ImportConfig('Award__c');
awardConfig.fieldMappings.put('award_type', 'Award_Type__c');
awardConfig.fieldMappings.put('award_category', 'Award_Category__c');
awardConfig.fieldMappings.put('year', 'Year__c');

// Add lookups
GenericCSVImporter.LookupConfig awardSeasonLookup = new GenericCSVImporter.LookupConfig(
    'Season__c', 'Season_Name__c', 'season_name'
);
awardConfig.lookupMappings.put('Season__c', awardSeasonLookup);

GenericCSVImporter.LookupConfig awardPlayerLookup = new GenericCSVImporter.LookupConfig(
    'Contact', 'LastName', 'player_name'
);
awardConfig.lookupMappings.put('Player__c', awardPlayerLookup);

// Note: Team awards would need special handling - the CSV doesn't clearly distinguish

GenericCSVImporter.ImportResult awardResult = GenericCSVImporter.importRecords(
    rowsByType.get('Award'), awardConfig
);
System.debug(awardResult.getSummary());
if (!awardResult.errors.isEmpty()) {
    for (String error : awardResult.errors) { System.debug('ERROR: ' + error); }
}

// Step 10: Import Articles
System.debug('\n=== IMPORTING ARTICLES ===');
GenericCSVImporter.ImportConfig articleConfig = new GenericCSVImporter.ImportConfig('Article__c');
articleConfig.fieldMappings.put('heading', 'Heading__c');
articleConfig.fieldMappings.put('body', 'Body__c');
articleConfig.fieldMappings.put('is_published', 'Is_Published__c');
articleConfig.fieldMappings.put('article_type', 'Article_Type__c');

GenericCSVImporter.ImportResult articleResult = GenericCSVImporter.importRecords(
    rowsByType.get('Article'), articleConfig
);
System.debug(articleResult.getSummary());
if (!articleResult.errors.isEmpty()) {
    for (String error : articleResult.errors) { System.debug('ERROR: ' + error); }
}

// Final Summary
System.debug('\n=== IMPORT SUMMARY ===');
System.debug('Seasons: ' + seasonResult.recordsCreated + ' created');
System.debug('Competitions: ' + compResult.recordsCreated + ' created');
System.debug('Teams: ' + teamResult.recordsCreated + ' created');
System.debug('Players: ' + playerResult.recordsCreated + ' created');
System.debug('Matches: ' + matchResult.recordsCreated + ' created');
System.debug('Awards: ' + awardResult.recordsCreated + ' created');
System.debug('Articles: ' + articleResult.recordsCreated + ' created');

Integer totalRecords = seasonResult.recordsCreated + compResult.recordsCreated + 
    teamResult.recordsCreated + playerResult.recordsCreated + matchResult.recordsCreated +
    awardResult.recordsCreated + articleResult.recordsCreated;
System.debug('Total records created: ' + totalRecords);

