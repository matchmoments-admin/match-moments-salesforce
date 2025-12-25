/**
 * NRL Data Import Helper
 * Uses GenericCSVImporter with pre-configured mappings for NRL 2024 data
 */
public with sharing class NRLDataImportHelper {
    
    public class ImportSummary {
        public Map<String, GenericCSVImporter.ImportResult> resultsByType = 
            new Map<String, GenericCSVImporter.ImportResult>();
        public Boolean overallSuccess = true;
        public Integer totalRecordsCreated = 0;
        public Integer totalRecordsFailed = 0;
        
        public String getSummary() {
            String summary = '=== NRL DATA IMPORT SUMMARY ===\n';
            for (String objectType : resultsByType.keySet()) {
                GenericCSVImporter.ImportResult result = resultsByType.get(objectType);
                summary += objectType + ': ' + result.getSummary() + '\n';
            }
            summary += 'Total Created: ' + totalRecordsCreated + '\n';
            summary += 'Total Failed: ' + totalRecordsFailed + '\n';
            summary += 'Overall Success: ' + overallSuccess;
            return summary;
        }
    }
    
    /**
     * Import NRL data from CSV content
     * Handles all object types in correct order to satisfy dependencies
     */
    public static ImportSummary importNRLData(String csvContent) {
        ImportSummary summary = new ImportSummary();
        
        try {
            // Parse CSV
            List<Map<String, String>> allRows = GenericCSVImporter.parseCSV(csvContent);
            
            // Group by object type
            Map<String, List<Map<String, String>>> rowsByType = groupRowsByType(allRows);
            
            // Import in dependency order
            importSeasons(rowsByType, summary);
            importCompetitions(rowsByType, summary);
            importTeams(rowsByType, summary);
            importPlayers(rowsByType, summary);
            importMatches(rowsByType, summary);
            importAwards(rowsByType, summary);
            importArticles(rowsByType, summary);
            
            // Calculate totals
            for (GenericCSVImporter.ImportResult result : summary.resultsByType.values()) {
                summary.totalRecordsCreated += result.recordsCreated;
                summary.totalRecordsFailed += result.recordsFailed;
                if (!result.success) {
                    summary.overallSuccess = false;
                }
            }
            
        } catch (Exception e) {
            summary.overallSuccess = false;
            System.debug('Import failed: ' + e.getMessage());
        }
        
        return summary;
    }
    
    /**
     * Group CSV rows by object_type column
     */
    private static Map<String, List<Map<String, String>>> groupRowsByType(
        List<Map<String, String>> allRows
    ) {
        Map<String, List<Map<String, String>>> rowsByType = 
            new Map<String, List<Map<String, String>>>();
            
        for (Map<String, String> row : allRows) {
            String objectType = row.get('object_type');
            if (String.isNotBlank(objectType)) {
                if (!rowsByType.containsKey(objectType)) {
                    rowsByType.put(objectType, new List<Map<String, String>>());
                }
                rowsByType.get(objectType).add(row);
            }
        }
        
        return rowsByType;
    }
    
    /**
     * Import Seasons
     */
    private static void importSeasons(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Season')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Season__c');
        config.fieldMappings.put('name', 'Season_Name__c');
        config.fieldMappings.put('sport', 'Sport__c');
        config.externalIdField = 'Season_Name__c';
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Season'), config);
        summary.resultsByType.put('Season', result);
    }
    
    /**
     * Import Competitions
     */
    private static void importCompetitions(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Competition')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Competition__c');
        config.fieldMappings.put('name', 'Competition_Name__c');
        config.fieldMappings.put('sport', 'Sport__c');
        config.fieldMappings.put('external_id', 'ESPN_League_ID__c');
        config.externalIdField = 'ESPN_League_ID__c';
        
        // Season lookup
        GenericCSVImporter.LookupConfig seasonLookup = new GenericCSVImporter.LookupConfig(
            'Season__c', 'Season_Name__c', 'season_name'
        );
        config.lookupMappings.put('Season__c', seasonLookup);
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Competition'), config);
        summary.resultsByType.put('Competition', result);
    }
    
    /**
     * Import Teams (as Accounts)
     */
    private static void importTeams(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Team')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Account');
        config.fieldMappings.put('name', 'Name');
        config.fieldMappings.put('sport', 'Sport__c');
        config.fieldMappings.put('venue', 'Venue_Name__c');
        
        // Note: gender and team_type might need picklist value adjustments
        // config.fieldMappings.put('gender', 'Gender_Class__c');
        // config.fieldMappings.put('team_type', 'Type');
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Team'), config);
        summary.resultsByType.put('Team', result);
    }
    
    /**
     * Import Players (as Contacts)
     */
    private static void importPlayers(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Player')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Contact');
        
        // Map name to LastName (we'll parse FirstName/LastName later if needed)
        config.fieldMappings.put('name', 'LastName');
        config.fieldMappings.put('nationality', 'Nationality__c');
        config.fieldMappings.put('date_of_birth', 'Date_of_Birth__c');
        config.fieldMappings.put('jersey_number', 'Jersey_Number__c');
        
        // Note: Position__c omitted as rugby positions may not match Salesforce picklist
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Player'), config);
        summary.resultsByType.put('Player', result);
    }
    
    /**
     * Import Matches
     */
    private static void importMatches(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Match')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Match__c');
        config.fieldMappings.put('match_datetime', 'Match_Date_Time__c');
        config.fieldMappings.put('status', 'Status__c');
        config.fieldMappings.put('home_score', 'Home_Score_Final__c');
        config.fieldMappings.put('away_score', 'Away_Score_Final__c');
        config.fieldMappings.put('venue', 'Venue__c');
        config.fieldMappings.put('attendance', 'Attendance__c');
        
        // Add lookups
        config.lookupMappings.put('Competition__c', 
            new GenericCSVImporter.LookupConfig('Competition__c', 'Competition_Name__c', 'competition_name'));
        config.lookupMappings.put('Season__c',
            new GenericCSVImporter.LookupConfig('Season__c', 'Season_Name__c', 'season_name'));
        config.lookupMappings.put('Home_Team__c',
            new GenericCSVImporter.LookupConfig('Account', 'Name', 'home_team'));
        config.lookupMappings.put('Away_Team__c',
            new GenericCSVImporter.LookupConfig('Account', 'Name', 'away_team'));
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Match'), config);
        summary.resultsByType.put('Match', result);
    }
    
    /**
     * Import Awards
     */
    private static void importAwards(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Award')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Award__c');
        config.fieldMappings.put('award_type', 'Award_Type__c');
        config.fieldMappings.put('award_category', 'Award_Category__c');
        config.fieldMappings.put('year', 'Year__c');
        
        // Add lookups (player and team awards handled differently)
        config.lookupMappings.put('Player__c',
            new GenericCSVImporter.LookupConfig('Contact', 'LastName', 'player_name'));
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Award'), config);
        summary.resultsByType.put('Award', result);
    }
    
    /**
     * Import Articles
     */
    private static void importArticles(
        Map<String, List<Map<String, String>>> rowsByType,
        ImportSummary summary
    ) {
        if (!rowsByType.containsKey('Article')) return;
        
        GenericCSVImporter.ImportConfig config = new GenericCSVImporter.ImportConfig('Article__c');
        config.fieldMappings.put('heading', 'Heading__c');
        config.fieldMappings.put('body', 'Body__c');
        config.fieldMappings.put('is_published', 'Is_Published__c');
        config.fieldMappings.put('article_type', 'Article_Type__c');
        
        GenericCSVImporter.ImportResult result = 
            GenericCSVImporter.importRecords(rowsByType.get('Article'), config);
        summary.resultsByType.put('Article', result);
    }
}

