// Check what fields are actually on Team_Membership__c
Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get('Team_Membership__c').getDescribe();
System.debug('Team_Membership__c fields:');
for (Schema.SObjectField field : describe.fields.getMap().values()) {
    System.debug('  - ' + field.getDescribe().getName() + ' (' + field.getDescribe().getLabel() + ')');
}

System.debug('\nSeason__c fields:');
describe = Schema.getGlobalDescribe().get('Season__c').getDescribe();
for (Schema.SObjectField field : describe.fields.getMap().values()) {
    System.debug('  - ' + field.getDescribe().getName() + ' (' + field.getDescribe().getLabel() + ')');
}

