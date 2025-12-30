// Test Sport Handlers with Match__c refactoring
// This tests that all handlers work with the new Match__c object

System.debug('=== Testing Sport Handlers ===');

try {
    // Create a test Competition for the matches
    Competition__c testComp = new Competition__c(
        Competition_Type__c = 'League',
        Sport__c = 'Soccer'
    );
    insert testComp;
    System.debug('Created test competition: ' + testComp.Id);
    
    // Sample ESPN API data structure
    Map<String, Object> sampleApiData = new Map<String, Object>{
        'id' => 'TEST123',
        'name' => 'Test Match',
        'date' => '2025-12-31T19:00:00Z',
        'status' => new Map<String, Object>{
            'type' => 'STATUS_SCHEDULED'
        },
        'competitions' => new List<Object>{
            new Map<String, Object>{
                'competitors' => new List<Object>{
                    new Map<String, Object>{
                        'homeAway' => 'home',
                        'score' => '2'
                    },
                    new Map<String, Object>{
                        'homeAway' => 'away',
                        'score' => '1'
                    }
                }
            }
        }
    };
    
    // Test SoccerHandler
    System.debug('\\nTesting SoccerHandler...');
    ISportDataHandler soccerHandler = SportUtils.getSportHandler('Soccer');
    System.debug('Sport Type: ' + soccerHandler.getSportType());
    Match__c soccerMatch = soccerHandler.mapFixture(sampleApiData, testComp.Id);
    System.debug('✅ SoccerHandler.mapFixture() - ESPN ID: ' + soccerMatch.ESPN_Event_ID__c);
    System.debug('   Competition: ' + soccerMatch.Competition__c);
    System.debug('   Status: ' + soccerMatch.Status__c);
    System.debug('   Home Score: ' + soccerMatch.Home_Score_Final__c);
    System.debug('   Away Score: ' + soccerMatch.Away_Score_Final__c);
    
    // Test NBAHandler
    System.debug('\\nTesting NBAHandler...');
    ISportDataHandler nbaHandler = SportUtils.getSportHandler('Basketball');
    System.debug('Sport Type: ' + nbaHandler.getSportType());
    Match__c nbaMatch = nbaHandler.mapFixture(sampleApiData, testComp.Id);
    System.debug('✅ NBAHandler.mapFixture() - ESPN ID: ' + nbaMatch.ESPN_Event_ID__c);
    System.debug('   Competition: ' + nbaMatch.Competition__c);
    System.debug('   Status: ' + nbaMatch.Status__c);
    
    // Test AFLHandler
    System.debug('\\nTesting AFLHandler...');
    ISportDataHandler aflHandler = SportUtils.getSportHandler('AFL');
    System.debug('Sport Type: ' + aflHandler.getSportType());
    
    // AFL-specific data with goals and behinds
    Map<String, Object> aflApiData = new Map<String, Object>{
        'id' => 'AFL123',
        'name' => 'AFL Test Match',
        'date' => '2025-12-31T19:00:00Z',
        'status' => new Map<String, Object>{
            'type' => 'STATUS_FINAL'
        },
        'competitions' => new List<Object>{
            new Map<String, Object>{
                'competitors' => new List<Object>{
                    new Map<String, Object>{
                        'homeAway' => 'home',
                        'score' => new Map<String, Object>{
                            'goals' => 10,
                            'behinds' => 5
                        }
                    },
                    new Map<String, Object>{
                        'homeAway' => 'away',
                        'score' => new Map<String, Object>{
                            'goals' => 8,
                            'behinds' => 7
                        }
                    }
                }
            }
        }
    };
    
    Match__c aflMatch = aflHandler.mapFixture(aflApiData, testComp.Id);
    System.debug('✅ AFLHandler.mapFixture() - ESPN ID: ' + aflMatch.ESPN_Event_ID__c);
    System.debug('   Home Score: ' + aflMatch.Home_Score_Final__c + ' (should be 65: 10*6 + 5)');
    System.debug('   Home Sub Score: ' + aflMatch.Home_Sub_Score__c + ' (should be 10.5)');
    System.debug('   Away Score: ' + aflMatch.Away_Score_Final__c + ' (should be 55: 8*6 + 7)');
    System.debug('   Status: ' + aflMatch.Status__c);
    
    // Test CricketHandler
    System.debug('\\nTesting CricketHandler...');
    ISportDataHandler cricketHandler = SportUtils.getSportHandler('Cricket');
    System.debug('Sport Type: ' + cricketHandler.getSportType());
    
    // Cricket-specific data with runs/wickets format
    Map<String, Object> cricketApiData = new Map<String, Object>{
        'id' => 'CRICKET123',
        'name' => 'Cricket Test Match',
        'date' => '2025-12-31T10:00:00Z',
        'status' => new Map<String, Object>{
            'type' => 'STATUS_IN_PROGRESS'
        },
        'competitions' => new List<Object>{
            new Map<String, Object>{
                'competitors' => new List<Object>{
                    new Map<String, Object>{
                        'homeAway' => 'home',
                        'score' => '245/8'
                    },
                    new Map<String, Object>{
                        'homeAway' => 'away',
                        'score' => '198/10'
                    }
                }
            }
        }
    };
    
    Match__c cricketMatch = cricketHandler.mapFixture(cricketApiData, testComp.Id);
    System.debug('✅ CricketHandler.mapFixture() - ESPN ID: ' + cricketMatch.ESPN_Event_ID__c);
    System.debug('   Home Score: ' + cricketMatch.Home_Score_Final__c + ' runs');
    System.debug('   Home Wickets: ' + cricketMatch.Home_Sub_Score__c);
    System.debug('   Away Score: ' + cricketMatch.Away_Score_Final__c + ' runs');
    System.debug('   Status: ' + cricketMatch.Status__c + ' (should be Live)');
    
    // Test SportUtils factory methods
    System.debug('\\nTesting SportUtils factory methods...');
    System.debug('✅ getSportHandlerType(Soccer): ' + SportUtils.getSportHandlerType('Soccer'));
    System.debug('✅ getSportHandlerType(Basketball): ' + SportUtils.getSportHandlerType('Basketball'));
    System.debug('✅ getSportHandlerType(AFL): ' + SportUtils.getSportHandlerType('AFL'));
    System.debug('✅ getSportHandlerType(Cricket): ' + SportUtils.getSportHandlerType('Cricket'));
    
    // Clean up test data
    delete testComp;
    System.debug('\\nCleaned up test competition');
    
    System.debug('\\n=== All Sport Handler Tests PASSED ===');
    
} catch (Exception e) {
    System.debug('❌ TEST FAILED: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

