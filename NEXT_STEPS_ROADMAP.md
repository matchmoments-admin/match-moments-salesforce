# Next Steps Roadmap - Post-Deployment Plan

**Date:** December 25, 2025  
**Current Status:** ✅ All changes committed and pushed  
**Deployment State:** Production-ready, ESPN API verified working

---

## 🎯 Executive Summary

Following the successful deployment of 12 new custom objects, migration to Match__c architecture, and resolution of FLS issues, the Einstein-AI Salesforce platform is now ready for the next phase of development. This roadmap outlines immediate actions, short-term priorities, medium-term enhancements, and long-term strategic initiatives.

---

## ⚡ Immediate Actions (This Week)

### 1. Verify Deployment in Salesforce Org
**Priority:** Critical  
**Estimated Time:** 30 minutes

**Tasks:**
- [ ] Run verification script: `sf apex run --file scripts/apex/verify-fls-fixed.apex --target-org brendan-dev-edition`
- [ ] Confirm all 12 new objects are queryable via SOQL
- [ ] Verify Match__c has all 20 custom fields visible in Setup UI
- [ ] Check permission sets assigned to appropriate users
- [ ] Test ESPN API integration still returns HTTP 200

**Success Criteria:**
✅ All verification scripts pass without errors  
✅ All SOQL queries execute successfully  
✅ No FLS errors in logs

---

### 2. Populate Season__c Records
**Priority:** Critical  
**Estimated Time:** 1 hour

**Why:** Season__c is a foundational object that Match__c, Team_Membership__c, and Award__c depend on via lookup relationships.

**Tasks:**
- [ ] Run script: `sf apex run --file scripts/apex/create-default-seasons.apex --target-org brendan-dev-edition`
- [ ] Create Season__c records for:
  - Men's Premier League 2025/26
  - Women's Super League 2025/26
  - NWSL 2025
  - WNBA 2025
  - Any other active competitions
- [ ] Verify Season__c.Status__c is set to "Active" for current seasons
- [ ] Link existing Competition__c records to appropriate Season__c

**Sample Apex:**
```apex
// Create Premier League 2025/26 Season
Season__c eplSeason = new Season__c(
    Season_Name__c = '2025/26',
    Start_Date__c = Date.newInstance(2025, 8, 15),
    End_Date__c = Date.newInstance(2026, 5, 24),
    Season_Type__c = 'Regular Season',
    Status__c = 'Active',
    Sport__c = 'Soccer'
);
insert eplSeason;

// Link to Competition
Competition__c epl = [SELECT Id FROM Competition__c WHERE ESPN_League_ID__c = 'eng.1' LIMIT 1];
epl.Season__c = eplSeason.Id;
update epl;
```

**Success Criteria:**
✅ 5+ Season__c records created  
✅ All active competitions linked to current season  
✅ Can query Season__c via SOQL without errors

---

### 3. Start Syncing to Match__c (Instead of Fixture__c)
**Priority:** High  
**Estimated Time:** 2 hours

**Why:** Match__c has 20 custom fields vs Fixture__c's limited fields, better ESPN alignment, and proper external ID for upserts.

**Tasks:**
- [ ] Update ESPNSyncService to target Match__c instead of Fixture__c
- [ ] Modify ESPNDataParser to map ESPN JSON to Match__c fields
- [ ] Update sport handlers (SoccerHandler, etc.) to use MatchesSelector
- [ ] Test sync with Premier League fixture
- [ ] Verify Match__c records created with all fields populated

**Code Changes Required:**
- `ESPNSyncService.cls` - Change DML operations from Fixture__c to Match__c
- `ESPNDataParser.cls` - Update field mappings
- `SoccerHandler.cls`, `NBAHandler.cls`, etc. - Use MatchesSelector instead of FixturesSelector

**Success Criteria:**
✅ Sync creates Match__c records instead of Fixture__c  
✅ All ESPN fields populated (ESPN_Event_ID__c, scores, venue, etc.)  
✅ No errors in debug logs

---

### 4. Configure League_Config__c for Automated Syncs
**Priority:** Medium  
**Estimated Time:** 1 hour

