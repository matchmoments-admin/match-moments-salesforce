/**
 * Test if Match__c fields are actually accessible
 */

System.debug('=== Testing Match__c Fields ===');
System.debug('');

try {
    // Create a test Competition first
    Competition__c comp = new Competition__c(
        ESPN_League_ID__c = 'test.1',
        Sport__c = 'Soccer',
        Season_Year__c = '2024-25',
        Status__c = 'Active'
    );
    insert comp;
    
    // Create test teams
    Account homeTeam = new Account(Name = 'Test Home Team', Type = 'Team', Sport__c = 'Soccer');
    Account awayTeam = new Account(Name = 'Test Away Team', Type = 'Team', Sport__c = 'Soccer');
    insert new List<Account>{homeTeam, awayTeam};
    
    // Try to create a Match__c with ALL fields
    Match__c testMatch = new Match__c();
    testMatch.Competition__c = comp.Id;
    testMatch.Home_Team__c = homeTeam.Id;
    testMatch.Away_Team__c = awayTeam.Id;
    testMatch.Match_Date_Time__c = Datetime.now().addDays(7);
    testMatch.Status__c = 'Scheduled';
    
    // Try to set ESPN_Event_ID__c
    try {
        testMatch.put('ESPN_Event_ID__c', 'test-event-123');
        System.debug('✅ ESPN_Event_ID__c field is accessible');
    } catch (Exception e) {
        System.debug('❌ ESPN_Event_ID__c NOT accessible: ' + e.getMessage());
    }
    
    // Try to set scores
    try {
        testMatch.put('Home_Score_Final__c', 2);
        testMatch.put('Away_Score_Final__c', 1);
        System.debug('✅ Score fields are accessible');
    } catch (Exception e) {
        System.debug('❌ Score fields NOT accessible: ' + e.getMessage());
    }
    
    // Try to set venue
    try {
        testMatch.put('Venue__c', 'Test Stadium');
        System.debug('✅ Venue__c field is accessible');
    } catch (Exception e) {
        System.debug('❌ Venue__c NOT accessible: ' + e.getMessage());
    }
    
    // Insert the record
    insert testMatch;
    System.debug('✅ Match__c record created: ' + testMatch.Id);
    
    // Query it back to see what fields are populated
    String query = 'SELECT Id, Name, Competition__c, Home_Team__c, Away_Team__c, Match_Date_Time__c, Status__c';
    
    // Try to add optional fields to query
    List<String> optionalFields = new List<String>{
        'ESPN_Event_ID__c',
        'Home_Score_Final__c',
        'Away_Score_Final__c',
        'Venue__c',
        'Attendance__c',
        'Broadcast_URL__c',
        'Current_Period__c'
    };
    
    List<String> accessibleFields = new List<String>();
    for (String field : optionalFields) {
        try {
            String testQuery = 'SELECT ' + field + ' FROM Match__c WHERE Id = \'' + testMatch.Id + '\' LIMIT 1';
            List<Match__c> testResult = Database.query(testQuery);
            accessibleFields.add(field);
            System.debug('✅ ' + field + ' is queryable');
        } catch (Exception e) {
            System.debug('❌ ' + field + ' is NOT queryable');
        }
    }
    
    System.debug('');
    System.debug('=== SUMMARY ===');
    System.debug('Accessible optional fields: ' + accessibleFields.size() + '/' + optionalFields.size());
    System.debug('Fields: ' + String.join(accessibleFields, ', '));
    
    // Cleanup
    delete testMatch;
    delete new List<Account>{homeTeam, awayTeam};
    delete comp;
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Line: ' + e.getLineNumber());
    System.debug('Stack: ' + e.getStackTraceString());
}

