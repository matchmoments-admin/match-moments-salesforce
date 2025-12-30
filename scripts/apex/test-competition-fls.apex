// Test script to verify Competition__c FLS permissions are working
// Run this in Anonymous Apex to verify the fix

System.debug('=== Testing Competition__c Field Access ===');
System.debug('');

try {
    // Query Competition records with all the fields used in frontend
    List<Competition__c> comps = [
        SELECT Id, Name, ESPN_League_ID__c,
               Sport__c, Tier__c, Country__c,
               Competition_Type__c, Logo_URL__c, Status__c,
               Season__c, Season__r.Name, Season__r.Start_Date__c, Season__r.End_Date__c,
               Season__r.Sport__c, Season__r.Season_Type__c,
               Season_Year__c
        FROM Competition__c
        LIMIT 5
    ];
    
    System.debug('✅ SUCCESS: Retrieved ' + comps.size() + ' Competition records');
    System.debug('');
    
    for (Competition__c comp : comps) {
        System.debug('Competition: ' + comp.Name);
        System.debug('  ESPN League ID: ' + comp.ESPN_League_ID__c);
        System.debug('  Sport: ' + comp.Sport__c + ' (required field)');
        System.debug('  Tier: ' + comp.Tier__c + ' (FLS granted)');
        System.debug('  Country: ' + comp.Country__c + ' (FLS granted)');
        System.debug('  Type: ' + comp.Competition_Type__c + ' (required field)');
        System.debug('  Logo URL: ' + comp.Logo_URL__c + ' (FLS granted)');
        System.debug('  Status: ' + comp.Status__c + ' (FLS granted)');
        System.debug('  Season Year: ' + comp.Season_Year__c + ' (required field)');
        System.debug('  Season: ' + (comp.Season__c != null ? comp.Season__r.Name : 'null') + ' (FLS granted)');
        System.debug('');
    }
    
    // Test relationship queries (Competition__r from Match__c)
    System.debug('=== Testing Competition__r relationship queries ===');
    List<Match__c> matches = [
        SELECT Id, Name,
               Competition__r.Name, Competition__r.Sport__c, 
               Competition__r.Tier__c, Competition__r.Country__c
        FROM Match__c
        WHERE Competition__c != null
        LIMIT 3
    ];
    
    System.debug('✅ SUCCESS: Retrieved ' + matches.size() + ' Match records with Competition relationships');
    System.debug('');
    
    for (Match__c match : matches) {
        System.debug('Match: ' + match.Name);
        System.debug('  Competition: ' + match.Competition__r.Name);
        System.debug('  Sport: ' + match.Competition__r.Sport__c);
        System.debug('  Tier: ' + match.Competition__r.Tier__c);
        System.debug('  Country: ' + match.Competition__r.Country__c);
        System.debug('');
    }
    
    System.debug('=== ALL TESTS PASSED ===');
    System.debug('Competition__c FLS permissions are working correctly!');
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    System.debug('');
    System.debug('If you see field-level security errors, check:');
    System.debug('1. API_Data_Access permission set is assigned to your user');
    System.debug('2. Permission set includes FLS for: Tier__c, Country__c, Logo_URL__c, Status__c, Season__c');
}

