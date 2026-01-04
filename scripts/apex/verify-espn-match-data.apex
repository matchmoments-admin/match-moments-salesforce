/**
 * Verify ESPN match data completeness
 * Queries and displays all match-related data to verify data integrity
 */

System.debug('=== VERIFY ESPN MATCH DATA ===');
System.debug('Started at: ' + DateTime.now());
System.debug('');

// Find match with ESPN Event ID 740788
String espnEventId = '740788';

List<Match__c> matches = [
    SELECT Id, Name, ESPN_Event_ID__c, Match_Date_Time__c, Status__c,
           Home_Team__r.Name, Away_Team__r.Name,
           Home_Score_Final__c, Away_Score_Final__c,
           Competition__r.Name
    FROM Match__c
    WHERE ESPN_Event_ID__c = :espnEventId
    LIMIT 1
];

if (matches.isEmpty()) {
    System.debug('ERROR: Match with ESPN Event ID ' + espnEventId + ' not found.');
    System.debug('Please run test-espn-match-complete.apex first to create the match.');
    return;
}

Match__c match = matches[0];
System.debug('Match: ' + match.Name);
System.debug('  Competition: ' + match.Competition__r.Name);
System.debug('  Date: ' + (match.Match_Date_Time__c != null ? match.Match_Date_Time__c.format() : 'N/A'));
System.debug('  Status: ' + match.Status__c);
System.debug('  Teams: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name);
System.debug('  Score: ' + match.Home_Score_Final__c + ' - ' + match.Away_Score_Final__c);
System.debug('');

// Verify Lineups
System.debug('=== LINEUPS ===');
List<Lineup__c> lineups = [
    SELECT Id, Team__c, Formation__c, Starting_XI_Count__c,
           Captain__c, Lineup_JSON__c
    FROM Lineup__c
    WHERE Match__c = :match.Id
];

System.debug('Total Lineups: ' + lineups.size());
if (lineups.size() != 2) {
    System.debug('⚠ WARNING: Expected 2 lineups (home/away), found ' + lineups.size());
}

for (Lineup__c lineup : lineups) {
    System.debug('  Team ID: ' + lineup.Team__c);
    System.debug('    Formation: ' + lineup.Formation__c);
    System.debug('    Starting XI: ' + lineup.Starting_XI_Count__c);
    System.debug('    Captain ID: ' + (lineup.Captain__c != null ? lineup.Captain__c : 'Not set'));
    System.debug('    Has Lineup JSON: ' + (String.isNotBlank(lineup.Lineup_JSON__c) ? 'Yes' : 'No'));
}
System.debug('');

// Verify Match Participations
System.debug('=== MATCH PARTICIPATIONS ===');
List<Match_Participation__c> participations = [
    SELECT Id, Player__c, Team__c, Position__c, Role__c
    FROM Match_Participation__c
    WHERE Match__c = :match.Id
    ORDER BY Team__c, Role__c, Position__c
];

System.debug('Total Participations: ' + participations.size());

Map<String, Integer> participationsByTeam = new Map<String, Integer>();
Map<String, Integer> participationsByRole = new Map<String, Integer>();

for (Match_Participation__c p : participations) {
    String teamId = p.Team__c != null ? String.valueOf(p.Team__c) : 'Unknown';
    String role = p.Role__c != null ? p.Role__c : 'Unknown';
    
    participationsByTeam.put(teamId, participationsByTeam.getOrDefault(teamId, 0) + 1);
    participationsByRole.put(role, participationsByRole.getOrDefault(role, 0) + 1);
}

System.debug('By Team:');
for (String team : participationsByTeam.keySet()) {
    System.debug('  ' + team + ': ' + participationsByTeam.get(team));
}

System.debug('By Role:');
for (String role : participationsByRole.keySet()) {
    System.debug('  ' + role + ': ' + participationsByRole.get(role));
}

if (participations.size() < 22) {
    System.debug('⚠ WARNING: Expected at least 22 participations (11 per team), found ' + participations.size());
}
System.debug('');

// Verify Commentary
System.debug('=== COMMENTARY ===');
List<Commentary__c> commentaries = [
    SELECT Id, Name, Commentary_JSON__c
    FROM Commentary__c
    WHERE Match__c = :match.Id
];

System.debug('Total Commentaries: ' + commentaries.size());
if (commentaries.size() != 1) {
    System.debug('⚠ WARNING: Expected 1 commentary record, found ' + commentaries.size());
}

for (Commentary__c comm : commentaries) {
    System.debug('  Commentary: ' + comm.Name);
    System.debug('    Has JSON: ' + (String.isNotBlank(comm.Commentary_JSON__c) ? 'Yes' : 'No'));
}
System.debug('');

// Verify Match Moments
System.debug('=== MATCH MOMENTS ===');
Integer totalMoments = [
    SELECT COUNT()
    FROM Match_Moment__c
    WHERE Match__c = :match.Id
];

System.debug('Total Match Moments: ' + totalMoments);

List<Match_Moment__c> sampleMoments = [
    SELECT Id, Event_Type__c, Event_Minute__c, Event_Second__c,
           Description__c, Primary_Player__c, Team__c,
           Is_Shareable__c, Event_Importance__c
    FROM Match_Moment__c
    WHERE Match__c = :match.Id
    ORDER BY Event_Time__c ASC
    LIMIT 20
];

System.debug('Sample Moments (first 20):');
Map<String, Integer> momentsByType = new Map<String, Integer>();

for (Match_Moment__c moment : sampleMoments) {
    String eventType = moment.Event_Type__c != null ? moment.Event_Type__c : 'Other';
    momentsByType.put(eventType, momentsByType.getOrDefault(eventType, 0) + 1);
    
    String timeStr = moment.Event_Minute__c != null ? String.valueOf(moment.Event_Minute__c) + '\'' : 'N/A';
    if (moment.Event_Second__c != null) {
        timeStr += '+' + String.valueOf(moment.Event_Second__c);
    }
    
    System.debug('  ' + timeStr + ' - ' + eventType + 
                 (moment.Primary_Player__c != null ? ' (Player: ' + moment.Primary_Player__c + ')' : '') +
                 (moment.Is_Shareable__c ? ' [Shareable]' : ''));
}

System.debug('Moments by Type:');
for (String type : momentsByType.keySet()) {
    System.debug('  ' + type + ': ' + momentsByType.get(type));
}
System.debug('');

// Verify Match Periods
System.debug('=== MATCH PERIODS ===');
List<Match_Period__c> periods = [
    SELECT Id, Period_Number__c, Period_Type__c, Status__c,
           Home_Score_Period__c, Away_Score_Period__c,
           Home_Score_Cumulative__c, Away_Score_Cumulative__c
    FROM Match_Period__c
    WHERE Match__c = :match.Id
    ORDER BY Period_Number__c ASC
];

System.debug('Total Periods: ' + periods.size());
if (periods.size() < 2) {
    System.debug('⚠ WARNING: Expected at least 2 periods (halves), found ' + periods.size());
}

for (Match_Period__c period : periods) {
    System.debug('  Period ' + period.Period_Number__c + ' (' + period.Period_Type__c + '):');
    System.debug('    Period Score: ' + period.Home_Score_Period__c + ' - ' + period.Away_Score_Period__c);
    System.debug('    Cumulative: ' + period.Home_Score_Cumulative__c + ' - ' + period.Away_Score_Cumulative__c);
    System.debug('    Status: ' + period.Status__c);
}

// Verify cumulative scores match final score
if (!periods.isEmpty()) {
    Match_Period__c lastPeriod = periods[periods.size() - 1];
    if (match.Home_Score_Final__c != null && match.Away_Score_Final__c != null) {
        if (lastPeriod.Home_Score_Cumulative__c != match.Home_Score_Final__c ||
            lastPeriod.Away_Score_Cumulative__c != match.Away_Score_Final__c) {
            System.debug('⚠ WARNING: Cumulative scores do not match final score');
            System.debug('  Final: ' + match.Home_Score_Final__c + ' - ' + match.Away_Score_Final__c);
            System.debug('  Cumulative: ' + lastPeriod.Home_Score_Cumulative__c + ' - ' + 
                        lastPeriod.Away_Score_Cumulative__c);
        } else {
            System.debug('✓ Cumulative scores match final score');
        }
    }
}
System.debug('');

// Summary
System.debug('=== SUMMARY ===');
System.debug('Match: ' + match.Name);
System.debug('Lineups: ' + lineups.size() + ' (expected: 2)');
System.debug('Participations: ' + participations.size() + ' (expected: ~22+)');
System.debug('Commentaries: ' + commentaries.size() + ' (expected: 1)');
System.debug('Match Moments: ' + totalMoments + ' (expected: >0)');
System.debug('Match Periods: ' + periods.size() + ' (expected: 2+)');
System.debug('');

System.debug('=== VERIFICATION COMPLETE ===');
System.debug('Completed at: ' + DateTime.now());

