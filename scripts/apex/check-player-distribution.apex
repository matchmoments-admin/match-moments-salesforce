// Check which teams have players synced
System.debug('=== Detailed Player Analysis ===');
System.debug('');

// Check players by team
AggregateResult[] playersByTeam = [
    SELECT Account.Name teamName, COUNT(Id) playerCount
    FROM Contact
    WHERE ESPN_Player_ID__c != null
    GROUP BY Account.Name
    ORDER BY COUNT(Id) DESC
];

System.debug('--- Players by Team ---');
for (AggregateResult ar : playersByTeam) {
    String teamName = (String)ar.get('teamName');
    Integer playerCount = (Integer)ar.get('playerCount');
    System.debug('  - ' + teamName + ': ' + playerCount + ' players');
}
System.debug('');

// Check if all Premier League teams are synced
List<Account> eplTeams = [
    SELECT Name, ESPN_Team_ID__c, 
           (SELECT Id FROM Contacts WHERE ESPN_Player_ID__c != null)
    FROM Account
    WHERE ESPN_Team_ID__c != null
    AND Name IN ('Arsenal', 'Liverpool', 'Manchester City', 'Manchester United', 
                  'Chelsea', 'Tottenham Hotspur', 'AFC Bournemouth')
    ORDER BY Name
];

System.debug('--- Premier League Teams with Player Counts ---');
for (Account team : eplTeams) {
    System.debug('  - ' + team.Name + ': ' + team.Contacts.size() + ' players synced');
}
System.debug('');