**Why:** League_Config__c enables scheduled, automated ESPN syncs without manual intervention.

**Tasks:**
- [ ] Create League_Config__c records for each competition
- [ ] Link to Competition__c via Master-Detail
- [ ] Set ESPN_League_ID__c (e.g., "eng.1" for Premier League)
- [ ] Configure sync frequency and priority
- [ ] Set up API quota limits
- [ ] Enable auto-retry for failed syncs

**Sample Apex:**
```apex
// Get Competition
Competition__c epl = [SELECT Id FROM Competition__c WHERE ESPN_League_ID__c = 'eng.1' LIMIT 1];

// Create League Config
League_Config__c eplConfig = new League_Config__c(
    Competition__c = epl.Id,
    ESPN_League_ID__c = 'eng.1',
    Is_Active__c = true,
    Sync_Frequency__c = 'Hourly',
    Priority__c = 1,
    API_Quota_Limit__c = 50,
    Auto_Retry__c = true,
    Max_Retries__c = 3,
    Include_Fixtures__c = true,
    Notification_Email__c = 'admin@matchmoments.com'
);
insert eplConfig;
```

**Success Criteria:**
✅ League_Config__c records created for all active competitions  
✅ Master-Detail relationship to Competition__c working  
✅ Can query League_Config__c with Competition__r fields

---

## 📅 Short Term (Next 1-2 Weeks)

### 5. Backfill Team_Membership__c Historical Data
**Priority:** High  
**Estimated Time:** 4 hours

**Why:** Team_Membership__c tracks historical player-team relationships, enabling transfer history and squad evolution analysis.

**Tasks:**
- [ ] Run script: `sf apex run --file scripts/apex/backfill-league-data.apex --target-org brendan-dev-edition`
- [ ] Create Team_Membership__c records for all current player rosters
- [ ] Set Season__c to current season
- [ ] Set Start_Date__c to season start or player join date
- [ ] Leave End_Date__c blank for current memberships
- [ ] Set Jersey_Number__c, Position__c from ESPN data
- [ ] Verify Is_Current__c formula returns true for active memberships

**Data Sources:**
- ESPN API roster endpoint
- Existing Contact (Player) records
- Existing Account (Team) records

**Success Criteria:**
✅ 500+ Team_Membership__c records created  
✅ All current players have active membership (End_Date__c = null)  
✅ Is_Current__c formula working correctly

---

### 6. Setup ESPN Sync Scheduler
**Priority:** High  
**Estimated Time:** 3 hours

**Reference:** See [ESPN_SYNC_SCHEDULER_GUIDE.md](ESPN_SYNC_SCHEDULER_GUIDE.md) for detailed instructions.

**Tasks:**
- [ ] Deploy OrgSchedulable class (already deployed)
- [ ] Deploy ESPNSyncQueueable and ESPNSyncBatchable (already deployed)
- [ ] Create Scheduled_Process__c records for each league
- [ ] Start scheduler: `OrgSchedulable.startScheduler()`
- [ ] Activate jobs for testing (15-minute frequency)
- [ ] Monitor first 24 hours of automated syncs
- [ ] Adjust frequencies based on API usage

**Sample Configuration:**
```apex
// NWSL Daily Teams & Rosters
insert new Scheduled_Process__c(
    ClassName__c = 'ESPNSyncQueueable',
    Type__c = 'Queueable Job',
    IsActive__c = true,
    Frequency__c = 1,
    Units__c = 'Days',
    Sport_Type__c = 'soccer',
    League_Code__c = 'usa.nwsl',
    Sync_Teams__c = true,
    Sync_Rosters__c = true,
    Sync_Fixtures__c = false,
    Max_API_Calls_Per_Run__c = 50,
    NextRunTime__c = Datetime.newInstance(Date.today().addDays(1), Time.newInstance(3, 0, 0, 0))
);
```

**Success Criteria:**
✅ OrgSchedulable running (60 scheduled jobs)  
✅ 5+ Scheduled_Process__c records configured  
✅ Jobs executing automatically and updating Last_Sync_Status__c  
✅ No API rate limit errors

---

