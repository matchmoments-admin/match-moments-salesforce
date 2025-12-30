// Check which objects have data
System.debug('=== DATA COUNT CHECK ===\n');

// Match__c
Integer matchCount = [SELECT COUNT() FROM Match__c];
System.debug('Match__c records: ' + matchCount);

// Fixture__c  
Integer fixtureCount = [SELECT COUNT() FROM Fixture__c];
System.debug('Fixture__c records: ' + fixtureCount);

// Match_Moment__c
Integer matchMomentCount = [SELECT COUNT() FROM Match_Moment__c];
System.debug('Match_Moment__c records: ' + matchMomentCount);

// Commentary_Event__c
Integer commentaryCount = [SELECT COUNT() FROM Commentary_Event__c];
System.debug('Commentary_Event__c records: ' + commentaryCount);

// Article__c
Integer articleCount = [SELECT COUNT() FROM Article__c];
System.debug('Article__c records: ' + articleCount);

// News_Article__c
Integer newsArticleCount = [SELECT COUNT() FROM News_Article__c];
System.debug('News_Article__c records: ' + newsArticleCount);

// Competition__c
Integer compCount = [SELECT COUNT() FROM Competition__c];
System.debug('Competition__c records: ' + compCount);

// Season__c
Integer seasonCount = [SELECT COUNT() FROM Season__c];
System.debug('Season__c records: ' + seasonCount);

// Account (Teams)
Integer teamCount = [SELECT COUNT() FROM Account WHERE ESPN_Team_ID__c != null];
System.debug('Account (Teams) records: ' + teamCount);

// Contact (Players)
Integer playerCount = [SELECT COUNT() FROM Contact WHERE ESPN_Player_ID__c != null];
System.debug('Contact (Players) records: ' + playerCount);

System.debug('\n=== ACTIVE OBJECT DETERMINATION ===');
if (matchCount > 0) {
    System.debug('✅ Use Match__c (has ' + matchCount + ' records)');
} else if (fixtureCount > 0) {
    System.debug('⚠️ Use Fixture__c (has ' + fixtureCount + ' records) - Match__c is empty');
} else {
    System.debug('❌ No match/fixture data in either object');
}

if (matchMomentCount > 0) {
    System.debug('✅ Use Match_Moment__c (has ' + matchMomentCount + ' records)');
} else if (commentaryCount > 0) {
    System.debug('⚠️ Use Commentary_Event__c (has ' + commentaryCount + ' records)');
} else {
    System.debug('❌ No moment/commentary data');
}

