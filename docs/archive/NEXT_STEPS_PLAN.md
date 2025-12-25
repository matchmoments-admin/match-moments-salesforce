# Next Steps Plan - After FLS Update

**Current Status:** Match__c fields exist but lack FLS permissions  
**Action Required:** Update permission sets, then proceed with testing  
**Estimated Time:** 30-45 minutes total

---

## Phase 1: Update FLS Permissions ⏳ (5-10 minutes)

### Tasks:
1. ✅ Update ESPN Internal Users permission set
   - Setup → Permission Sets → ESPN Internal Users
   - Add Match object permissions (Read, Create, Edit)
   - Add FLS for all 20 Match__c fields
   - Save

2. ✅ Update ESPN Scheduler Admin permission set
   - Setup → Permission Sets → ESPN Scheduler Admin
   - Add Match object permissions (Read, Create, Edit)
   - Add FLS for all 20 Match__c fields
   - Save

### Reference:
- **Guide:** `FLS_UPDATE_GUIDE.md`
- **Fields to enable:** All 20 custom fields (list in guide)

---

## Phase 2: Verify FLS Update ✅ (2-3 minutes)

### Script to Run:
```bash
sf apex run --file scripts/apex/verify-fls-fixed.apex --target-org brendan-dev-edition
```

### Expected Output:
```
✅ Field count looks good! (29+ fields)
✅ All 15 ESPN fields accessible
✅ SOQL query successful!
🎉 SUCCESS! FLS permissions correctly configured
```

### If Failed:
- Review permission set settings
- Ensure all fields have Read and Edit access
- Check user has permission set assigned
- Re-run verification

---

## Phase 3: Update ESPN Sync Code 🔧 (10-15 minutes)

### Files to Update:

**1. ESPNSyncService.cls**
- Update `syncFixturesForDate()` method
- Change from `Fixture__c` to `Match__c`
- Update field names (Fixture_Date_Time__c → Match_Date_Time__c)

**2. ESPNDataParser.cls**
- Update `parseFixturesToMatches()` method (if exists)
- Ensure ESPN_Event_ID__c is used as External ID
- Map all ESPN response fields to Match__c

**3. Test Scripts**
- Update `test-epl-sync-with-fixture.apex` → rename to `test-epl-sync-with-match.apex`
- Change all Fixture__c references to Match__c
- Update SOQL queries

### Verification:
```apex
// Quick compile check
System.debug('Testing Match__c references...');
Match__c test = new Match__c(
    ESPN_Event_ID__c = 'test-123',
    Home_Score_Final__c = 2,
    Away_Score_Final__c = 1,
    Venue__c = 'Test Stadium'
);
System.debug('✅ Match__c fields accessible in code');
```

---

## Phase 4: Run Premier League 2025/26 Sync Test 🎯 (10-15 minutes)

### Test Script:
```bash
sf apex run --file scripts/apex/test-epl-sync-with-match.apex --target-org brendan-dev-edition
```

### Expected Results:
- ✅ 20 Premier League teams synced to Account
- ✅ 5-10 fixtures synced to Match__c (not Fixture__c)
- ✅ ESPN_Event_ID__c populated as External ID
- ✅ All score, venue, and metadata fields populated
- ✅ Match__c.Competition__c linked to correct Competition

### What to Test:
1. **Teams Sync**
   ```apex
   List<Account> teams = [
       SELECT Name, ESPN_Team_ID__c, Abbreviation__c
       FROM Account
       WHERE ESPN_Team_ID__c != null
       ORDER BY Name
   ];
   // Expected: 20+ teams including Arsenal, Liverpool, Man City
   ```

2. **Matches Sync**
   ```apex
   List<Match__c> matches = [
       SELECT ESPN_Event_ID__c, Home_Team__r.Name, Away_Team__r.Name,
              Home_Score_Final__c, Away_Score_Final__c, Venue__c,
              Match_Date_Time__c, Status__c
       FROM Match__c
       WHERE Competition__r.ESPN_League_ID__c = 'eng.1'
       ORDER BY Match_Date_Time__c
   ];
   // Expected: 5-10 EPL matches with complete data
   ```

3. **Data Quality**
   - ESPN_Event_ID__c is unique and populated
   - Scores are numeric and accurate
   - Venues are populated
   - Teams are correctly linked

---

## Phase 5: Comprehensive Verification 📊 (5 minutes)

### Verification Queries:

