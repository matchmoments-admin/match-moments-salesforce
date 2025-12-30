public inherited sharing class AccountsSelector extends fflib_SObjectSelector implements IAccountsSelector {
    public static final Schema.SObjectType SOBJECT_TYPE = Account.SObjectType;
    private static Account defaultAussieStore = null;
    private static Account nationalMarketStore = null;
    private static Account aussieHlsStore = null;
    private static Account overflowStore = null;

    private static List<Account> cachedAccounts = new List<Account>();

    public static final List<Schema.SObjectField> SOBJECT_FIELDS_LIST = new List<Schema.SObjectField>{
        Account.Id,
        Account.Name,
        Account.ALI_Company_Auth_Rep_Number_Store__c,
        Account.BillingAddress,
        Account.BillingStreet,
        Account.BillingCity,
        Account.BillingState,
        Account.BillingPostalCode,
        Account.BillingCountry,
        Account.BillingLatitude,
        Account.BillingLongitude,
        Account.Closing_Time__c,
        Account.Contractual_Entity_Store__c,
        Account.OwnerId,
        Account.RecordTypeId,
        Account.Brand__c,
        Account.Email__c,
        Account.External_ID__c,
        Account.IsLeadActive__c,
        Account.Is_National_Market_Customer__c,
        Account.Fax,
        Account.Lead_Source__c,
        Account.Lendi_Customer_Uuid__c,
        Account.Logo__c,
        Account.Monthly_Appointments_Target__c,
        Account.Opening_Time__c,
        Account.Phone,
        Account.Primary_Store__c,
        Account.Restriction_Status__c,
        Account.Store__c,
        Account.Store_UUID__c,
        Account.Suburb__c,
        Account.Weekly_Appointment_Target__c,
        Account.isLeadActiveLogo__c,
        Account.Opportunity_Count__c,
        Account.Store_Territory__c,
        Account.Toolbox_ID__c,
        Account.Marketing_Store_Name__c,
        Account.Store_Type__c,
        Account.Store_Status__c,
        Account.Store_Opt_In_Status__c,
        Account.Stripe_Customer_Id__c,
        Account.Appointment_Overflow_End_Date__c
    };

    public static final List<Schema.SObjectField> ACCOUNTCONTACTRELATIONS_FIELDS_LIST = new List<Schema.SObjectField>{
        AccountContactRelation.Id,
        AccountContactRelation.IsActive,
        AccountContactRelation.ContactId,
        AccountContactRelation.Roles
    };

    public static IAccountsSelector newInstance() {
        return (IAccountsSelector) Application.Selector.newInstance(SOBJECT_TYPE);
    }

    public Schema.SObjectType getSObjectType() {
        return SOBJECT_TYPE;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return SOBJECT_FIELDS_LIST;
    }

    /**
     * PUBLIC METHODS
     */
    private Map<Id, Account> getFromSmartCache(Set<Id> recordIds) {
        Boolean isSmartCacheEnabled = Feature_Flag__mdt.getInstance('Smart_Cache_Feature').Enabled__c;
        if (!isSmartCacheEnabled) {
            // If the feature flag is false, directly query the database
            return new Map<Id, Account>((List<Account>) Database.query(newQueryFactory().setCondition('Id IN :recordIds').toSOQL()));
        }

        Integer heapSizeBuffer = Label.Heap_Size_Buffer.isNumeric() ? Integer.valueOf(Label.Heap_Size_Buffer) : 3000000;
        if (Limits.getHeapSize() > (Limits.getLimitHeapSize() - heapSizeBuffer)) {
            // Directly query the database without updating the cache
            List<Account> accountList = Database.query(newQueryFactory().setCondition('Id IN :recordIds').toSOQL());
            return new Map<Id, Account>(accountList);
        }

        // Create a set for missing IDs
        Set<Id> missingIds = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>(cachedAccounts);

        // Check for missing IDs
        for (Id recordId : recordIds) {
            if (accountMap.containsKey(recordId) == false) {
                missingIds.add(recordId);
            }
        }
        // If there are missing IDs, query the database
        if (missingIds.isEmpty() == false) {
            List<Account> missingAccounts = Database.query(newQueryFactory().setCondition('Id IN :missingIds').toSOQL());
            if (missingAccounts.isEmpty() == false) {
                // Update cache with new accounts
                for (Account account : missingAccounts) {
                    cachedAccounts.add(account);
                    accountMap.put(account.Id, account);
                }
            }
        }
        return accountMap;
    }

    public Account getDefaultAussieStore() {
        if (defaultAussieStore == null) {
            List<Account> storeList = this.selectByStoreUuid(new Set<String>{ Accounts.DEFAULT_AUSSIE_STORE_UUID });
            if (storeList.isEmpty()) {
                return null;
            }
            defaultAussieStore = storeList[0];
        }
        return defaultAussieStore;
    }

    public Account getAussieHlsStore() {
        if (aussieHlsStore == null) {
            List<Account> storeList = this.selectByStoreUuid(new Set<String>{ Label.Aussie_HLS_Store_UUID });
            if (storeList.isEmpty()) {
                return null;
            }
            aussieHlsStore = storeList[0];
        }
        return aussieHlsStore;
    }

    public Account getOverflowStore() {
        if (overflowStore == null) {
            List<Account> storeList = this.selectByStoreUuid(new Set<String>{ Label.Overflow_Store_UUID });
            if (storeList.isEmpty()) {
                return null;
            }
            overflowStore = storeList[0];
        }
        return overflowStore;
    }

    public Account getNationalMarketStore() {
        if (nationalMarketStore == null) {
            List<Account> storeList = this.selectByStoreUuid(new Set<String>{ Label.National_Market_Retail_Store_UUID });
            if (storeList.isEmpty()) {
                //National Market Store always exist, this for test classes not required the Store
                return null;
            }
            nationalMarketStore = storeList[0];
        }
        return nationalMarketStore;
    }

    public List<Account> selectById(Set<Id> recordIds) {
        Map<Id, Account> accountMap = getFromSmartCache(recordIds);
        return new List<Account>(accountMap.values());
    }

    public Account selectById(Id recordId) {
        return (Account) Database.query(newQueryFactory().setCondition('Id =: recordId').toSOQL());
    }

    public List<Account> selectByIdWithRecordType(Set<Id> recordIds, Id recordTypeId) {
        return (List<Account>) Database.query(newQueryFactory().setCondition('Id IN :recordIds AND RecordTypeId =: recordTypeId').toSOQL());
    }

    public List<Account> selectByIdWithOwner(Set<Id> recordIds) {
        fflib_QueryFactory queryFactory = newQueryFactory()
            .selectField('Owner.UserRole.Name')
            .selectField('Owner.User_UUID__c')
            .selectField('Previous_Owner__r.User_UUID__c')
            .selectField('Suburb__r.Name')
            .selectField('Suburb__r.Postcode__c')
            .selectField('Store__r.Store_UUID__c')
            .selectField('Previous_Store__r.Store_UUID__c')
            .selectField('Is_Purchase_Proposition_Customer__c')
            .selectField('Conference_Call_Opted_In__c')
            .setCondition('Id IN :recordIds');
        new UsersSelector().configureQueryFactoryFields(queryFactory, 'Owner');

        return (List<Account>) Database.query(queryFactory.toSOQL());
    }

    public List<Account> selectByUuid(Set<String> customerUuidSet) {
        return (List<Account>) Database.query(
            newQueryFactory()
                .selectField('Store__r.Name')
                .selectField('Store__r.Store_UUID__c')
                .selectField('Store__r.Store_Type__c')
                .selectField('Store__r.Appointment_Overflow__c')
                .selectField('Store__r.Weekly_Appointment_Count__c')
                .selectField('Store__r.Weekly_Appointment_Overflow_Count__c')
                .selectField('Store__r.Weekly_Appointment_Capacity__c')
                .selectField('Owner.User_UUID__c')
                .setCondition('Lendi_Customer_Uuid__c IN :customerUuidSet')
                .toSOQL()
        );
    }

    public Map<String, Account> selectCustomerByUuid(Set<String> customerUuidSet) {
        Map<String, Account> accountMap = new Map<String, Account>();
        fflib_QueryFactory queryFactory = newQueryFactory().setCondition('Lendi_Customer_Uuid__c IN :customerUuidSet');
        queryFactory.subselectQuery('Contacts').selectField('Id');
        List<Account> accountList = (List<Account>) Database.query(queryFactory.toSOQL());

        for (Account record : accountList) {
            accountMap.put(record.Lendi_Customer_Uuid__c, record);
        }
        return accountMap;
    }

    public List<Account> selectByStoreUuid(Set<String> storeUuidSet) {
        return (List<Account>) Database.query(
            newQueryFactory()
                .selectField('Appointment_Overflow__c')
                .selectField('Weekly_Appointment_Count__c')
                .selectField('Weekly_Appointment_Capacity__c')
                .selectField('Weekly_Appointment_Percentage_Achieved__c')
                .setCondition('Store_UUID__c IN :storeUuidSet')
                .toSOQL()
        );
    }

    public Map<String, Account> selectByStoreUuidsWithACRs(Set<String> storeUuidSet) {
        Map<String, Account> storeByUuid = new Map<String, Account>();
        fflib_QueryFactory queryFactory = newQueryFactory().setCondition('Store_UUID__c IN :storeUuidSet');
        queryFactory.subselectQuery('AccountContactRelations').selectField('Contact.User_UUID__c');

        for (Account store : (List<Account>) Database.query(queryFactory.toSOQL())) {
            storeByUuid.put(store.Store_UUID__c, store);
        }

        return storeByUuid;
    }

    public List<Account> selectByToolboxId(Set<String> toolboxIdSet) {
        return (List<Account>) Database.query(
            newQueryFactory().setCondition('Toolbox_ID__c IN :toolboxIdSet OR store_UUID__c IN :toolboxIdSet').toSOQL()
        );
    } //need to update tp accept storeUUID

    public List<Account> selectByToolboxCompanyId(Set<String> toolboxIdSet) {
        return (List<Account>) Database.query(
            newQueryFactory()
                .selectField('Toolbox_Company_Id__c')
                .selectField('Owner.User_UUID__c')
                .setCondition('Toolbox_Company_Id__c IN :toolboxIdSet')
                .toSOQL()
        );
    }

    //Cannot order and limit the subquery due to limitation of UserRecordAccess object hence doing normal query.
    public Map<String, Account> selectByUuidWithRelatedOpportunities(Set<String> customerUuidSet) {
        Map<String, Account> accountByCustomerUuidMap = new Map<String, Account>();
        List<Account> accountList = [
            SELECT
                Id,
                Lendi_Customer_Uuid__c,
                Is_Disabled__c,
                OwnerId,
                Owner.ManagerId,
                (SELECT Id, Customer_Deidentified__c, Internal_Team_Member__c FROM Contacts),
                (
                    SELECT
                        Id,
                        Application_UUID__c,
                        OwnerId,
                        Current_OTM_CS_Assessment_Associate__c,
                        Current_OTM_CS_Assessment_Expert__c,
                        Current_OTM_CS_Settlement_Associate__c,
                        Current_OTM_CS_Settlement_Expert__c,
                        Current_OTM_CS_Specialist__c,
                        RecordType.DeveloperName
                    FROM Opportunities
                    ORDER BY SystemModStamp DESC
                    LIMIT 200
                )
            FROM Account
            WHERE Lendi_Customer_Uuid__c IN :customerUuidSet
        ];
        for (Account accountRecord : accountList) {
            accountByCustomerUuidMap.put(accountRecord.Lendi_Customer_Uuid__c, accountRecord);
        }
        return accountByCustomerUuidMap;
    }

    public List<Account> selectStoreByIdWithAccountContacts(Set<Id> recordIds) {
        String storeRecordType = Accounts.STORE_RECORD_TYPE;
        fflib_QueryFactory queryFactory = newQueryFactory().setCondition('Id IN : recordIds AND RecordType.DeveloperName = :storeRecordType');
        queryFactory.subselectQuery('AccountContactRelations')
            .selectFields(ACCOUNTCONTACTRELATIONS_FIELDS_LIST)
            .selectField('Contact.Salesforce_User__c')
            .selectField('Contact.Broker_Status__c')
            .selectField('Contact.Name');
        return (List<Account>) Database.query(queryFactory.toSOQL());
    }

    public List<Account> selectCustomerByCreatedDateRange(Datetime fromDate, Datetime toDate) {
        return Database.query(
            newQueryFactory()
                .setCondition(
                    'RecordType.DeveloperName = \'' +
                        Accounts.CUSTOMER_RECORD_TYPE +
                        '\' AND Restriction_Status__c = \'' +
                        Accounts.RS_NOT_SET +
                        '\' AND CreatedDate > :fromDate AND CreatedDate < :toDate'
                )
                .toSOQL()
        );
    }

    public List<Account> selectByExternalId(Set<String> externalIdSet) {
        return (List<Account>) Database.query(
            newQueryFactory()
                .selectField('External_ID__c')
                .selectField('Owner.User_UUID__c')
                .setCondition('External_ID__c IN :externalIdSet')
                .toSOQL()
        );
    }

    public List<Account> selectCmsDataByAccountId(Set<Id> recordIds) {
        String storeRecordType = Accounts.STORE_RECORD_TYPE;
        fflib_QueryFactory queryFactory = newQueryFactory().setCondition('Id IN : recordIds AND RecordType.DeveloperName = :storeRecordType');
        queryFactory.subselectQuery('CMS_Data__r')
            .selectFields(CMSDataSelector.SOBJECT_FIELDS_LIST)
            .addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
            .setLimit(1);

        queryFactory.subselectQuery('AccountContactRelations')
            .selectFields(ACCOUNTCONTACTRELATIONS_FIELDS_LIST)
            .selectField('Contact.User_UUID__c')
            .selectField('Contact.Name')
            .selectField('Contact.Broker_Status__c');

        queryFactory.subselectQuery('Suburbs__r').selectField('Key__c').selectField('Name').selectField('Postcode__c').selectField('State__c');

        return (List<Account>) Database.query(queryFactory.toSOQL());
    }

    /**
     * Description : This method is used to fetch Store__C fields for account records
     * Author : Palak Singla
     * Params : Set<Id> accountIdSet - Account Id Set
     **/
    public List<Account> selectAccountsWithStoreFields(Set<Id> accountIdSet) {
        fflib_QueryFactory queryFactory = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .selectField('Store__r.Store_Territory__c')
            .setCondition('Id IN :accountIdSet');

        ((AccountsSelector) AccountsSelector.newInstance()).configureQueryFactoryFields(queryFactory, 'Store__r');
        return (List<Account>) Database.query(queryFactory.toSOQL());
    }

    public List<Account> selectStoresByName(String searchValue, Set<String> storeTypes) {
        String storeRecordType = Accounts.STORE_RECORD_TYPE;
        fflib_QueryFactory queryFactory = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .setCondition('Name LIKE :searchValue AND RecordType.DeveloperName = :storeRecordType AND Store_Type__c IN :storeTypes');
        return (List<Account>) Database.query(queryFactory.toSOQL());
    }

    public List<Account> selectByRoundRobinFlag(Datetime fromDatetime) {
        return (List<Account>) Database.query(
            newQueryFactory().selectField('Store__r.Store_Opt_In_Status__c').setCondition('Execute_Round_Robin__c > :fromDatetime').toSOQL()
        );
    }

    public Map<Id, Integer> selectLeadCountThisMonthByOwnerId(Set<Id> userIds) {
        String customerRecordType = Accounts.CUSTOMER_RECORD_TYPE;
        String countQuery =
            'SELECT OwnerId userId, COUNT(Id) leadCount ' +
            'FROM Account ' +
            'WHERE OwnerId IN :userIds ' +
            'AND RecordType.DeveloperName = :customerRecordType ' +
            'AND Owner_Assigned_Datetime__c = THIS_MONTH ' +
            'GROUP BY OwnerId';

        Map<Id, Integer> leadCountByUserId = new Map<Id, Integer>();
        for (AggregateResult result : Database.query(countQuery)) {
            leadCountByUserId.put((Id) result.get('userId'), (Integer) result.get('leadCount'));
        }

        return leadCountByUserId;
    }

    public List<Account> selectStoreByDistance(Location locationValue, Integer rowLimit) {
        return [
            SELECT Id, Name, BillingCity, BillingPostalCode, DISTANCE(BillingAddress, :locationValue, 'km') distanceByKm
            FROM Account
            WHERE
                RecordType.DeveloperName = :Accounts.STORE_RECORD_TYPE
                AND Store_Type__c = :Accounts.STORE_TYPE_RETAIL
                AND Store_Status__c = :Accounts.STORE_STATUS_ACTIVE
            ORDER BY DISTANCE(BillingAddress, :locationValue, 'km') ASC NULLS LAST
            LIMIT :rowLimit
        ];
    }

    public List<Account> selectMiniRegions(Set<String> miniRegionNamesToExclude) {
        String queryConditionTemplate = 'RecordType.DeveloperName = {0} AND Store_Type__c = {1} AND Store_Status__c = {2}';
        List<Object> queryConditionParameters = new List<Object>{
            '\'' +
            Accounts.STORE_RECORD_TYPE +
            '\'',
            '\'' +
            Accounts.STORE_TYPE_MINI_REGION +
            '\'',
            '\'' +
            Accounts.STORE_STATUS_ACTIVE +
            '\''
        };
        String formattedConditionQuery = String.format(queryConditionTemplate, queryConditionParameters);

        if (miniRegionNamesToExclude != null && !miniRegionNamesToExclude.isEmpty()) {
            formattedConditionQuery += ' AND Name NOT IN :miniRegionNamesToExclude';
        }

        System.debug('formattedConditionQuery==>' + formattedConditionQuery);

        fflib_QueryFactory queryFactory = newQueryFactory().setCondition(formattedConditionQuery);
        return Database.query(queryFactory.toSOQL());
    }

    public List<Account> selectByPartnerAccountsByNames(Set<String> accountNames) {
        if (accountNames == null || accountNames.isEmpty()) {
            return new List<Account>();
        }

        return (List<Account>) Database.query(
            newQueryFactory()
                .selectField('Brand__c')
                .selectField('RecordType.DeveloperName')
                .setCondition('Name IN :accountNames AND RecordType.DeveloperName = \'Partner\'')
                .toSOQL()
        );
    }

    /**
     * @description Select Mobile store by state for state-based mobile broker assignment
     * @param managerState The state from User.Manager.State
     * @return Account record for the appropriate Mobile store, or null if not found
     */
    public Account selectMobileStoreByState(String managerState) {
        if (String.isBlank(managerState)) {
            return null;
        }

        // Normalize the state value to handle various formats
        String normalizedState = normalizeState(managerState);

        // Map normalized state to store name
        String storeName = getMobileStoreNameByState(normalizedState);

        if (String.isBlank(storeName)) {
            return null;
        }

        // Query for the mobile store
        String recordTypeName = Accounts.STORE_RECORD_TYPE;
        List<Account> mobileStores = (List<Account>) Database.query(
            newQueryFactory()
                .setCondition('Name = :storeName AND RecordType.DeveloperName = :recordTypeName')
                .setLimit(1)
                .toSOQL()
        );

        return mobileStores.isEmpty() ? null : mobileStores[0];
    }

    /**
     * @description Query mobile stores for multiple states in a single bulk SOQL query
     */
    public Map<String, Account> selectMobileStoresByStates(Set<String> states) {
        if (states == null || states.isEmpty()) {
            return new Map<String, Account>();
        }

        String recordTypeName = Accounts.STORE_RECORD_TYPE;
        
        Set<String> storeNames = new Set<String>();
        Map<String, String> normalizedStateByStoreName = new Map<String, String>();
        
        for (String state : states) {
            String normalizedState = normalizeState(state);
            if (String.isNotBlank(normalizedState)) {
                String storeName = getMobileStoreNameByState(normalizedState);
                if (String.isNotBlank(storeName)) {
                    storeNames.add(storeName);
                    normalizedStateByStoreName.put(storeName, normalizedState);
                }
            }
        }

        if (storeNames.isEmpty()) {
            return new Map<String, Account>();
        }

        List<Account> mobileStores = (List<Account>) Database.query(
            newQueryFactory()
                .setCondition('Name IN :storeNames AND RecordType.DeveloperName = :recordTypeName')
                .toSOQL()
        );

        Map<String, Account> storeByState = new Map<String, Account>();
        for (Account store : mobileStores) {
            String normalizedState = normalizedStateByStoreName.get(store.Name);
            if (String.isNotBlank(normalizedState)) {
                storeByState.put(normalizedState, store);
            }
        }

        return storeByState;
    }

    /**
     * @description Normalize state values to handle various formats
     * @param state Raw state value from User.Manager.State
     * @return Normalized state abbreviation (NSW, VIC, etc.)
     */
    @TestVisible
    private String normalizeState(String state) {
        if (String.isBlank(state)) {
            return null;
        }

        // Remove whitespace and convert to uppercase
        String normalized = state.trim().toUpperCase();

        // Map full state names to abbreviations
        Map<String, String> stateMapping = new Map<String, String>{
            'NEW SOUTH WALES' => 'NSW',
            'VICTORIA' => 'VIC',
            'QUEENSLAND' => 'QLD',
            'SOUTH AUSTRALIA' => 'SA',
            'WESTERN AUSTRALIA' => 'WA',
            'TASMANIA' => 'TAS',
            'NORTHERN TERRITORY' => 'NT',
            'AUSTRALIAN CAPITAL TERRITORY' => 'ACT',
            'NSW' => 'NSW',
            'VIC' => 'VIC',
            'QLD' => 'QLD',
            'SA' => 'SA',
            'WA' => 'WA',
            'TAS' => 'TAS',
            'NT' => 'NT',
            'ACT' => 'ACT'
        };

        return stateMapping.containsKey(normalized) ? stateMapping.get(normalized) : null;
    }

    /**
     * @description Get Mobile store name based on normalized state
     */
    @TestVisible
    private String getMobileStoreNameByState(String normalizedState) {
        if (String.isBlank(normalizedState)) {
            return null;
        }

        switch on normalizedState {
            when 'NSW' {
                return 'Mobile NSW';
            }
            when 'VIC' {
                return 'Mobile VIC';
            }
            when 'QLD' {
                return 'Mobile QLD';
            }
            when 'SA' {
                return 'Mobile SA';
            }
            when 'WA' {
                return 'Mobile WA';
            }
            when 'TAS' {
                return 'Mobile TAS';
            }
            when 'NT' {
                return 'Mobile NT';
            }
            when 'ACT' {
                return 'Mobile ACT';
            }
            when else {
                return null;
            }
        }
    }
}