// Simple verification of imported data
System.debug('\n===== DATA IMPORT VERIFICATION =====\n');

Integer seasonCount = [SELECT COUNT() FROM Season__c];
System.debug('✓ Seasons: ' + seasonCount);

Integer compCount = [SELECT COUNT() FROM Competition__c];
System.debug('✓ Competitions: ' + compCount);

Integer teamCount = [SELECT COUNT() FROM Account WHERE Type = 'Club'];
System.debug('✓ Teams: ' + teamCount);

Integer playerCount = [SELECT COUNT() FROM Contact];
System.debug('✓ Players: ' + playerCount);

Integer matchCount = [SELECT COUNT() FROM Match__c];
System.debug('✓ Matches: ' + matchCount);

Integer statsCount = [SELECT COUNT() FROM Player_Season_Stats__c];
System.debug('✓ Player Stats: ' + statsCount);

Integer awardCount = [SELECT COUNT() FROM Award__c];
System.debug('✓ Awards: ' + awardCount);

Integer articleCount = [SELECT COUNT() FROM Article__c];
System.debug('✓ Articles: ' + articleCount);

System.debug('\n===== VERIFICATION COMPLETE =====');
System.debug('Total records imported: ' + (seasonCount + compCount + teamCount + playerCount + matchCount + statsCount + awardCount + articleCount));

