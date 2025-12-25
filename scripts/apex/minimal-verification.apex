// Minimal Verification - Tests core objects that were definitely deployed
System.debug('=== MINIMAL DEPLOYMENT VERIFICATION ===\n');

// Test 1: Season object
System.debug('1. Season__c:');
Season__c season = new Season__c(Season_Name__c='Test 2024-25', Start_Date__c=Date.today());
insert season;
System.debug('   ✓ Created: ' + season.Id);

// Test 2: Award object
System.debug('\n2. Award__c:');
Account team = new Account(Name='Test Team');
insert team;
Contact player = new Contact(FirstName='John', LastName='Doe');
insert player;
Competition__c comp = new Competition__c(ESPN_League_ID__c='test', Sport__c='Soccer');
insert comp;

Award__c award = new Award__c(
    Player__c=player.Id,
    Team__c=team.Id,
    Season__c=season.Id,
    Competition__c=comp.Id,
    Award_Type__c='Test Award'
);
insert award;
System.debug('   ✓ Created: ' + award.Id);

// Test 3: Verify relationships
System.debug('\n3. Relationship Query:');
Award__c result = [
    SELECT Player__r.Name, Team__r.Name, Season__r.Season_Name__c
    FROM Award__c WHERE Id=:award.Id
];
System.debug('   ✓ Player: ' + result.Player__r.Name);
System.debug('   ✓ Team: ' + result.Team__r.Name);
System.debug('   ✓ Season: ' + result.Season__r.Season_Name__c);

// Test 4: League Config
System.debug('\n4. League_Config__c:');
League_Config__c config = new League_Config__c(
    Competition__c=comp.Id,
    ESPN_League_ID__c='test-config',
    Is_Active__c=true
);
insert config;
System.debug('   ✓ Created: ' + config.Id);

// Test 5: ESPN Sync Error
System.debug('\n5. ESPN_Sync_Error__c:');
ESPN_Sync_Error__c error = new ESPN_Sync_Error__c(
    League_Config__c=config.Id,
    Error_Type__c='API_ERROR',
    Error_Message__c='Test',
    Occurred_At__c=DateTime.now()
);
insert error;
System.debug('   ✓ Created: ' + error.Id);

// Test 6: API Usage
System.debug('\n6. API_Usage__c:');
API_Usage__c usage = new API_Usage__c(
    API_Name__c='Test API',
    Call_Count__c=1,
    Usage_Date__c=Date.today()
);
insert usage;
System.debug('   ✓ Created: ' + usage.Id);

// Test 7: Platform Event
System.debug('\n7. ESPN_Sync_Event__e:');
ESPN_Sync_Event__e event = new ESPN_Sync_Event__e(
    League_ID__c='test',
    Event_Type__c='TEST',
    Sync_Status__c='Success'
);
Database.SaveResult sr = EventBus.publish(event);
System.debug('   ✓ Published: ' + sr.isSuccess());

// Test 8: Team Membership (without Team__c)
System.debug('\n8. Team_Membership__c:');
Team_Membership__c tm = new Team_Membership__c(
    Player__c=player.Id,
    Season__c=season.Id,
    Start_Date__c=Date.today()
);
insert tm;
tm = [SELECT Is_Current__c FROM Team_Membership__c WHERE Id=:tm.Id];
System.debug('   ✓ Created: ' + tm.Id);
System.debug('   ✓ Is_Current formula: ' + tm.Is_Current__c);

// Cleanup
delete new List<SObject>{tm, usage, error, config, award, comp, player, team, season};
System.debug('\n✅ ALL CORE OBJECTS VERIFIED SUCCESSFULLY!');
System.debug('\n📊 Deployed & Verified:');
System.debug('  - Season__c');
System.debug('  - Award__c (with relationships)');
System.debug('  - League_Config__c');
System.debug('  - ESPN_Sync_Error__c');
System.debug('  - API_Usage__c');
System.debug('  - ESPN_Sync_Event__e');
System.debug('  - Team_Membership__c (partial - missing Team__c field)');

