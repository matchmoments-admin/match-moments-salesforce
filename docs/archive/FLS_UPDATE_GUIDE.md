# Match__c FLS Update Guide

**Issue:** Match__c fields exist but lack Field-Level Security permissions  
**Solution:** Add FLS to ESPN permission sets  
**Time Required:** 5-10 minutes

---

## 🎯 **Step-by-Step Instructions**

### Permission Set 1: ESPN Internal Users

1. **Navigate to Permission Set**
   - Setup → Permission Sets
   - Click **ESPN Internal Users**

2. **Add Object Permissions**
   - Click **Object Settings**
   - Click **Match** (scroll to find it)
   - Click **Edit**
   - Under "Object Permissions":
     - ✅ Check **Read**
     - ✅ Check **Create**
     - ✅ Check **Edit**
     - ✅ Check **Delete** (optional)
     - ✅ Check **View All** (optional, for admins)
     - ✅ Check **Modify All** (optional, for admins)

3. **Add Field-Level Security**
   - Scroll down to "Field Permissions"
   - Check **Read Access** and **Edit Access** for ALL these fields:
   
   **ESPN Sync Critical Fields:**
   - ✅ Attendance
   - ✅ Away Score Final
   - ✅ Away Sub Score
   - ✅ Broadcast URL
   - ✅ Current Period
   - ✅ Display Score (read-only, formula field)
   - ✅ **ESPN Event ID** ⚠️ (CRITICAL - External ID)
   - ✅ Home Score Final
   - ✅ Home Sub Score
   - ✅ Match Stats JSON
   - ✅ Neutral Venue
   - ✅ Referee
   - ✅ Season
   - ✅ Venue
   - ✅ Winner
   
   **Also check these existing fields:**
   - ✅ Away Team
   - ✅ Competition
   - ✅ Home Team
   - ✅ Match Date Time
   - ✅ Status

4. **Save Changes**
   - Click **Save** at bottom of page

---

### Permission Set 2: ESPN Scheduler Admin

Repeat the same process for **ESPN Scheduler Admin**:
1. Setup → Permission Sets → ESPN Scheduler Admin
2. Object Settings → Match → Edit
3. Check all Object Permissions
4. Check all Field Permissions (same list as above)
5. Save

---

## ✅ **Verification After Update**

Run this script to verify FLS is working:

```apex
// scripts/apex/verify-fls-fixed.apex

System.debug('=== VERIFYING FLS UPDATE ===');

// Test 1: Check field accessibility
Schema.SObjectType matchType = Schema.getGlobalDescribe().get('Match__c');
Map<String, Schema.SObjectField> fields = matchType.getDescribe().fields.getMap();

System.debug('Fields visible: ' + fields.size());
System.debug('Should be 29+ (20 custom + 9 system)');

// Test 2: Check critical ESPN field
if (fields.containsKey('espn_event_id__c')) {
    Schema.DescribeFieldResult field = fields.get('espn_event_id__c').getDescribe();
    System.debug('✅ ESPN_Event_ID__c is visible');
    System.debug('   - Accessible: ' + field.isAccessible());
    System.debug('   - Createable: ' + field.isCreateable());
    System.debug('   - Updateable: ' + field.isUpdateable());
    
    if (field.isAccessible() && field.isCreateable()) {
        System.debug('✅ FLS UPDATE SUCCESSFUL!');
    } else {
        System.debug('⚠️ Field visible but not accessible - check permissions');
    }
} else {
    System.debug('❌ ESPN_Event_ID__c still not visible');
}

// Test 3: Try a SOQL query
try {
    List<Match__c> test = [
        SELECT Id, ESPN_Event_ID__c, Home_Score_Final__c, Venue__c
        FROM Match__c
        LIMIT 1
    ];
    System.debug('✅ SOQL query successful!');
    System.debug('   Records found: ' + test.size());
} catch (Exception e) {
    System.debug('❌ SOQL query failed: ' + e.getMessage());
}

System.debug('');
System.debug('=== VERIFICATION COMPLETE ===');
```

Expected output after fix:
```
Fields visible: 29
✅ ESPN_Event_ID__c is visible
   - Accessible: true
   - Createable: true
   - Updateable: true
✅ FLS UPDATE SUCCESSFUL!
✅ SOQL query successful!
   Records found: 0
```

---

## 🚨 **Important Notes**

1. **Master-Detail Field:** Competition__c is master-detail, so Match__c automatically inherits sharing from Competition__c

2. **Formula Field:** Display_Score__c is read-only, only check "Read Access"

3. **External ID:** ESPN_Event_ID__c is critical - this is how we upsert matches from ESPN API

4. **System Administrator:** Even System Administrators respect FLS, so permission sets must have FLS granted

---

## 🔄 **If Permission Sets Don't Exist**

If ESPN permission sets weren't deployed, you can either:

### Option A: Add FLS to System Administrator Profile
1. Setup → Profiles → System Administrator
2. Object Settings → Match → Edit
3. Add all field permissions
4. Save

### Option B: Create New Permission Set
1. Setup → Permission Sets → New
2. Label: "Match Object Access"
3. License: Salesforce
4. Save
5. Add Match object and field permissions
6. Assign to your user

---

## ⚡ **Quick Checklist**

Before proceeding to next steps, verify:
- [ ] ESPN Internal Users permission set updated with Match FLS
- [ ] ESPN Scheduler Admin permission set updated with Match FLS
- [ ] All 20 custom fields have Read and Edit access
- [ ] Verification script runs successfully
- [ ] SOQL queries work without "No such column" errors

---

**Time to Complete:** 5-10 minutes  
**Impact:** Enables ESPN sync to Match__c object  
**Priority:** High - Required for next steps

