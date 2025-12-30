// Check Article__c fields to verify field names for web API queries
System.debug('=== ARTICLE__C FIELD VERIFICATION ===');
Map<String, Schema.SObjectField> articleFields = Schema.SObjectType.Article__c.fields.getMap();

// Check relationship fields
List<String> fieldsToCheck = new List<String>{
    'match__c',
    'related_match__c',
    'fixture__c',
    'related_fixture__c',
    'team__c',
    'related_team__c',
    'player__c',
    'related_player__c',
    'competition__c',
    'thumbnail_url__c',
    'header_image_url__c',
    'featured_image_url__c',
    'author__c',
    'published_date__c',
    'article_date__c'
};

for (String fieldName : fieldsToCheck) {
    if (articleFields.containsKey(fieldName)) {
        Schema.DescribeFieldResult field = articleFields.get(fieldName).getDescribe();
        System.debug('✅ ' + field.getName() + ' (' + field.getLabel() + ') - Type: ' + field.getType());
    } else {
        System.debug('❌ ' + fieldName + ' DOES NOT EXIST');
    }
}

// List ALL fields in Article__c for reference
System.debug('\n=== ALL ARTICLE__C FIELDS ===');
List<String> allFields = new List<String>(articleFields.keySet());
allFields.sort();
for (String fname : allFields) {
    Schema.DescribeFieldResult field = articleFields.get(fname).getDescribe();
    if (field.isCustom() || fname.contains('related') || fname.contains('match') || fname.contains('team') || fname.contains('player')) {
        System.debug(field.getName() + ' (' + field.getLabel() + ') - Type: ' + field.getType());
    }
}

