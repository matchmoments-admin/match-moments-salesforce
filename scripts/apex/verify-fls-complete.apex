System.debug('========== FLS VERIFICATION TEST ==========');
System.debug('');

// Test 1: Season__c
Schema.SObjectType seasonType = Schema.getGlobalDescribe().get('Season__c');
Map<String, Schema.SObjectField> seasonFields = seasonType.getDescribe().fields.getMap();
System.debug('Season__c Total Fields: ' + seasonFields.size());
System.debug('  Sport__c accessible: ' + (seasonFields.containsKey('sport__c') ? String.valueOf(seasonFields.get('sport__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 2: Team_Membership__c
Schema.SObjectType membershipType = Schema.getGlobalDescribe().get('Team_Membership__c');
Map<String, Schema.SObjectField> membershipFields = membershipType.getDescribe().fields.getMap();
System.debug('Team_Membership__c Total Fields: ' + membershipFields.size());
System.debug('  Team__c accessible: ' + (membershipFields.containsKey('team__c') ? String.valueOf(membershipFields.get('team__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Season__c accessible: ' + (membershipFields.containsKey('season__c') ? String.valueOf(membershipFields.get('season__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Jersey_Number__c accessible: ' + (membershipFields.containsKey('jersey_number__c') ? String.valueOf(membershipFields.get('jersey_number__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 3: Award__c  
Schema.SObjectType awardType = Schema.getGlobalDescribe().get('Award__c');
Map<String, Schema.SObjectField> awardFields = awardType.getDescribe().fields.getMap();
System.debug('Award__c Total Fields: ' + awardFields.size());
System.debug('  Player__c accessible: ' + (awardFields.containsKey('player__c') ? String.valueOf(awardFields.get('player__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Sport__c accessible: ' + (awardFields.containsKey('sport__c') ? String.valueOf(awardFields.get('sport__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 4: League_Config__c
Schema.SObjectType leagueConfigType = Schema.getGlobalDescribe().get('League_Config__c');
Map<String, Schema.SObjectField> leagueConfigFields = leagueConfigType.getDescribe().fields.getMap();
System.debug('League_Config__c Total Fields: ' + leagueConfigFields.size());
System.debug('  Season__c accessible: ' + (leagueConfigFields.containsKey('season__c') ? String.valueOf(leagueConfigFields.get('season__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Sync_Enabled__c accessible: ' + (leagueConfigFields.containsKey('sync_enabled__c') ? String.valueOf(leagueConfigFields.get('sync_enabled__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  API_Calls_Today__c accessible: ' + (leagueConfigFields.containsKey('api_calls_today__c') ? String.valueOf(leagueConfigFields.get('api_calls_today__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 5: ESPN_Sync_Error__c
Schema.SObjectType syncErrorType = Schema.getGlobalDescribe().get('ESPN_Sync_Error__c');
Map<String, Schema.SObjectField> syncErrorFields = syncErrorType.getDescribe().fields.getMap();
System.debug('ESPN_Sync_Error__c Total Fields: ' + syncErrorFields.size());
System.debug('  Error_Message__c accessible: ' + (syncErrorFields.containsKey('error_message__c') ? String.valueOf(syncErrorFields.get('error_message__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Stack_Trace__c accessible: ' + (syncErrorFields.containsKey('stack_trace__c') ? String.valueOf(syncErrorFields.get('stack_trace__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 6: API_Usage__c
Schema.SObjectType apiUsageType = Schema.getGlobalDescribe().get('API_Usage__c');
Map<String, Schema.SObjectField> apiUsageFields = apiUsageType.getDescribe().fields.getMap();
System.debug('API_Usage__c Total Fields: ' + apiUsageFields.size());
System.debug('  Endpoint__c accessible: ' + (apiUsageFields.containsKey('endpoint__c') ? String.valueOf(apiUsageFields.get('endpoint__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('  Requests_Today__c accessible: ' + (apiUsageFields.containsKey('requests_today__c') ? String.valueOf(apiUsageFields.get('requests_today__c').getDescribe().isAccessible()) : 'FIELD NOT FOUND'));
System.debug('');

// Test 7: Try SOQL queries
try {
    List<Season__c> seasons = [SELECT Id, Sport__c FROM Season__c LIMIT 1];
    System.debug('✅ Season__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ Season__c SOQL failed: ' + e.getMessage());
}

try {
    List<Team_Membership__c> memberships = [SELECT Id, Team__c, Season__c FROM Team_Membership__c LIMIT 1];
    System.debug('✅ Team_Membership__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ Team_Membership__c SOQL failed: ' + e.getMessage());
}

try {
    List<Award__c> awards = [SELECT Id, Sport__c FROM Award__c LIMIT 1];
    System.debug('✅ Award__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ Award__c SOQL failed: ' + e.getMessage());
}

try {
    List<League_Config__c> configs = [SELECT Id, Season__c, Sync_Enabled__c FROM League_Config__c LIMIT 1];
    System.debug('✅ League_Config__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ League_Config__c SOQL failed: ' + e.getMessage());
}

try {
    List<ESPN_Sync_Error__c> errors = [SELECT Id, Error_Message__c FROM ESPN_Sync_Error__c LIMIT 1];
    System.debug('✅ ESPN_Sync_Error__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ ESPN_Sync_Error__c SOQL failed: ' + e.getMessage());
}

try {
    List<API_Usage__c> usage = [SELECT Id, Endpoint__c, Requests_Today__c FROM API_Usage__c LIMIT 1];
    System.debug('✅ API_Usage__c SOQL query successful!');
} catch (Exception e) {
    System.debug('❌ API_Usage__c SOQL failed: ' + e.getMessage());
}

System.debug('');
System.debug('========== VERIFICATION COMPLETE ==========');

