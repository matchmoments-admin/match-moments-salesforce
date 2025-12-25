// Create default Season__c records for common sports
// Idempotent - uses upsert by Season_Name__c + Sport__c

System.debug('=== Creating Default Seasons ===');

List<Season__c> seasons = new List<Season__c>();

// Soccer and Basketball - Split Year Seasons
seasons.add(new Season__c(
    Season_Name__c = '2023-2024',
    Start_Date__c = Date.newInstance(2023, 8, 1),
    End_Date__c = Date.newInstance(2024, 7, 31),
    Sport__c = 'Soccer',
    Season_Type__c = 'Split Year',
    Status__c = 'Completed'
));

seasons.add(new Season__c(
    Season_Name__c = '2024-2025',
    Start_Date__c = Date.newInstance(2024, 8, 1),
    End_Date__c = Date.newInstance(2025, 7, 31),
    Sport__c = 'Soccer',
    Season_Type__c = 'Split Year',
    Status__c = 'Active'
));

seasons.add(new Season__c(
    Season_Name__c = '2023-2024',
    Start_Date__c = Date.newInstance(2023, 10, 1),
    End_Date__c = Date.newInstance(2024, 6, 30),
    Sport__c = 'Basketball',
    Season_Type__c = 'Split Year',
    Status__c = 'Completed'
));

seasons.add(new Season__c(
    Season_Name__c = '2024-2025',
    Start_Date__c = Date.newInstance(2024, 10, 1),
    End_Date__c = Date.newInstance(2025, 6, 30),
    Sport__c = 'Basketball',
    Season_Type__c = 'Split Year',
    Status__c = 'Active'
));

// Cricket and Tennis - Calendar Year Seasons
seasons.add(new Season__c(
    Season_Name__c = '2024',
    Start_Date__c = Date.newInstance(2024, 1, 1),
    End_Date__c = Date.newInstance(2024, 12, 31),
    Sport__c = 'Cricket',
    Season_Type__c = 'Calendar Year',
    Status__c = 'Completed'
));

seasons.add(new Season__c(
    Season_Name__c = '2025',
    Start_Date__c = Date.newInstance(2025, 1, 1),
    End_Date__c = Date.newInstance(2025, 12, 31),
    Sport__c = 'Cricket',
    Season_Type__c = 'Calendar Year',
    Status__c = 'Active'
));

seasons.add(new Season__c(
    Season_Name__c = '2024',
    Start_Date__c = Date.newInstance(2024, 1, 1),
    End_Date__c = Date.newInstance(2024, 12, 31),
    Sport__c = 'Tennis',
    Season_Type__c = 'Calendar Year',
    Status__c = 'Completed'
));

seasons.add(new Season__c(
    Season_Name__c = '2025',
    Start_Date__c = Date.newInstance(2025, 1, 1),
    End_Date__c = Date.newInstance(2025, 12, 31),
    Sport__c = 'Tennis',
    Season_Type__c = 'Calendar Year',
    Status__c = 'Active'
));

// AFL - Split Year Season
seasons.add(new Season__c(
    Season_Name__c = '2024',
    Start_Date__c = Date.newInstance(2024, 3, 1),
    End_Date__c = Date.newInstance(2024, 9, 30),
    Sport__c = 'AFL',
    Season_Type__c = 'Split Year',
    Status__c = 'Completed'
));

seasons.add(new Season__c(
    Season_Name__c = '2025',
    Start_Date__c = Date.newInstance(2025, 3, 1),
    End_Date__c = Date.newInstance(2025, 9, 30),
    Sport__c = 'AFL',
    Season_Type__c = 'Split Year',
    Status__c = 'Active'
));

// Query existing seasons to avoid duplicates
Map<String, Season__c> existingSeasons = new Map<String, Season__c>();
for (Season__c existingSeason : [
    SELECT Id, Season_Name__c, Sport__c
    FROM Season__c
]) {
    String key = existingSeason.Season_Name__c + '_' + existingSeason.Sport__c;
    existingSeasons.put(key, existingSeason);
}

// Update IDs for existing seasons (for upsert)
List<Season__c> seasonsToUpsert = new List<Season__c>();
Integer newCount = 0;
Integer existingCount = 0;

for (Season__c season : seasons) {
    String key = season.Season_Name__c + '_' + season.Sport__c;
    if (existingSeasons.containsKey(key)) {
        season.Id = existingSeasons.get(key).Id;
        existingCount++;
    } else {
        newCount++;
    }
    seasonsToUpsert.add(season);
}

try {
    upsert seasonsToUpsert;
    System.debug('=== Successfully upserted ' + seasonsToUpsert.size() + ' seasons ===');
    System.debug('New seasons created: ' + newCount);
    System.debug('Existing seasons updated: ' + existingCount);
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('=== Season Creation Complete ===');