### 7. Migrate Existing Fixture__c Data to Match__c (Optional)
**Priority:** Medium  
**Estimated Time:** 2 hours

**Why:** Consolidate all match data in Match__c for consistency. Only necessary if you want to maintain historical data in the new structure.

**Decision Required:** 
- **Option A**: Keep Fixture__c as-is for historical data, use Match__c for new data
- **Option B**: Migrate all 7 Fixture__c records to Match__c, deprecate Fixture__c

**If Option B:**
```apex
// Migration Script
List<Fixture__c> fixtures = [SELECT /* all fields */ FROM Fixture__c];
List<Match__c> matches = new List<Match__c>();

for (Fixture__c fix : fixtures) {
    Match__c match = new Match__c(
        ESPN_Event_ID__c = fix.ESPN_Event_ID__c,
        Match_Date__c = fix.Fixture_Date_Time__c,
        Status__c = fix.Status__c,
        Home_Score_Final__c = fix.Home_Score_Final__c,
        Away_Score_Final__c = fix.Away_Score_Final__c,
        Venue__c = fix.Venue__c
        // ... map all fields
    );
    matches.add(match);
}

insert matches;
```

**Success Criteria:**
✅ All Fixture__c data migrated to Match__c  
✅ Field values preserved correctly  
✅ Relationships maintained

---

### 8. Implement Award__c Import Service
**Priority:** Medium  
**Estimated Time:** 6 hours

**Why:** Award__c tracks player and team achievements, enabling awards dashboards and player profiles.

**Tasks:**
- [ ] Create AwardImportService class
- [ ] Implement ESPN API integration for awards data
- [ ] Parse award types: Player of the Month, Golden Boot, Team of the Year, etc.
- [ ] Create Award__c records with proper relationships to Player, Team, Season
- [ ] Handle different sports (soccer, basketball, cricket)
- [ ] Schedule nightly import job

**Award Types to Support:**
- Player of the Month/Year
- Golden Boot (Top Scorer)
- Golden Glove (Top Goalkeeper)
- Team Championships/Trophies
- Individual Season Awards

**Success Criteria:**
✅ AwardImportService class deployed  
✅ 100+ Award__c records created  
✅ Awards linked to correct Player, Team, Season, Competition

---

### 9. End-to-End Testing with New Architecture
**Priority:** High  
**Estimated Time:** 4 hours

**Tasks:**
- [ ] Test complete ESPN sync flow: Teams → Rosters → Matches
- [ ] Test Match__c FLS permissions with different user profiles
- [ ] Test Season__c relationships with Competition__c, Match__c
- [ ] Test Team_Membership__c creation and Is_Current__c formula
- [ ] Test League_Config__c Master-Detail to Competition__c
- [ ] Test ESPN_Sync_Error__c creation when sync fails
- [ ] Performance test: Sync 20 teams + 400 players + 10 matches

**Test Scenarios:**
1. **Happy Path**: Full sync succeeds, all objects populated
2. **API Failure**: ESPN returns 500, ESPN_Sync_Error__c created
3. **Duplicate Prevention**: Upsert on ESPN_Event_ID__c prevents duplicates
4. **FLS Enforcement**: Non-privileged user cannot see sensitive fields
5. **Relationship Integrity**: Deleting Season__c cascade behavior

**Success Criteria:**
✅ All test scenarios pass  
✅ No uncaught exceptions  
✅ Performance acceptable (<5 min for full sync)

---

## 🚀 Medium Term (Next Month)

### 10. Implement Match_Moment__c Sync from ESPN Commentary
**Priority:** High  
**Estimated Time:** 8 hours

**Why:** Match_Moment__c captures goals, cards, substitutions, and other key events for detailed match analysis.

**Tasks:**
- [ ] Enhance ESPNDataParser to parse commentary JSON
- [ ] Create MatchMomentService class
- [ ] Map ESPN event types to Match_Moment__c.Event_Type__c
- [ ] Link Match_Moment__c to Match__c, Player__c
- [ ] Capture timestamps (Clock_Time__c)
- [ ] Store event details (Score_After__c, Assist_By__c, etc.)

