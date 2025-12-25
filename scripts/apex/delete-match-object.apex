/**
 * Delete Match__c object to redeploy it fresh with all fields
 */

System.debug('Checking for Match__c records...');
Integer recordCount = [SELECT COUNT() FROM Match__c];
System.debug('Found ' + recordCount + ' Match__c records');

if (recordCount > 0) {
    System.debug('Deleting all Match__c records...');
    delete [SELECT Id FROM Match__c];
    System.debug('✅ Deleted ' + recordCount + ' records');
} else {
    System.debug('✅ No records to delete');
}

System.debug('');
System.debug('Now run this command in terminal:');
System.debug('sfdx project deploy start --target-org brendan-dev-edition --metadata CustomObject:Match__c');

