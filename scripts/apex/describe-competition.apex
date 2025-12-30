// Describe Competition__c object to see all fields
Schema.DescribeSObjectResult describeResult = Schema.SObjectType.Competition__c;
Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

System.debug('=== Competition__c Fields ===');
for (String fieldName : fieldMap.keySet()) {
    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
    System.debug(fieldName + ' (' + fieldDescribe.getLabel() + ') - Type: ' + fieldDescribe.getType());
}

// Check if Competition_Name__c exists
if (fieldMap.containsKey('competition_name__c')) {
    System.debug('✅ Competition_Name__c EXISTS');
} else {
    System.debug('❌ Competition_Name__c DOES NOT EXIST');
}

// Check what Name field is used
System.debug('Name field type: ' + fieldMap.get('name').getDescribe().getType());

