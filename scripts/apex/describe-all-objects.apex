// Describe all key objects to verify field names
System.debug('=== ARTICLE__C ===');
Schema.DescribeSObjectResult articleDescribe = Schema.SObjectType.Article__c;
Map<String, Schema.SObjectField> articleFields = articleDescribe.fields.getMap();
for (String fieldName : articleFields.keySet()) {
    if (fieldName.contains('heading') || fieldName.contains('match') || fieldName.contains('fixture')) {
        Schema.DescribeFieldResult field = articleFields.get(fieldName).getDescribe();
        System.debug('  ' + field.getName() + ' (' + field.getLabel() + ')');
    }
}

System.debug('\n=== MATCH_MOMENT__C ===');
Schema.SObjectType momentType = Schema.getGlobalDescribe().get('Match_Moment__c');
if (momentType != null) {
    System.debug('✅ Match_Moment__c EXISTS');
    Map<String, Schema.SObjectField> momentFields = momentType.getDescribe().fields.getMap();
    System.debug('Total fields: ' + momentFields.size());
} else {
    System.debug('❌ Match_Moment__c DOES NOT EXIST');
}

System.debug('\n=== COMMENTARY_EVENT__C ===');
Schema.SObjectType commentaryType = Schema.getGlobalDescribe().get('Commentary_Event__c');
if (commentaryType != null) {
    System.debug('✅ Commentary_Event__c EXISTS');
    Map<String, Schema.SObjectField> commentaryFields = commentaryType.getDescribe().fields.getMap();
    System.debug('Total fields: ' + commentaryFields.size());
} else {
    System.debug('❌ Commentary_Event__c DOES NOT EXIST');
}

System.debug('\n=== FIXTURE__C ===');
Schema.SObjectType fixtureType = Schema.getGlobalDescribe().get('Fixture__c');
if (fixtureType != null) {
    System.debug('✅ Fixture__c EXISTS');
    Map<String, Schema.SObjectField> fixtureFields = fixtureType.getDescribe().fields.getMap();
    System.debug('Total fields: ' + fixtureFields.size());
    System.debug('Has ESPN_Event_ID__c: ' + fixtureFields.containsKey('espn_event_id__c'));
} else {
    System.debug('❌ Fixture__c DOES NOT EXIST');
}

System.debug('\n=== ACCOUNT (Teams) ===');
Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
System.debug('Has ESPN_Team_ID__c: ' + accountFields.containsKey('espn_team_id__c'));
System.debug('Has League__c: ' + accountFields.containsKey('league__c'));
System.debug('Has Abbreviation__c: ' + accountFields.containsKey('abbreviation__c'));

System.debug('\n=== CONTACT (Players) ===');
Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
System.debug('Has ESPN_Player_ID__c: ' + contactFields.containsKey('espn_player_id__c'));
System.debug('Has Position__c: ' + contactFields.containsKey('position__c'));