**Event Types:**
- Goal
- Yellow Card
- Red Card
- Substitution
- Penalty
- Own Goal
- VAR Decision

**Success Criteria:**
✅ Match_Moment__c records created for all major events  
✅ Events linked to correct Match__c and Player__c  
✅ Timestamps accurate

---

### 11. Real-Time Live Score Updates
**Priority:** Medium  
**Estimated Time:** 12 hours

**Why:** Live scores drive user engagement and enable real-time dashboards.

**Approach:**
- **Option A**: Platform Events (ESPN_Sync_Event__e) with Lightning component subscribers
- **Option B**: Scheduled job every 5 minutes during live matches
- **Option C**: Streaming API integration with ESPN

**Recommended:** Option B (Scheduled job) for simplicity and reliability.

**Tasks:**
- [ ] Create LiveScoreService class
- [ ] Implement "live matches" detection (Status__c = 'In Progress')
- [ ] Schedule job to run every 5 minutes
- [ ] Update Match__c.Home_Score_Final__c, Away_Score_Final__c
- [ ] Update Match__c.Current_Period__c
- [ ] Publish ESPN_Sync_Event__e for Lightning component refresh

**Success Criteria:**
✅ Scores update every 5 minutes during live matches  
✅ Lightning components refresh automatically  
✅ No performance degradation

---

### 12. Build Lightning Dashboards for Match Analytics
**Priority:** Medium  
**Estimated Time:** 8 hours

**Dashboards to Create:**
1. **League Overview**: Standings, top scorers, upcoming fixtures
2. **Team Performance**: Win/loss record, goals scored/conceded, form
3. **Player Stats**: Goals, assists, cards, minutes played
4. **Match History**: Recent results, head-to-head records
5. **Sync Health**: API usage, success rates, error trends

**Components:**
- Bar charts (goals per match)
- Line charts (form over time)
- Tables (standings, statistics)
- Gauges (API quota usage)

**Success Criteria:**
✅ 5 dashboards created  
✅ Real-time data from Match__c, Team_Membership__c, Award__c  
✅ Mobile-responsive design

---

### 13. Create REST APIs for Next.js Integration
**Priority:** High  
**Estimated Time:** 16 hours

**Why:** Enables frontend application to consume Salesforce data.

**API Endpoints to Create:**
```apex
@RestResource(urlMapping='/api/v1/matches/*')
global class MatchAPI {
    @HttpGet
    global static List<MatchDTO> getMatches() {
        // Return upcoming matches
    }
    
    @HttpGet
    global static MatchDetailDTO getMatchDetail() {
        // Return match with moments, lineups, stats
    }
}

@RestResource(urlMapping='/api/v1/teams/*')
global class TeamAPI {
    @HttpGet
    global static List<TeamDTO> getTeams() {
        // Return teams with standings
    }
    
    @HttpGet
    global static TeamDetailDTO getTeamDetail() {
        // Return team with roster, stats, fixtures
    }
}

@RestResource(urlMapping='/api/v1/players/*')
global class PlayerAPI {
    @HttpGet
    global static PlayerDetailDTO getPlayerDetail() {
        // Return player with stats, awards, history
    }
}
```

**Tasks:**
- [ ] Create DTO classes for data transfer
- [ ] Implement REST resource classes
- [ ] Add proper error handling
- [ ] Implement pagination for large datasets
- [ ] Add CORS headers for cross-origin requests
- [ ] Document API with OpenAPI/Swagger

**Success Criteria:**
✅ 10+ API endpoints functional  
✅ Proper HTTP status codes (200, 404, 500)  
✅ Response times <500ms  
✅ API documentation complete

---

## 🌟 Long Term (Next Quarter)

### 14. JWT Authentication for Secure API Access
**Priority:** High  
**Estimated Time:** 12 hours

**Why:** Secure authentication for Next.js frontend and third-party integrations.

**Implementation:**
- JWT token generation in Apex
- Token validation on each API request
- Token expiration and refresh logic
- Role-based access control (RBAC)

**Success Criteria:**
✅ JWT authentication working  
✅ Tokens expire after 1 hour  
✅ Refresh token flow implemented

