# Match Moments - Salesforce Sports CRM Platform

A comprehensive Salesforce-based sports content management and revenue platform focused on women's sports engagement, social sharing, and multi-sport statistics tracking.

## 🎯 Project Overview

Match Moments is an enterprise-grade Salesforce application that enables sports organizations, leagues, and media companies to:

- 📊 **Track live sports data** from ESPN API across multiple sports (Soccer, Cricket, Basketball, Rugby, AFL, Tennis)
- 📱 **Share viral moments** across social platforms with built-in engagement tracking
- 💰 **Manage revenue streams** with a 60% focus on women's sports content
- 🏆 **Aggregate statistics** for teams, players, and competitions
- 🤝 **Track partnerships** including sponsorships, media licenses, and league deals
- 📈 **Monitor KPIs** with MRR/ARR tracking and gender-focused analytics

### Why Match Moments?

**Women's Sports Focus (60% Revenue Target):**
- Women's sports is the fastest-growing sports market
- 65% of viral sports moments are from women's competitions
- Sponsors pay 20% premium for women's sports access
- Strategic differentiation in underserved market

---

## ⚡ Key Features

### 1. Multi-Sport ESPN Integration
- Real-time fixture data synchronization
- Team, player, and competition management
- Live commentary and event tracking
- Quick Actions for manual sync on Fixture__c and Competition__c

### 2. Social Sharing Platform
- **socialShareWidget LWC**: Share to Twitter, Facebook, LinkedIn, WhatsApp
- **momentDetailPage LWC**: Public-facing moment display pages
- Automatic engagement tracking (shares, views, clicks)
- Viral score calculation and trending detection
- QR code generation for offline sharing

### 3. Advanced Statistics
- **Team_Season_Stats__c**: 32+ fields (wins, losses, goals, points, rankings)
- **Player_Season_Stats__c**: 40+ fields (goals, assists, cards, playing time)
- Multi-sport support (soccer, cricket, basketball, rugby/AFL)
- Automatic aggregation from live match data

### 4. Revenue Management (Phase 2E)
**7 Revenue Streams Tracked:**
1. **Subscriptions** ($660K target) - Premium, Creator, Team tiers
2. **Advertising** ($840K) - Display, video, native ads
3. **Sponsorships** ($100K) - Brand partnerships with 20% women's premium
4. **Media Licensing** ($50K) - Content and data rights
5. **League Partnerships** ($30K) - Official data provider deals
6. **Team Portals** ($180K) - Bronze/Silver/Gold team subscriptions
7. **API Access** ($24K) - Developer integrations
8. **Affiliate Revenue** ($36K) - Commission tracking

