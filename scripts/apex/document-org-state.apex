// Document Current Org State - Run this to see what's actually deployed
System.debug('=== ORG STATE DOCUMENTATION ===\n');

List<String> objects = new List<String>{
    'Season__c',
    'Team_Membership__c', 
    'Award__c',
    'League_Config__c',
    'ESPN_Sync_Error__c',
    'API_Usage__c'
};

for (String objName : objects) {
    try {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objName).getDescribe();
        System.debug('\n' + objName + ' (' + describe.getLabel() + '):');
        
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : describe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            if (fieldDesc.isCustom() && !fieldDesc.getName().endsWith('__r')) {
                fieldNames.add(fieldDesc.getName());
            }
        }
        
        fieldNames.sort();
        System.debug('  Custom Fields (' + fieldNames.size() + '):');
        for (String fn : fieldNames) {
            System.debug('    - ' + fn);
        }
        
    } catch (Exception e) {
        System.debug('\n' + objName + ': ❌ NOT FOUND');
    }
}

System.debug('\n\n=== Copy this output and share it for troubleshooting ===');

