// Fix existing records with correct picklist values
System.debug('=== Fixing Existing Records ===');

// Delete all imported test data to start fresh
List<Season__c> seasonsToDelete = [SELECT Id FROM Season__c WHERE Season_Name__c IN ('2024', '2024-25')];
List<Competition__c> compsToDelete = [SELECT Id FROM Competition__c WHERE ESPN_League_ID__c IN ('SL2024', 'EPL2024_25')];
List<Account> teamsToDelete = [SELECT Id FROM Account WHERE Type = 'Club' AND CreatedDate = TODAY];
List<Contact> playersToDelete = [SELECT Id FROM Contact WHERE CreatedDate = TODAY];
List<Match__c> matchesToDelete = [SELECT Id FROM Match__c WHERE CreatedDate = TODAY];
List<Player_Season_Stats__c> statsToDelete = [SELECT Id FROM Player_Season_Stats__c WHERE CreatedDate = TODAY];
List<Award__c> awardsToDelete = [SELECT Id FROM Award__c WHERE CreatedDate = TODAY];
List<Article__c> articlesToDelete = [SELECT Id FROM Article__c WHERE CreatedDate = TODAY];

System.debug('Deleting existing test data...');
delete articlesToDelete;
delete awardsToDelete;
delete statsToDelete;
delete matchesToDelete;
delete playersToDelete;
delete teamsToDelete;
delete compsToDelete;
delete seasonsToDelete;

System.debug('✓ Deleted: ' + (seasonsToDelete.size() + compsToDelete.size() + teamsToDelete.size() + playersToDelete.size() + matchesToDelete.size() + statsToDelete.size() + awardsToDelete.size() + articlesToDelete.size()) + ' records');
System.debug('=== Ready for fresh import ===');

