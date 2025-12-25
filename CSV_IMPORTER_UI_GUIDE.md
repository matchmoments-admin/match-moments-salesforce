# CSV Importer - UI Usage Guide

## 🎉 What's Deployed

All classes and components are now **DEPLOYED** to your Salesforce org:

✅ **Apex Classes**:
- `GenericCSVImporter` - Core import engine
- `NRLDataImportHelper` - NRL-specific helper
- `CSVImportController` - LWC backend controller

✅ **Lightning Web Component**:
- `csvImporter` - UI for CSV upload and import

## 🚀 How to Use the UI

### Step 1: Add Component to a Page

1. **Go to Setup** (⚙️ icon in top right)
2. **Quick Find**: Type "Lightning App Builder"
3. Click **"Lightning App Builder"**
4. Choose an option:
   - **New Page** → Create a new app page
   - **Edit an existing page** (Home, App Page, or Record Page)

5. **From the Components panel** (left side):
   - Scroll down or search for **"csvImporter"**
   - Drag and drop it onto your page canvas

6. **Save** and **Activate** the page

### Step 2: Navigate to the Component

1. Go to the page where you added the component
2. You'll see the **"CSV Data Importer"** card

## 📋 Using the Component

### Two Import Modes

#### **Mode 1: Generic Import** (Default)
Import any CSV into any Salesforce object with custom field mappings.

**Steps**:
1. **Select Import Mode**: Keep "Generic Import" selected
2. **Upload CSV**: Click "Select CSV File" and choose your file
3. **Select Target Object**: Choose the Salesforce object (e.g., Contact, Account)
4. **Map Fields**: For each CSV column, select which Salesforce field it maps to
5. **Optional**: Select an "External ID Field" for upsert (update or insert)
6. **Click "Import Data"**

#### **Mode 2: NRL Import** (Pre-configured)
Import NRL data using pre-configured mappings.

**Steps**:
1. **Select Import Mode**: Click "NRL Import (Pre-configured)"
2. **Upload CSV**: Select your `nrl_2024_test_data.csv` file
3. **Click "Import NRL Data"**
4. The system automatically handles all object types and relationships

### Import Results

After import, you'll see:
- ✅ **Success Box** (green) - Import succeeded
- ⚠️ **Warning Box** (yellow) - Partial success with errors
- 📊 **Statistics**:
  - Records Processed
  - Records Created
  - Records Updated
  - Records Failed
- ❌ **Error Details** - If any records failed

## 🎯 Example Workflows

### Example 1: Import Teams (Accounts)

1. Select **Generic Import**
2. Upload a CSV with columns: `TeamName, Sport, Venue`
3. Select **Account** as target object
4. Map fields:
   - `TeamName` → `Name`
   - `Sport` → `Sport__c`
   - `Venue` → `Venue_Name__c`
5. Click **Import Data**

### Example 2: Import Players with Team Lookup

1. First, ensure teams are already imported (see Example 1)
2. Upload a CSV with columns: `FirstName, LastName, TeamName, JerseyNumber`
3. Select **Contact** as target object
4. Map fields:
   - `FirstName` → `FirstName`
   - `LastName` → `LastName`
   - `JerseyNumber` → `Jersey_Number__c`
5. For team lookup (requires custom code - see advanced section)
6. Click **Import Data**

### Example 3: Import NRL Complete Dataset

1. Select **NRL Import (Pre-configured)**
2. Upload `nrl_2024_test_data.csv`
3. Click **Import NRL Data**
4. View results by object type (Seasons, Teams, Players, Matches, etc.)

## 🎨 UI Features

### Visual Feedback
- 🔵 **Blue Pills** - Show detected CSV columns
- 📝 **Field Mapping Grid** - Side-by-side CSV to Salesforce mapping
- 🔄 **Loading Spinner** - Shows during import
- ✅ **Success/Warning/Error Themes** - Color-coded results

