# Fix: Deploy Missing Match__c Fields

## Problem
`Match__c` object exists but is missing 15 critical fields needed for ESPN sync.

## Quick Fix: Manual Field Creation

### Step 1: Go to Setup
1. Click the gear icon (⚙️) → Setup
2. In Quick Find, search for "Object Manager"
3. Click "Object Manager"
4. Find and click "Match"

### Step 2: Create Missing Fields

Click "Fields & Relationships" → "New" and create these fields:

#### 1. ESPN_Event_ID__c (CRITICAL - Required for sync)
- **Data Type:** Text
- **Length:** 50
- **Field Label:** ESPN Event ID
- **Field Name:** ESPN_Event_ID
- **External ID:** ✅ Checked
- **Unique:** ✅ Checked (Case Insensitive)
- **Required:** ❌ Not checked

#### 2. Home_Score_Final__c
- **Data Type:** Number
- **Length:** 3
- **Decimal Places:** 0
- **Field Label:** Home Score Final
- **Field Name:** Home_Score_Final

#### 3. Away_Score_Final__c
- **Data Type:** Number
- **Length:** 3
- **Decimal Places:** 0
- **Field Label:** Away Score Final
- **Field Name:** Away_Score_Final

#### 4. Venue__c
- **Data Type:** Text
- **Length:** 255
- **Field Label:** Venue
- **Field Name:** Venue

#### 5. Attendance__c
- **Data Type:** Number
- **Length:** 10
- **Decimal Places:** 0
- **Field Label:** Attendance
- **Field Name:** Attendance

#### 6. Broadcast_URL__c
- **Data Type:** URL
- **Field Label:** Broadcast URL
- **Field Name:** Broadcast_URL

#### 7. Current_Period__c
- **Data Type:** Text
- **Length:** 50
- **Field Label:** Current Period
- **Field Name:** Current_Period

#### 8. Match_Stats_JSON__c
- **Data Type:** Long Text Area
- **Length:** 131072
- **Visible Lines:** 5
- **Field Label:** Match Stats JSON
- **Field Name:** Match_Stats_JSON

#### 9. Referee__c
- **Data Type:** Text
- **Length:** 255
- **Field Label:** Referee
- **Field Name:** Referee

#### 10. Home_Sub_Score__c
- **Data Type:** Number
- **Length:** 3
- **Decimal Places:** 0
- **Field Label:** Home Sub Score
- **Field Name:** Home_Sub_Score

#### 11. Away_Sub_Score__c
- **Data Type:** Number
- **Length:** 3
- **Decimal Places:** 0
- **Field Label:** Away Sub Score
- **Field Name:** Away_Sub_Score

#### 12. Neutral_Venue__c
- **Data Type:** Checkbox
- **Field Label:** Neutral Venue
- **Field Name:** Neutral_Venue
- **Default:** Unchecked

#### 13. Season__c
- **Data Type:** Lookup Relationship
- **Related To:** Season
- **Field Label:** Season
- **Field Name:** Season

#### 14. Winner__c
- **Data Type:** Lookup Relationship
- **Related To:** Account
- **Field Label:** Winner
- **Field Name:** Winner

#### 15. Display_Score__c
- **Data Type:** Formula (Text)
- **Field Label:** Display Score
- **Field Name:** Display_Score
- **Formula:**
```
IF(
  AND(NOT(ISBLANK(Home_Score_Final__c)), NOT(ISBLANK(Away_Score_Final__c))),
  TEXT(Home_Score_Final__c) & " - " & TEXT(Away_Score_Final__c),
  "TBD"
)
```

### Step 3: Verify Fields
After creating all fields, run this test:

```apex
// Test query
List<Match__c> test = [SELECT ESPN_Event_ID__c, Home_Score_Final__c, 
                       Away_Score_Final__c, Venue__c 
                       FROM Match__c LIMIT 1];
System.debug('✅ Fields are accessible!');
```

### Step 4: Test ESPN Sync
Run the test script:

```bash
sfdx apex run --target-org brendan-dev-edition --file scripts/apex/simple-espn-test.apex
```

---

## Alternative: Deploy via Metadata API

If manual creation is too tedious, you can try this command:

```bash
# Force deploy all Match__c fields
cd /Users/brendan.milton/agent-force-learning/Einstein-AI

# Deploy each field individually
for field in ESPN_Event_ID__c Home_Score_Final__c Away_Score_Final__c Venue__c Attendance__c Broadcast_URL__c Current_Period__c Match_Stats_JSON__c Referee__c Home_Sub_Score__c Away_Sub_Score__c Neutral_Venue__c Season__c Winner__c Display_Score__c; do
  echo "Deploying $field..."
  sfdx project deploy start --target-org brendan-dev-edition \
    --metadata "CustomField:Match__c.$field" \
    --ignore-conflicts
done
```

---

## Verification Checklist

After deploying fields, verify:

- [ ] Can query `ESPN_Event_ID__c` from Match__c
- [ ] Can query score fields (`Home_Score_Final__c`, `Away_Score_Final__c`)
- [ ] Can query `Venue__c`
- [ ] ESPN sync service runs without errors
- [ ] Match__c records are created with ESPN data
- [ ] All 20 fields show in Object Manager → Match → Fields & Relationships

---

## Expected Result

After fixing, you should be able to run:

```apex
Competition__c comp = new Competition__c(
    ESPN_League_ID__c = 'eng.1',
    Sport__c = 'Soccer',
    Season_Year__c = '2024-25',
    Status__c = 'Active'
);
insert comp;

Integer teams = ESPNSyncService.syncLeagueTeams('soccer', 'eng.1');
Integer fixtures = ESPNSyncService.syncFixturesForDate('soccer', 'eng.1', Date.today(), comp.Id);

System.debug('Teams: ' + teams);
System.debug('Fixtures: ' + fixtures);

// Verify data
List<Match__c> matches = [SELECT ESPN_Event_ID__c, Home_Team__r.Name, 
                          Away_Team__r.Name, Home_Score_Final__c, 
                          Away_Score_Final__c, Venue__c
                          FROM Match__c LIMIT 5];

for (Match__c m : matches) {
    System.debug(m.Home_Team__r.Name + ' vs ' + m.Away_Team__r.Name + 
                 ' at ' + m.Venue__c);
}
```

And see actual Premier League data!

---

**Time to Complete:** 15-20 minutes (manual) or 5 minutes (script)  
**Priority:** CRITICAL - Required for ESPN sync to work