```apex
// 1. Check Match__c record count
Integer matchCount = [SELECT COUNT() FROM Match__c];
System.debug('Total Match__c records: ' + matchCount);

// 2. Verify all fields populated
List<Match__c> sampleMatches = [
    SELECT Id, Name, ESPN_Event_ID__c,
           Home_Team__r.Abbreviation__c, Away_Team__r.Abbreviation__c,
           Home_Score_Final__c, Away_Score_Final__c, Display_Score__c,
           Venue__c, Attendance__c, Referee__c,
           Current_Period__c, Match_Stats_JSON__c,
           Neutral_Venue__c, Season__c, Winner__c,
           Match_Date_Time__c, Status__c,
           Competition__r.Name
    FROM Match__c
    WHERE ESPN_Event_ID__c != null
    LIMIT 5
];

for (Match__c m : sampleMatches) {
    System.debug('Match: ' + m.Home_Team__r.Abbreviation__c + ' vs ' + 
                 m.Away_Team__r.Abbreviation__c);
    System.debug('  Score: ' + m.Display_Score__c);
    System.debug('  Venue: ' + m.Venue__c);
    System.debug('  ESPN ID: ' + m.ESPN_Event_ID__c);
    System.debug('  Competition: ' + m.Competition__r.Name);
}

// 3. Verify External ID works for upserts
Match__c testUpsert = new Match__c(
    ESPN_Event_ID__c = sampleMatches[0].ESPN_Event_ID__c,
    Home_Score_Final__c = 3,
    Away_Score_Final__c = 2
);
upsert testUpsert Match__c.ESPN_Event_ID__c;
System.debug('✅ Upsert by External ID working');
```

---

## Phase 6: Update Documentation 📝 (5 minutes)

### Documents to Update:

1. **ESPN_SYNC_TEST_RESULTS_2025-12-24.md**
   - Correct the "Known Limitations" section
   - Change from "fields don't exist" to "FLS issue - now resolved"
   - Update with successful Match__c sync results

2. **FLS_VS_MISSING_FIELDS_ANALYSIS.md**
   - Add resolution section
   - Document the fix applied
   - Include before/after test results

3. **IMPLEMENTATION_SUMMARY_2025-12-24.md**
   - Update final status
   - Mark FLS issue as resolved
   - Add Match__c sync success results

4. **Create: MATCH_SYNC_SUCCESS_REPORT.md**
   - New document showing successful Match__c sync
   - Premier League 2025/26 data results
   - All fields verified working

---

## Success Criteria ✅

Before marking complete, verify:
- [ ] All 15 ESPN fields visible in Schema.describe()
- [ ] SOQL queries work without errors
- [ ] Match__c records created from ESPN API
- [ ] ESPN_Event_ID__c populated as External ID
- [ ] Home/Away scores, venue, etc. all populated
- [ ] Upsert by ESPN_Event_ID__c works correctly
- [ ] No "No such column" errors
- [ ] Documentation updated with success results

---

## Rollback Plan 🔄

If issues arise:
1. **Code Changes:** Revert ESPN sync services to use Fixture__c
2. **Data:** Match__c records can be deleted (no dependencies yet)
3. **FLS:** Can be removed from permission sets if needed
4. **Fallback:** Fixture__c still exists with all data intact

---

## Timeline Summary

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Update FLS Permissions | 5-10 min | 🔄 In Progress |
| 2 | Verify FLS | 2-3 min | ⏳ Pending |
| 3 | Update ESPN Sync Code | 10-15 min | ⏳ Pending |
| 4 | Run EPL Sync Test | 10-15 min | ⏳ Pending |
| 5 | Comprehensive Verification | 5 min | ⏳ Pending |
| 6 | Update Documentation | 5 min | ⏳ Pending |
| **Total** | **Complete Implementation** | **30-45 min** | **0% Complete** |

---

## Next Immediate Action 🎯

**RIGHT NOW:**
1. Open Setup in Salesforce
2. Navigate to Permission Sets
3. Follow `FLS_UPDATE_GUIDE.md` instructions
4. Update ESPN Internal Users permission set
5. Come back here when done, run verification script

**Command to run after FLS update:**
```bash
sf apex run --file scripts/apex/verify-fls-fixed.apex --target-org brendan-dev-edition
```

---

## Support Files Created

- ✅ `FLS_UPDATE_GUIDE.md` - Step-by-step FLS update instructions
- ✅ `scripts/apex/verify-fls-fixed.apex` - Verification script
- ✅ `scripts/apex/check-and-fix-fls.apex` - FLS diagnostic script
- ✅ `NEXT_STEPS_PLAN.md` - This file

---

**Plan Created:** December 24, 2025  
**Estimated Completion:** 30-45 minutes from FLS update  
**Current Blocker:** FLS permissions (manual UI update required)  
**Next Milestone:** Verify FLS, then proceed to Match__c sync testing

