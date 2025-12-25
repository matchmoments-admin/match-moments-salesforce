// Find the Rugby League players
List<Contact> rugbyPlayers = [
    SELECT Id, Name, Nationality__c, Jersey_Number__c, CreatedDate 
    FROM Contact 
    WHERE LastName IN ('French', 'Lewis', 'Williams', 'Sneyd')
    ORDER BY LastName
];

System.debug('\n=== RUGBY LEAGUE PLAYERS ===');
System.debug('Found ' + rugbyPlayers.size() + ' rugby players:');
for (Contact p : rugbyPlayers) {
    System.debug('  - ' + p.Name + ' (' + p.Nationality__c + ') Jersey #' + p.Jersey_Number__c + ' - Created: ' + p.CreatedDate);
}

// Check all players imported today
List<Contact> todaysPlayers = [
    SELECT Id, Name, Nationality__c, Position__c 
    FROM Contact 
    WHERE CreatedDate = TODAY
    ORDER BY Name
];

System.debug('\n=== ALL PLAYERS IMPORTED TODAY ===');
System.debug('Total: ' + todaysPlayers.size());
for (Contact p : todaysPlayers) {
    System.debug('  - ' + p.Name + ' (' + p.Nationality__c + ') Position: ' + p.Position__c);
}

