/**
 * Describe Match__c Object - Get TRUE field list from org
 * This uses Schema.describeSObjects() which reflects actual org state
 */

System.debug('=== DESCRIBING MATCH__C OBJECT (TRUE ORG STATE) ===');
System.debug('');

Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');

if (matchType == null) {
    System.debug('❌ Match__c object does NOT exist in org');
} else {
    Schema.DescribeSObjectResult describe = matchType.getDescribe();
    
    System.debug('Object Name: ' + describe.getName());
    System.debug('Label: ' + describe.getLabel());
    System.debug('');
    
    Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
    System.debug('Total fields in org: ' + fieldMap.size());
    System.debug('');
    System.debug('All fields currently in Match__c:');
    
    List<String> fieldNames = new List<String>(fieldMap.keySet());
    fieldNames.sort();
    
    for (String fieldName : fieldNames) {
        Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
        String fieldType = String.valueOf(field.getType());
        System.debug('  - ' + field.getName() + ' (' + field.getLabel() + ') - Type: ' + fieldType);
    }
}

