/**
 * Audit Script - Check Current Org State
 * Verifies which Match__c fields exist and what objects/fields are accessible
 */

System.debug('=== AUDIT: Current Org State ===');
System.debug('');

// ========================================
// 1. Check Match__c Fields via Schema Describe
// ========================================
System.debug('--- Checking Match__c Fields ---');

try {
    Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
    
    if (matchType != null) {
        Map<String, Schema.SObjectField> fieldMap = matchType.getDescribe().fields.getMap();
        
        List<String> expectedFields = new List<String>{
            'ESPN_Event_ID__c',
            'Home_Score_Final__c',
            'Away_Score_Final__c',
            'Venue__c',
            'Attendance__c',
            'Broadcast_URL__c',
            'Current_Period__c',
            'Match_Stats_JSON__c',
            'Referee__c',
            'Home_Sub_Score__c',
            'Away_Sub_Score__c',
            'Neutral_Venue__c',
            'Season__c',
            'Winner__c',
            'Display_Score__c',
            'Home_Team__c',
            'Away_Team__c',
            'Competition__c',
            'Match_Date_Time__c',
            'Status__c'
        };
        
        System.debug('Total Match__c fields in org: ' + fieldMap.size());
        System.debug('');
        System.debug('Checking 20 expected fields:');
        
        Integer foundCount = 0;
        Integer missingCount = 0;
        List<String> missingFields = new List<String>();
        
        for (String fieldName : expectedFields) {
            if (fieldMap.containsKey(fieldName.toLowerCase())) {
                System.debug('  ✅ ' + fieldName + ' - EXISTS');
                foundCount++;
            } else {
                System.debug('  ❌ ' + fieldName + ' - MISSING');
                missingCount++;
                missingFields.add(fieldName);
            }
        }
        
        System.debug('');
        System.debug('Summary: ' + foundCount + ' found, ' + missingCount + ' missing');
        
        if (missingCount > 0) {
            System.debug('');
            System.debug('Missing fields to deploy:');
            for (String field : missingFields) {
                System.debug('  - ' + field);
            }
        }
    } else {
        System.debug('❌ Match__c object does NOT exist in org');
    }
} catch (Exception e) {
    System.debug('ERROR checking Match__c: ' + e.getMessage());
}

System.debug('');

// ========================================
// 2. Check Account (Team) Fields
// ========================================
System.debug('--- Checking Account (Team) Fields ---');

try {
    Schema.SObjectType accountType = Schema.getGlobalDescribe().get('Account');
    Map<String, Schema.SObjectField> accountFields = accountType.getDescribe().fields.getMap();
    
    List<String> teamFields = new List<String>{
        'ESPN_Team_ID__c',
        'Abbreviation__c',
        'Venue_Name__c',
        'Logo_Url__c',
        'League__c'
    };
    
    for (String fieldName : teamFields) {
        if (accountFields.containsKey(fieldName.toLowerCase())) {
            System.debug('  ✅ ' + fieldName + ' - EXISTS');
        } else {
            System.debug('  ❌ ' + fieldName + ' - MISSING');
        }
    }
} catch (Exception e) {
    System.debug('ERROR checking Account: ' + e.getMessage());
}

System.debug('');

// ========================================
// 3. Check Contact (Player) Fields
// ========================================
System.debug('--- Checking Contact (Player) Fields ---');

try {
    Schema.SObjectType contactType = Schema.getGlobalDescribe().get('Contact');
    Map<String, Schema.SObjectField> contactFields = contactType.getDescribe().fields.getMap();
    
    List<String> playerFields = new List<String>{
        'ESPN_Player_ID__c',
        'Profile_Image_URL__c',
        'Position__c',
        'Jersey_Number__c'
    };
    
    for (String fieldName : playerFields) {
        if (contactFields.containsKey(fieldName.toLowerCase())) {
            System.debug('  ✅ ' + fieldName + ' - EXISTS');
        } else {
            System.debug('  ❌ ' + fieldName + ' - MISSING');
        }
    }
} catch (Exception e) {
    System.debug('ERROR checking Contact: ' + e.getMessage());
}

System.debug('');

// ========================================
// 4. Check Current Data Counts
// ========================================
System.debug('--- Current Data in Org ---');

try {
    Integer matchCount = [SELECT COUNT() FROM Match__c];
    System.debug('Match__c records: ' + matchCount);
} catch (Exception e) {
    System.debug('Match__c records: ERROR - ' + e.getMessage());
}

try {
    Integer fixtureCount = [SELECT COUNT() FROM Fixture__c];
    System.debug('Fixture__c records (old): ' + fixtureCount);
} catch (Exception e) {
    System.debug('Fixture__c records (old): ERROR - ' + e.getMessage());
}

try {
    Integer teamCount = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null];
    System.debug('Teams (Accounts with ESPN_Team_ID__c): ' + teamCount);
} catch (Exception e) {
    System.debug('Teams: ERROR - ' + e.getMessage());
}

try {
    Integer playerCount = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
    System.debug('Players (Contacts with ESPN_Player_ID__c): ' + playerCount);
} catch (Exception e) {
    System.debug('Players: ERROR - ' + e.getMessage());
}

try {
    Integer compCount = [SELECT COUNT() FROM Competition__c];
    System.debug('Competition__c records: ' + compCount);
} catch (Exception e) {
    System.debug('Competition__c records: ERROR - ' + e.getMessage());
}

System.debug('');

// ========================================
// 5. Test Basic Query on Match__c
// ========================================
System.debug('--- Testing Match__c Query ---');

try {
    // Try to query Match__c with only required fields
    List<Match__c> matches = [SELECT Id, Name, Home_Team__c, Away_Team__c, 
                               Competition__c, Match_Date_Time__c, Status__c
                               FROM Match__c LIMIT 1];
    System.debug('✅ Basic Match__c query works. Found ' + matches.size() + ' records');
} catch (Exception e) {
    System.debug('❌ Match__c query failed: ' + e.getMessage());
}

System.debug('');
System.debug('=== AUDIT COMPLETE ===');

