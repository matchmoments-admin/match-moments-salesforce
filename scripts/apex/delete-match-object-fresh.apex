/**
 * Delete Match__c Object to Allow Fresh Deployment
 * WARNING: This deletes the Match__c custom object from the org
 * Safe to run because audit confirmed 0 Match__c records exist
 */

System.debug('=== PREPARING TO DELETE MATCH__C OBJECT ===');
System.debug('WARNING: This will delete the Match__c custom object');
System.debug('');

// Verify no data exists
Integer matchCount = [SELECT COUNT() FROM Match__c];

if (matchCount > 0) {
    System.debug('❌ ABORT: ' + matchCount + ' Match__c records exist!');
    System.debug('Cannot safely delete object with data.');
} else {
    System.debug('✅ Confirmed: 0 Match__c records exist');
    System.debug('');
    System.debug('To delete Match__c object:');
    System.debug('1. Go to Setup → Object Manager → Match');
    System.debug('2. Click "Delete"');
    System.debug('3. Confirm deletion');
    System.debug('');
    System.debug('Then redeploy with:');
    System.debug('sf project deploy start --source-dir force-app/main/default/objects/Match__c --target-org brendan-dev-edition');
}