**Target: $1.92M ARR (60% from Women's Sports)**

### 5. FFLib Enterprise Architecture
- **Application Factory Pattern**: Centralized dependency injection
- **Unit of Work Pattern**: Transactional data management
- **Selector Pattern**: 15+ query classes with proper FLS
- **Domain Pattern**: 12+ domain classes with business logic
- **Service Pattern**: 8+ service implementations

---

## 📊 Implementation Status

| Phase | Description | Status | Completion |
|-------|-------------|--------|------------|
| **2A** | Statistics Foundation | ✅ Complete | 100% |
| **2B** | Social Sharing Platform | ✅ Complete | 100% |
| **2C** | FFLib Architecture | ✅ Complete | 100% |
| **2D** | Fixture Integration | ✅ Complete | 100% |
| **2E** | Revenue & Sales CRM | 🚧 In Progress | 50% |

**Overall Progress:** ~90% complete

### Phase 2E: Revenue Implementation Details

**Completed (✅):**
- 109 custom fields across Lead, Opportunity, Account objects
- 4 custom objects: Revenue_Stream__c, Sponsorship__c, Media_License__c, League_Partnership__c
- 65 additional custom fields across revenue objects
- Field Level Security (FLS) for all 174 fields
- Gender tracking on all revenue objects
- Women's sports premium tracking (20% uplift)
- MRR/ARR calculation framework

**In Progress (🚧):**
- FFLib Domains for revenue objects
- FFLib Selectors with gender-based queries
- Revenue Services (RevenueService, LeadConversionService, SubscriptionService)
- Automation triggers (gender classification, premium calculation)
- Batch jobs (revenue recognition, churn detection)
- Executive dashboards and reports

---

## 🏗️ Architecture

### Technology Stack
- **Platform**: Salesforce (Lightning Experience)
- **Backend**: Apex (with FFLib patterns)
- **Frontend**: Lightning Web Components (LWC)
- **API Integration**: ESPN API via Named Credentials
- **Architecture**: fflib-apex-common, fflib-apex-mocks

### Core Objects

**Custom Objects:**
- `Team__c` - Sports teams
- `Player__c` - Athletes
- `Competition__c` - Leagues/tournaments
- `Fixture__c` - Matches/games
- `Fixture_Period__c` - Match periods (halves, quarters)
- `Fixture_Participation__c` - Team participation in fixtures
- `Commentary__c` - Match commentary
- `Commentary_Event__c` - Key moments (goals, cards, etc.)
- `Team_Season_Stats__c` - Season statistics per team
- `Player_Season_Stats__c` - Season statistics per player
- `Social_Engagement__c` - Social share/view tracking
- `Revenue_Stream__c` - Revenue source tracking
- `Sponsorship__c` - Brand partnerships
- `Media_License__c` - Content licensing deals
- `League_Partnership__c` - Official league relationships

**Enhanced Standard Objects:**
- `Lead` - +13 revenue qualification fields
- `Opportunity` - +18 revenue tracking fields
- `Account` - +13 customer management fields

### FFLib Layers

```
┌─────────────────────────────────────┐
│   Lightning Web Components (LWC)    │
│  socialShareWidget, momentDetailPage │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│     Controllers (Apex Classes)      │
│ ESPNActionController, MomentPageCtrl │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│        Services (IService)          │
│  ESPNSyncService, SocialSharingServ │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│         Domains (IDomain)           │
│   Teams, Players, Fixtures, etc.    │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│       Selectors (ISelector)         │
│  TeamsSelector, FixturesSelector    │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│      Custom Objects & Fields        │
└─────────────────────────────────────┘
```

---

## 🚀 Installation

### Prerequisites
- Salesforce Developer Edition or higher
- Salesforce CLI (`sf` command)
- Git
- Node.js (for LWC development)

### Setup Instructions

1. **Clone the repository:**
```bash
git clone https://github.com/matchmoments-admin/match-moments-salesforce.git
cd match-moments-salesforce
```

2. **Authenticate with your Salesforce org:**
```bash
sf org login web --set-default-dev-hub --alias my-hub
```

3. **Create a scratch org (optional):**
```bash
sf org create scratch --definition-file config/project-scratch-def.json \
  --set-default --duration-days 30 --alias match-moments-scratch
```

4. **Deploy the metadata:**
```bash
# Deploy everything
sf project deploy start --source-dir force-app -o your-org-alias

# Or deploy specific components
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/objects
sf project deploy start --source-dir force-app/main/default/lwc
```

5. **Assign permission sets:**
```bash
sf org assign permset --name ESPN_Internal_Users -o your-org-alias
```

6. **Configure ESPN API access:**
   - Go to Setup → Named Credentials
   - Configure ESPN API credentials
   - Update Remote Site Settings if needed

7. **Verify deployment:**
```bash
# Run verification script in Anonymous Apex
# Copy/paste contents of scripts/apex/verify-phase2.apex
```

---

## 📖 Usage Examples

### Sync Fixture Data from ESPN

```apex
// Using ESPNActionController
ESPNActionController.DataWrapper result = ESPNActionController.getFixtureData(
    fixtureId,     // Fixture__c record Id
    'soccer',      // Sport type
    'eng.1',       // ESPN League ID
    '401492691'    // ESPN Event ID
);

if (result.success) {
    System.debug('Fixture synced: ' + result.message);
}
```

### Create a Women's Sports Sponsorship

```apex
// Create sponsor account
Account sponsor = new Account(
    Name = 'Nike',
    Account_Type__c = 'Brand/Sponsor'
);
insert sponsor;

// Create sponsorship with women's premium
Sponsorship__c wslDeal = new Sponsorship__c(
    Sponsor_Name__c = sponsor.Id,
    Sponsorship_Type__c = 'Title Sponsor',
    Gender_Focus__c = 'Women\'s Sports',
    Sport_Type__c = 'Soccer',
    Contract_Value__c = 500000,
    Women_Premium__c = 100000, // 20% uplift
    Contract_Start__c = Date.today(),
    Contract_End__c = Date.today().addYears(3),
    Status__c = 'Active',
    Impressions_Target__c = 10000000
);
insert wslDeal;
```

### Track Social Engagement

```apex
// Using EngagementTracker
EngagementTracker.trackShare(
    commentaryEventId,
    'Twitter',
    'https://matchmoments.com/event/12345',
    'https://twitter.com/user'
);

// Calculate viral score
Decimal viralScore = EngagementTracker.calculateViralScore(commentaryEventId);
System.debug('Viral Score: ' + viralScore);
```

### Use FFLib Application Factory

```apex
// Get selector
IFixturesSelector fixSelector = (IFixturesSelector) 
    Application.Selector.newInstance(Fixture__c.SObjectType);

List<Fixture__c> upcomingFixtures = fixSelector.selectByCompetition(
    competitionIds, 
    Date.today(), 
    Date.today().addDays(7)
);

// Use service
IESPNSyncService syncService = (IESPNSyncService) 
    Application.Service.newInstance(IESPNSyncService.class);

syncService.syncFixturesForCompetition(competitionId);
```

---

## 🧪 Testing

### Run Apex Tests

```bash
# Run all tests
sf apex run test --test-level RunLocalTests -o your-org-alias

# Run specific test class
sf apex run test --tests TeamsSelector_Test -o your-org-alias
```

### Test LWC Components

```bash
# Run LWC tests (if configured)
npm run test:unit
```

### Manual Testing

**Social Sharing Widget:**
1. Navigate to Commentary_Event__c record page
2. Verify socialShareWidget displays share buttons
3. Click each platform button and verify proper URL generation
4. Check Social_Engagement__c records are created

**Fixture Sync:**
1. Create Fixture__c with ESPN_Event_ID__c
2. Click "Sync from ESPN" quick action
3. Verify scores and status are updated
4. Check associated commentary events

**Revenue Tracking:**
1. Create Lead with Lead_Type__c = 'Subscription'
2. Convert to Opportunity
3. Verify MRR__c and ARR__c calculations
4. Check Gender_Focus__c is properly classified

---

## 📁 Project Structure

```
match-moments-salesforce/
├── force-app/main/default/
│   ├── classes/               # Apex classes
│   │   ├── application/       # Application factory
│   │   ├── controllers/       # LWC controllers
│   │   ├── domains/          # Domain layer (12 classes)
│   │   ├── selectors/        # Selector layer (15 classes)
│   │   └── services/         # Service layer (8 classes)
│   ├── lwc/                  # Lightning Web Components
│   │   ├── socialShareWidget/
│   │   ├── momentDetailPage/
│   │   └── getSportData/
│   ├── objects/              # Custom objects & fields
│   │   ├── Team__c/
│   │   ├── Player__c/
│   │   ├── Fixture__c/
│   │   ├── Revenue_Stream__c/
│   │   └── Sponsorship__c/
│   ├── permissionsets/       # Permission sets
│   ├── flows/                # Flows
│   ├── layouts/              # Page layouts
│   └── tabs/                 # Custom tabs
├── scripts/apex/             # Apex scripts for testing
├── config/                   # Org configuration
├── manifest/                 # Package.xml
└── docs/                     # Documentation
```

### 🔗 Browse Source Code on GitHub

#### Apex Classes

**Application Layer:**
- [`Application.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/application/Application.cls) - FFLib Application Factory

**Controllers:**
- [`ESPNActionController.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/ESPNActionController.cls) - ESPN API integration
- [`ESPNActionControllerV2.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/controllers/ESPNActionControllerV2.cls) - FFLib-based controller
- [`MomentPageController.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/MomentPageController.cls) - Moment detail page controller
- [`EngagementTracker.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/EngagementTracker.cls) - Social engagement tracking

**Domains:** [View all](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/classes/domains)
- [`Teams.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/Teams.cls)
- [`Players.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/Players.cls)
- [`Fixtures.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/Fixtures.cls)
- [`Competitions.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/Competitions.cls)
- [`CommentaryEvents.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/CommentaryEvents.cls)
- [`SocialEngagements.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/domains/SocialEngagements.cls)

**Selectors:** [View all](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/classes/selectors)
- [`TeamsSelector.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/selectors/TeamsSelector.cls)
- [`PlayersSelector.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/selectors/PlayersSelector.cls)
- [`FixturesSelector.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/selectors/FixturesSelector.cls)
- [`CompetitionsSelector.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/selectors/CompetitionsSelector.cls)
- [`CommentaryEventsSelector.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/selectors/CommentaryEventsSelector.cls)

**Services:** [View all](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/classes/services)
- [`ESPNSyncServiceImpl.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/services/ESPNSyncServiceImpl.cls)
- [`SocialSharingServiceImpl.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/services/SocialSharingServiceImpl.cls)
- [`EngagementServiceImpl.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/services/EngagementServiceImpl.cls)
- [`SportUtils.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/services/SportUtils.cls)

**Sport Handlers:**
- [`SoccerHandler.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/SoccerHandler.cls)
- [`CricketHandler.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/CricketHandler.cls)
- [`NBAHandler.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/NBAHandler.cls)
- [`AFLHandler.cls`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/classes/AFLHandler.cls)

#### Lightning Web Components

- [`socialShareWidget`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/lwc/socialShareWidget) - Social share buttons with engagement tracking
  - [`socialShareWidget.js`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/socialShareWidget/socialShareWidget.js)
  - [`socialShareWidget.html`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/socialShareWidget/socialShareWidget.html)
  - [`socialShareWidget.css`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/socialShareWidget/socialShareWidget.css)

- [`momentDetailPage`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/lwc/momentDetailPage) - Public moment display page
  - [`momentDetailPage.js`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/momentDetailPage/momentDetailPage.js)
  - [`momentDetailPage.html`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/momentDetailPage/momentDetailPage.html)
  - [`momentDetailPage.css`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/momentDetailPage/momentDetailPage.css)

- [`getSportData`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/lwc/getSportData) - Quick action UI for ESPN sync
  - [`getSportData.js`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/getSportData/getSportData.js)
  - [`getSportData.html`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/lwc/getSportData/getSportData.html)

#### Custom Objects

[**View all objects**](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects)

**Core Sports Objects:**
- [`Team__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Team__c) - Sports teams (maps to Account)
- [`Competition__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Competition__c) - Leagues and tournaments
- [`Fixture__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Fixture__c) - Matches/games
- [`Fixture_Period__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Fixture_Period__c) - Match periods
- [`Commentary__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Commentary__c) - Match commentary
- [`Commentary_Event__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Commentary_Event__c) - Key moments (goals, cards, etc.)

**Statistics Objects:**
- [`Team_Season_Stats__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Team_Season_Stats__c) - Team statistics (32+ fields)
- [`Player_Season_Stats__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Player_Season_Stats__c) - Player statistics (40+ fields)

**Social & Engagement:**
- [`Social_Engagement__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Social_Engagement__c) - Share and view tracking

**Revenue Objects:**
- [`Revenue_Stream__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Revenue_Stream__c) - Revenue source tracking
- [`Sponsorship__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Sponsorship__c) - Brand partnerships (20% women's premium)
- [`Media_License__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Media_License__c) - Content licensing deals
- [`League_Partnership__c`](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/League_Partnership__c) - Official league relationships

**Enhanced Standard Objects:**
- [`Lead` (custom fields)](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Lead/fields) - +13 revenue qualification fields
- [`Opportunity` (custom fields)](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Opportunity/fields) - +18 revenue tracking fields
- [`Account` (custom fields)](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/objects/Account/fields) - +13 customer management fields

#### Configuration

- [**Permission Sets**](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/permissionsets)
  - [`ESPN_Internal_Users`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/permissionsets/ESPN_Internal_Users.permissionset-meta.xml) - Full FLS access
  - [`ESPN_API_External_Users`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/permissionsets/ESPN_API_External_Users.permissionset-meta.xml) - Limited access

- [**Quick Actions**](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/quickActions)
  - [`Fixture__c.SyncFromESPN`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/quickActions/Fixture__c.SyncFromESPN.quickAction-meta.xml)
  - [`Competition__c.SyncFixturesFromESPN`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/quickActions/Competition__c.SyncFixturesFromESPN.quickAction-meta.xml)

- [**Remote Site Settings**](https://github.com/matchmoments-admin/match-moments-salesforce/tree/main/force-app/main/default/remoteSiteSettings)
  - [`ESPN_API`](https://github.com/matchmoments-admin/match-moments-salesforce/blob/main/force-app/main/default/remoteSiteSettings/ESPN_API.remoteSite-meta.xml)

---

## 🔧 Development Workflow

### Making Changes

1. **Create a feature branch:**
```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes:**
   - Edit files in `force-app/main/default/`
   - Follow FFLib patterns for Apex
   - Follow LWC best practices for components

3. **Test locally:**
```bash
# Deploy to scratch org
sf project deploy start --source-dir force-app -o your-scratch-org

# Run tests
sf apex run test --test-level RunLocalTests -o your-scratch-org
```

4. **Commit and push:**
```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/your-feature-name
```

5. **Create pull request** for review

### Coding Standards

**Apex:**
- Use FFLib patterns (Application factory, Selectors, Domains, Services)
- Always include FLS checks in selectors
- One Unit of Work per transaction
- 90%+ test coverage
- Bulkified code (no SOQL in loops)

**LWC:**
- Use Lightning Data Service where possible
- Proper error handling with toast messages
- Accessibility (ARIA labels, keyboard navigation)
- Component documentation with JSDoc

**Security:**
- Field Level Security (FLS) for all custom fields
- CRUD/FLS checks in all selectors
- Parameterized queries to prevent SOQL injection
- Sharing rules properly configured

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [sports.plan.md](sports.plan.md) | Master project plan (Phase 2A-2E) |
| [REVENUE-IMPLEMENTATION-STATUS.md](REVENUE-IMPLEMENTATION-STATUS.md) | Revenue implementation details |
| [PHASE-2E-CUSTOM-OBJECTS-COMPLETE.md](PHASE-2E-CUSTOM-OBJECTS-COMPLETE.md) | Custom objects summary |
| [ESPN_TESTING_PLAN.md](ESPN_TESTING_PLAN.md) | ESPN API integration testing |
| [UI_TESTING_PLAN.md](UI_TESTING_PLAN.md) | UI component testing guide |
| [SOCIAL_SHARING_IMPLEMENTATION_PLAN.md](SOCIAL_SHARING_IMPLEMENTATION_PLAN.md) | Social features plan |

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow coding standards (see Development Workflow)
4. Write/update tests for your changes
5. Ensure all tests pass
6. Update documentation as needed
7. Commit with descriptive messages (`git commit -m 'feat: add amazing feature'`)
8. Push to your branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style/formatting
- `refactor:` Code refactoring
- `test:` Adding/updating tests
- `chore:` Maintenance tasks

---

## 🛠️ Troubleshooting

### Common Issues

**Issue: ESPN API returns 403 Forbidden**
- Check Named Credential configuration
- Verify Remote Site Settings include ESPN domain
- Confirm API key is valid

**Issue: Social share buttons not appearing**
- Check FLS permissions for Social_Engagement__c
- Verify socialShareWidget LWC is added to page layout
- Check browser console for JavaScript errors

**Issue: Revenue fields not visible**
- Assign ESPN_Internal_Users permission set
- Verify FLS is configured for all 109 revenue fields
- Check page layout includes custom fields

**Issue: FFLib Application factory errors**
- Verify Application.cls is deployed
- Check all selector/domain/service bindings
- Ensure FFLib libraries are installed

---

## 📊 Key Metrics & KPIs

### Revenue Targets (Year 2)
- **Total ARR**: $1.92M
- **Women's Sports Revenue**: $1.15M (60%)
- **MRR Growth Rate**: 15% month-over-month
- **Customer LTV**: $12K average
- **Churn Rate**: <5% annually

### Engagement Metrics
- **Viral Moments**: 1000+ per month
- **Social Shares**: 50K+ per month
- **Platform Distribution**: Twitter (40%), Facebook (30%), LinkedIn (20%), WhatsApp (10%)
- **Women's Sports Engagement**: 65% of all shares

### Data Tracking
- **Fixtures Synced**: 500+ per week
- **Competitions Active**: 20+ leagues
- **Teams Tracked**: 200+
- **Players Tracked**: 5000+

---

## 📞 Support

For issues, questions, or contributions:

- **GitHub Issues**: [Create an issue](https://github.com/matchmoments-admin/match-moments-salesforce/issues)
- **Project Documentation**: See `/docs` folder
- **Salesforce Trailblazer Community**: Tag `@MatchMoments`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **FFLib**: Built on [apex-enterprise-patterns](https://github.com/apex-enterprise-patterns)
- **ESPN API**: Sports data powered by ESPN
- **Salesforce Community**: For best practices and patterns
- **Women's Sports Foundation**: Inspiration for 60% women's focus

---

## 🗺️ Roadmap

### Q1 2026
- ✅ Complete Phase 2E FFLib implementation
- ✅ Launch executive dashboards
- ✅ Automate revenue recognition

### Q2 2026
- 📅 Real-time live scores integration
- 📅 Mobile app with Salesforce Mobile SDK
- 📅 Advanced analytics with Einstein AI

### Q3 2026
- 📅 Expand to 10 additional sports
- 📅 International market expansion
- 📅 API for third-party integrations

### Q4 2026
- 📅 Predictive churn modeling
- 📅 Automated sponsorship matching
- 📅 Community portal for fans

---

**Built with ❤️ for Women's Sports**

*Last Updated: December 6, 2025*