---

### 15. Next.js Frontend Application
**Priority:** High  
**Estimated Time:** 80 hours

**Pages to Build:**
- Home: Featured matches, trending moments
- League: Standings, fixtures, top scorers
- Team: Roster, stats, upcoming matches
- Player: Profile, stats, awards, transfer history
- Match: Live scores, commentary, lineups, stats

**Tech Stack:**
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- React Query for data fetching
- Zustand for state management

**Success Criteria:**
✅ 10+ pages functional  
✅ Mobile-responsive  
✅ SEO optimized

---

### 16. Advanced Analytics with Einstein AI
**Priority:** Medium  
**Estimated Time:** 40 hours

**Use Cases:**
- Match outcome predictions
- Player performance forecasting
- Injury risk assessment
- Transfer value estimation
- Fan engagement predictions

**Success Criteria:**
✅ 3+ Einstein models trained  
✅ Predictions displayed in UI  
✅ >70% accuracy rate

---

### 17. Mobile App with Salesforce Mobile SDK
**Priority:** Low  
**Estimated Time:** 60 hours

**Features:**
- Live score notifications
- Match center with real-time updates
- Player profiles
- Standings and fixtures
- Offline mode

**Success Criteria:**
✅ iOS and Android apps published  
✅ 4+ star rating  
✅ 1000+ downloads

---

## 📊 Success Metrics & KPIs

### Technical Metrics
- **API Uptime**: >99.9%
- **Response Time**: <500ms for API calls
- **Sync Success Rate**: >95%
- **FLS Coverage**: 100%
- **Test Coverage**: >85%

### Business Metrics
- **Data Freshness**: Scores updated within 5 minutes
- **Match Coverage**: 500+ matches per month
- **Player Profiles**: 5000+ players tracked
- **User Engagement**: 50K+ API calls per day

---

## 🔧 Technical Debt & Maintenance

### Items to Address
1. **Test Coverage**: Write unit tests for new selectors, domains, services
2. **Error Handling**: Standardize error messages and logging
3. **Documentation**: Complete JSDoc for all Apex classes
4. **Performance**: Optimize SOQL queries with selective fields
5. **Security**: Implement CRUD/FLS checks in all services

### Monthly Tasks
- Review ESPN_Sync_Error__c records and fix recurring issues
- Audit API_Usage__c and adjust rate limits
- Update Season__c records as seasons progress
- Archive completed seasons
- Review and update documentation

---

## 🎯 Prioritization Framework

**Critical (Do First):**
- Verify deployment
- Populate Season__c
- Start syncing to Match__c
- Configure League_Config__c

**High (Next 2 Weeks):**
- Backfill Team_Membership__c
- Setup ESPN sync scheduler
- Implement Award__c import
- End-to-end testing

**Medium (Next Month):**
- Match_Moment__c sync
- Live score updates
- Analytics dashboards
- REST APIs

**Low (Next Quarter):**
- Einstein AI
- Mobile app

---

## 📞 Support & Resources

### Documentation
- [ESPN_SYNC_SCHEDULER_GUIDE.md](ESPN_SYNC_SCHEDULER_GUIDE.md)
- [FINAL_STATUS_REPORT.md](FINAL_STATUS_REPORT.md)
- [CHANGE_SUMMARY_2025-12-25.md](CHANGE_SUMMARY_2025-12-25.md)

### Test Scripts
- `scripts/apex/verify-fls-fixed.apex`
- `scripts/apex/create-default-seasons.apex`
- `scripts/apex/backfill-league-data.apex`
- `scripts/apex/test-epl-sync-with-fixture.apex`

### Verification Commands
```bash
# Check deployment status
git log --oneline -5

# Verify FLS
sf apex run --file scripts/apex/verify-fls-fixed.apex --target-org brendan-dev-edition

# Test ESPN sync
sf apex run --file scripts/apex/test-epl-sync-with-fixture.apex --target-org brendan-dev-edition
```

---

**Created:** December 25, 2025  
**Last Updated:** December 25, 2025  
**Status:** 🟢 Ready for Implementation  
**Next Review:** Weekly sprint planning


