// Verify players are now linked to teams
System.debug('\n=== PLAYER TEAM LINKS VERIFICATION ===\n');

// Query all imported players with their teams
List<Contact> players = [
    SELECT Id, Name, Current_Team__c, Current_Team__r.Name, Nationality__c,
           (SELECT Id, Team__r.Name, Jersey_Number__c, Status__c 
            FROM Team_Memberships__r)
    FROM Contact 
    WHERE LastName IN ('French', 'Lewis', 'Williams', 'Sneyd', 'Salah', 'Haaland', 'Isak', 'Palmer', 'van Dijk', 'Saka')
    ORDER BY Name
];

System.debug('Found ' + players.size() + ' players:\n');

for (Contact p : players) {
    System.debug('🏃 ' + p.Name + ' (' + p.Nationality__c + ')');
    if (p.Current_Team__c != null) {
        System.debug('   ✅ Current Team: ' + p.Current_Team__r.Name);
    } else {
        System.debug('   ❌ No Current Team set');
    }
    
    if (!p.Team_Memberships__r.isEmpty()) {
        for (Team_Membership__c tm : p.Team_Memberships__r) {
            System.debug('   📋 Membership: ' + tm.Team__r.Name + ' #' + tm.Jersey_Number__c + ' (' + tm.Status__c + ')');
        }
    } else {
        System.debug('   ❌ No Team Memberships');
    }
    System.debug('');
}

// Summary
Integer playersWithTeam = 0;
Integer teamMemberships = 0;
for (Contact p : players) {
    if (p.Current_Team__c != null) playersWithTeam++;
    teamMemberships += p.Team_Memberships__r.size();
}

System.debug('\n=== SUMMARY ===');
System.debug('✅ Players with Current Team: ' + playersWithTeam + '/' + players.size());
System.debug('✅ Total Team Memberships: ' + teamMemberships);