### Buttons
- **Import Data** / **Import NRL Data** - Execute the import
- **Clear** - Reset everything and start over

## 📱 Where to Add the Component

### Recommended Locations

1. **Home Page**
   - Best for frequently used import tool
   - Always accessible from home

2. **Custom App Page**
   - Create a dedicated "Data Management" app page
   - Add multiple data tools together

3. **Utility Bar**
   - Quick access from any page
   - Pop-up panel without leaving current page

4. **Record Page**
   - If importing related to specific records
   - Example: Import players on Team detail page

## 🔧 Lightning App Builder Tips

### Creating a Dedicated Import Page

1. **Setup** → **Lightning App Builder** → **New**
2. **Page Type**: "App Page"
3. **Label**: "Data Import"
4. **Template**: "One Region"
5. Drag **csvImporter** to the main region
6. **Save** → **Activate**
7. **Add to App Navigation**:
   - Select your app (e.g., "Sports Management")
   - Click **Add page to app**
   - Make it visible

### Adding to Home Page

1. **Setup** → **Lightning App Builder**
2. Find and **Edit** "Home Page Default"
3. Drag **csvImporter** into your preferred section
4. **Save** and **Activate**

## 🎓 Quick Reference

| Task | Steps |
|------|-------|
| **Add to Home** | Setup → Lightning App Builder → Edit Home Page → Drag csvImporter |
| **Create New Page** | Setup → Lightning App Builder → New → App Page → Add csvImporter |
| **Import Teams** | Generic Mode → Upload CSV → Select Account → Map fields → Import |
| **Import NRL Data** | NRL Mode → Upload CSV → Import NRL Data |
| **Clear Form** | Click "Clear" button |

## 🆘 Troubleshooting

### Component Not Showing Up
- **Check**: Is the page activated?
- **Check**: Is the component in the right region?
- **Refresh** the browser

### Import Fails
- **Check CSV Format**: Must be comma-delimited
- **Check Picklist Values**: Must match exactly
- **Check Required Fields**: All required fields must be mapped
- **Check Lookups**: Parent records must exist first

### Field Not in List
- **Check**: Is the field editable?
- **Check**: Is the field accessible to your profile?
- **Auto-number fields**: Cannot be manually set

## 📊 Advanced: Custom Configuration

For developers who want to extend the component:

### Add Custom Objects
Edit `CSVImportController.getAvailableObjects()` to add more objects:

```apex
commonObjects.put('Custom_Object__c', 'Custom Objects');
```

### Add Lookup Support in UI
Currently, lookups require the NRL helper pattern. To add UI-based lookup configuration:
1. Add lookup field selection UI in HTML
2. Collect lookup configs in JavaScript
3. Pass to `importCSVData` method

## 🎯 Next Steps

1. **Test the Component**: Upload a small CSV file
2. **Create a Dedicated Page**: Set up a "Data Management" page
3. **Import Your Data**: Use NRL mode or generic mode
4. **Customize** (optional): Add more objects or features

## 📸 Screenshot Guide

Your UI should look like this:

```
┌─────────────────────────────────────────┐
│ CSV Data Importer                   🔲  │
├─────────────────────────────────────────┤
│ Import Mode:                            │
│ ⦿ Generic Import  ○ NRL Import          │
│                                          │
│ Select CSV File: [Choose File]          │
│                                          │
│ CSV Columns Detected (5)                │
│ [FirstName] [LastName] [Email] ...      │
│                                          │
│ Target Salesforce Object:               │
│ [Contact ▼]                              │
│                                          │
│ Field Mappings:                         │
│ CSV Column     → Salesforce Field       │
│ FirstName      → [FirstName ▼]          │
│ LastName       → [LastName ▼]           │
│ Email          → [Email ▼]              │
│                                          │
│ [Import Data]  [Clear]                  │
└─────────────────────────────────────────┘
```

---

**You're ready to import CSV data through the UI!** 🚀

For technical details, see `GENERIC_CSV_IMPORTER_GUIDE.md`

