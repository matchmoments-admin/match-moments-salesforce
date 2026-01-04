// Test FFLIB Selector Methods
// This script tests the new bulk query methods added to selectors

System.debug('=== Testing FFLIB Selector Methods ===');

// Test 1: LineupsSelector.newInstance() and selectByMatchIds()
try {
    LineupsSelector lineupSelector = LineupsSelector.newInstance();
    System.debug('✓ LineupsSelector.newInstance() works');
    
    // Get a sample match ID for testing
    List<Match__c> sampleMatches = [SELECT Id FROM Match__c LIMIT 1];
    if (!sampleMatches.isEmpty()) {
        Set<Id> matchIds = new Set<Id>{ sampleMatches[0].Id };
        List<Lineup__c> lineups = lineupSelector.selectByMatchIds(matchIds);
        System.debug('✓ LineupsSelector.selectByMatchIds() works - Found ' + lineups.size() + ' lineups');
    } else {
        System.debug('⚠ No matches found to test selectByMatchIds');
    }
} catch (Exception e) {
    System.debug('✗ LineupsSelector test failed: ' + e.getMessage());
}

// Test 2: MatchParticipationsSelector.newInstance() and selectByMatchIds()
try {
    MatchParticipationsSelector participationSelector = MatchParticipationsSelector.newInstance();
    System.debug('✓ MatchParticipationsSelector.newInstance() works');
    
    List<Match__c> sampleMatches = [SELECT Id FROM Match__c LIMIT 1];
    if (!sampleMatches.isEmpty()) {
        Set<Id> matchIds = new Set<Id>{ sampleMatches[0].Id };
        List<Match_Participation__c> participations = participationSelector.selectByMatchIds(matchIds);
        System.debug('✓ MatchParticipationsSelector.selectByMatchIds() works - Found ' + participations.size() + ' participations');
    } else {
        System.debug('⚠ No matches found to test selectByMatchIds');
    }
} catch (Exception e) {
    System.debug('✗ MatchParticipationsSelector test failed: ' + e.getMessage());
}

// Test 3: MatchMomentsSelector.selectByMatchIds()
try {
    MatchMomentsSelector momentsSelector = MatchMomentsSelector.newInstance();
    System.debug('✓ MatchMomentsSelector.newInstance() works');
    
    List<Match__c> sampleMatches = [SELECT Id FROM Match__c LIMIT 1];
    if (!sampleMatches.isEmpty()) {
        Set<Id> matchIds = new Set<Id>{ sampleMatches[0].Id };
        List<Match_Moment__c> moments = momentsSelector.selectByMatchIds(matchIds);
        System.debug('✓ MatchMomentsSelector.selectByMatchIds() works - Found ' + moments.size() + ' moments');
    } else {
        System.debug('⚠ No matches found to test selectByMatchIds');
    }
} catch (Exception e) {
    System.debug('✗ MatchMomentsSelector test failed: ' + e.getMessage());
}

// Test 4: MatchPeriodsSelector.newInstance() and selectByFixtureId()
try {
    MatchPeriodsSelector periodsSelector = MatchPeriodsSelector.newInstance();
    System.debug('✓ MatchPeriodsSelector.newInstance() works');
    
    List<Match__c> sampleMatches = [SELECT Id FROM Match__c LIMIT 1];
    if (!sampleMatches.isEmpty()) {
        Set<Id> matchIds = new Set<Id>{ sampleMatches[0].Id };
        List<Match_Period__c> periods = periodsSelector.selectByFixtureId(matchIds);
        System.debug('✓ MatchPeriodsSelector.selectByFixtureId() works - Found ' + periods.size() + ' periods');
    } else {
        System.debug('⚠ No matches found to test selectByFixtureId');
    }
} catch (Exception e) {
    System.debug('✗ MatchPeriodsSelector test failed: ' + e.getMessage());
}

// Test 5: CommentariesSelector.newInstance()
try {
    CommentariesSelector commentarySelector = CommentariesSelector.newInstance();
    System.debug('✓ CommentariesSelector.newInstance() works');
} catch (Exception e) {
    System.debug('✗ CommentariesSelector test failed: ' + e.getMessage());
}

// Test 6: Verify Application.cls registers all selectors
try {
    // Test that Application.Selector can instantiate each selector
    LineupsSelector l1 = (LineupsSelector) Application.Selector.newInstance(Lineup__c.SObjectType);
    MatchParticipationsSelector m1 = (MatchParticipationsSelector) Application.Selector.newInstance(Match_Participation__c.SObjectType);
    MatchMomentsSelector m2 = (MatchMomentsSelector) Application.Selector.newInstance(Match_Moment__c.SObjectType);
    MatchPeriodsSelector m3 = (MatchPeriodsSelector) Application.Selector.newInstance(Match_Period__c.SObjectType);
    CommentariesSelector c1 = (CommentariesSelector) Application.Selector.newInstance(Commentary__c.SObjectType);
    
    System.debug('✓ Application.Selector properly registers all selectors');
} catch (Exception e) {
    System.debug('✗ Application.Selector registration test failed: ' + e.getMessage());
}

System.debug('=== FFLIB Selector Tests Complete ===');

