public without sharing class AccountTriggerHandler extends fflib_SObjectDomain {
    public AccountTriggerHandler(List<SObject> sObjectList) {
        super(sObjectList);
        Configuration.disableTriggerCRUDSecurity();
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AccountTriggerHandler(sObjectList);
        }
    }

    public override void onApplyDefaults() {
        // Apply defaults
    }

    public override void onBeforeInsert() {
        setDefaulUser(true);
        validateStoreTerritory(true);
        setExternalId();
        setStoreUuid();
        setStore(true);
        setRestrictionStatus(true);
        setUnrestrictedDateTime(true);
        setOwnershipToLeadOwner(true);
        setRandCode();
        setIsNationalMarketPlace(true);
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        setDefaulUser(false);
        validateStoreTerritory(false);
        setExternalId();
        setStore(false);
        setRestrictionStatus(false);
        setUnrestrictedDateTime(false);
        setOwnershipToLeadOwner(false);
        clearOwnerAssignedDatetime(existingRecords);
        populatePreviousOwner(existingRecords);
        populatePreviousStore(existingRecords);
        clearPrimaryStore(existingRecords);
        setRandCode();
        updateDisabledAccount();
        setIsNationalMarketPlace(false);
        enableSuburbRouting();
    }

    // insert validations
    public override void onValidate() {
        validateBrand();
        validateOwner(records);
    }

    // update validations
    public override void onValidate(Map<Id, SObject> existingRecords) {
        validateOwner(
            new List<Account>( // added new List to avoid failing when trying to determine SObjectType
                (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId })
            )
        );

        validateRestrictionStatusChange(existingRecords);
    }

    public override void onAfterInsert() {
        List<Account> accountsToPublish = getWorkflowUpdatedAccounts((List<Account>) getRecords());

        fflib_ISObjectUnitOfWork uow = Application.UOWContext.createNewUOW();
        AccountService.setAccountTeamMembers(null, records);
        setStoreTerritory(true);
        Application.UOWContext.removeCurrentUOW().commitWork();

        if (accountsToPublish.isEmpty() == false) {
            AccountService.publishWorkflowUpdatedEvent(accountsToPublish);
        }

        publishToolboxAccountEvent(true);
        publishStoreMessage(true);
        syncStoreAccountRecordsToAussieforce(true);
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        fflib_ISObjectUnitOfWork uow = Application.UOWContext.createNewUOW();
        updateContactsAddresses();
        updateDisabledRecords();
        updateLegacyAussieContactRecordType();
        handleOwnerChange();
        handleStoreChange();
        handleStoreStatusChange();
        handleRestrictionStatusChange();
        raiseCOTR();
        setStoreTerritory(false);
        List<Account> accountList = getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId, Account.RecordTypeId });
        AccountService.setAccountTeamMembers(existingRecords, accountList);
        Application.UOWContext.removeCurrentUOW().commitWork();

        fflib_ISObjectUnitOfWork uow1 = Application.UOWContext.createNewUOW();
        List<Account> recordsToProcess = new List<Account>((List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c }));
        AccountService.shareCallsAndApptsWithAssociatedTerritories(recordsToProcess);
        Accounts.newInstance(recordsToProcess).shareCasesWithAssociatedTerritories();

        List<Account> accountsToPublish = getWorkflowUpdatedAccounts(
            getChangedRecords(
                new Set<Schema.SObjectField>{
                    Account.OwnerId,
                    Account.IsLeadActive__c,
                    Account.Lendi_Customer_Uuid__c,
                    Account.Restriction_Status__c,
                    Account.Store__c,
                    Account.Is_National_Market_Customer__c,
                    Account.Is_Purchase_Proposition_Customer__c
                }
            )
        );

        if (accountsToPublish.isEmpty() == false) {
            AccountService.publishWorkflowUpdatedEvent(accountsToPublish);
        }

        publishToolboxAccountEvent(false);
        publishStoreMessage(false);
        publishTeamMemberEvent();
        Application.UOWContext.removeCurrentUOW().commitWork();
        syncStoreAccountRecordsToAussieforce(false);
    }

    /**
     * PRIVATE METHODS
     */
    private void validateBrand() {
        for (Account acc : (List<Account>) records) {
            if (String.isEmpty(acc.Brand__c)) {
                acc.Brand__c.addError('You must provide a Brand when creating Accounts.');
            }
        }
    }

    private void validateOwner(List<Account> accountList) {
        if (accountList.isEmpty()) {
            return;
        }

        IAccounts accounts = Accounts.newInstance(accountList);
        accounts.validateOwner();
    }

    private void validateRestrictionStatusChange(Map<Id, SObject> existingRecords) {
        List<Account> recordsToValidate = new List<Account>(
            (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Restriction_Status__c })
        );

        if (recordsToValidate.isEmpty() == false) {
            Accounts.newInstance(recordsToValidate).validateRestrictionStatusChange(existingRecords);
        }
    }

    private void setExternalId() {
        List<Account> recordsToProcess = new List<Account>((List<Account>) Utils.filterSObjectListByField(getRecords(), 'External_ID__c', null));

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setExternalId();
        }
    }

    private void setStoreUuid() {
        Accounts.newInstance(getRecords()).setStoreUuid();
    }

    private void setStore(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert
                ? (List<Account>) getRecords()
                : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId, Account.Brand__c })
        );
        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setStoreUsingOwner();
        }

        recordsToProcess = new List<Account>(
            isInsert
                ? (List<Account>) getRecords()
                : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.BillingCity, Account.BillingPostalCode })
        );

        if (recordsToProcess.isEmpty() == false) {
            if (FeatureFlagCustomMetadata.getFeatureFlag('Enable_Lead_Overflow') == false) {
                Accounts.newInstance(recordsToProcess).setStoreUsingSuburb();
            } else {
                Accounts.newInstance(recordsToProcess).setStoreUsingSuburbWithOverflowChecks();
            }
        }
    }

    private void setRandCode() {
        Accounts.newInstance(getRecords()).setStoreRANCode();
    }

    private void setRestrictionStatus(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert
                ? (List<Account>) getRecords()
                : (List<Account>) getChangedRecords(
                      new Set<Schema.SObjectField>{ Account.Lendi_Customer_Uuid__c, Account.Lead_Id__c, Account.RecordTypeId, Account.Store__c }
                  )
        );

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setRestrictionStatus();
        }
    }

    private void setUnrestrictedDateTime(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert ? (List<Account>) getRecords() : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Restriction_Status__c })
        );

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setUnrestrictedDateTime();
        }
    }

    private void setOwnershipToLeadOwner(Boolean isInsert) {
        List<Account> accountList = new List<Account>( // added new List to avoid failing when trying to determine SObjectType
            isInsert
                ? (List<Account>) getRecords()
                : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId, Account.Store__c, Account.RecordTypeId })
        );
        if (Accounts.bottRulesEnabled == true) {
            return;
        }
        if (accountList.isEmpty() == false) {
            Accounts.newInstance(accountList).setRoundRobinFlag();
        }
    }

    private void clearOwnerAssignedDatetime(Map<Id, SObject> existingRecords) {
        List<Account> recordsToProcess = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);
            if (
                Utils.hasFieldChanged(oldAccount, accountRecord, 'OwnerId') == true &&
                Utils.hasFieldChanged(oldAccount, accountRecord, 'Owner_Assigned_Datetime__c') == false
            ) {
                recordsToProcess.add(accountRecord);
            }
        }

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).clearOwnerAssignedDatetime();
        }
    }

    private void raiseCOTR() {
        if (Accounts.bottRulesEnabled == true || FeatureManagement.checkPermission('Block_Ownership_Change_Comms') == true) {
            return;
        }
        List<Account> recordsToProcess = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);
            if (FeatureFlagCustomMetadata.getFeatureFlag('Enable_Appointment_Overflow') == true) {
                // Skip if the store change from or to the overflow store
                Id overflowStoreId = AccountsSelector.newInstance().getOverflowStore().Id;
                if (accountRecord.Store__c == overflowStoreId || oldAccount.Store__c == overflowStoreId) {
                    continue;
                }
            }
            // Process for COTR only if both store and owner have changed AND it's not a COTR rejection (i.e. it's not a revert of ownership change)
            if (
                (accountRecord.Store__c != oldAccount.Store__c) &&
                (accountRecord.OwnerId != oldAccount.OwnerId) &&
                (Accounts.accountIdsCOTRDenied.contains(accountRecord.Id) == false)
            ) {
                recordsToProcess.add(accountRecord);
            }
        }

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).raiseCOTR(existingRecords);
        }
    }

    private void setStoreTerritory(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert
                ? (List<Account>) getRecords()
                : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c, Account.RecordTypeId })
        );

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setStoreTerritory();
        }
    }

    private void updateContactsAddresses() {
        List<Account> changedAddressList = getChangedRecords(
            new Set<Schema.SObjectField>{
                Account.BillingStreet,
                Account.BillingCity,
                Account.BillingState,
                Account.BillingPostalCode,
                Account.BillingCountry
            }
        );
        if (changedAddressList.isEmpty() == false) {
            AccountService.updateContactsAddresses(changedAddressList);
        }
    }

    private void updateLegacyAussieContactRecordType() {
        List<Account> changedAccountList = new List<Account>((List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.RecordTypeId }));
        Id legacyAussieAccountRecordTypeId = Utils.getRecordTypeId('Account', Accounts.LEGACY_AUSSIE_RECORD_TYPE);
        Id customerAccountRecordTypeId = Utils.getRecordTypeId('Account', Accounts.CUSTOMER_RECORD_TYPE);

        //Get newly converted legacy aussie account records
        List<Account> accountList = new List<Account>();
        for (Account accountRecord : changedAccountList) {
            Account oldAccountRecord = (Account) existingRecords.get(accountRecord.Id);
            if (
                oldAccountRecord.RecordTypeId == legacyAussieAccountRecordTypeId &&
                accountRecord.RecordTypeId == customerAccountRecordTypeId &&
                accountRecord.Brand__c == Contacts.BRAND_AUSSIE
            ) {
                accountList.add(accountRecord);
            }
        }

        if (accountList.isEmpty() == false) {
            Accounts.newInstance(accountList).updateLegacyAussieContactRecordType();
        }
    }

    private void handleOwnerChange() {
        List<Account> accountList = getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId });

        if (accountList.isEmpty() == false) {
            // keeping uow outside of service class
            // to accomodate for additonal changes when owner changes
            List<Account> accountListNoStore = new List<Account>();
            for (Account acc : accountList) {
                if (String.isBlank(acc.Store__c)) {
                    accountListNoStore.add(acc);
                }
            }
            if (!accountListNoStore.isEmpty()) {
                // Territory should only be set from customer owner if store is missing (non-Aussie brands). For Aussie, it's set from Opportunity store.
                fflib_ISObjectUnitOfWork territoryOppsUOW = Application.UOWContext.createNewUOW();
                AccountService.setTerritoryOnOpenOpps(accountListNoStore, territoryOppsUOW);
                Application.UOWContext.removeCurrentUOW().commitWork();
            }
            fflib_ISObjectUnitOfWork uow = Application.UOWContext.createNewUOW();
            AccountService.transferOpportunityAndContactOwnership(accountList, uow);
            Map<Id, Account> storeChangeAccountMap = new Map<Id, Account>(
                (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c })
            );
            AccountService.setLeadSourceStatusFromAppointmentContext(accountList, storeChangeAccountMap, uow);

            if (accountList.isEmpty() == false) {
                AccountService.handleUnallocatedAppointmentsOnOwnerChange(accountList);
            }
            Application.UOWContext.removeCurrentUOW().commitWork();
            fflib_ISObjectUnitOfWork resetUOW = Application.UOWContext.createNewUOW();
            AccountService.resetSystemOwnershipChangeFlag((List<Account>) records, resetUOW);

            AccountService.transferConveyancingNBACaseOwnership(existingRecords, accountList, uow);

            Application.UOWContext.removeCurrentUOW().commitWork();
        }
    }

    private void handleStoreChange() {
        fflib_ISObjectUnitOfWork uow = Application.UOWContext.createNewUOW();
        List<Account> recordsToProcess = new List<Account>( // added new List to avoid failing when trying to determine SObjectType
            (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c })
        );
        
        // Filter out duplicate accounts
        List<Account> filteredRecords = new List<Account>();
        for (Account acc : recordsToProcess) {
            if (isDuplicateAccount(acc) == false) {
                filteredRecords.add(acc);
            }
        }
        
        if (filteredRecords.isEmpty() == false) {
            Accounts.newInstance(filteredRecords).handleOpenOpportunitiesOnStoreChange();
            AccountService.handleUnallocatedAppointmentsOnStoreChange(filteredRecords);
        }
        Application.UOWContext.removeCurrentUOW().commitWork();
    }

    private void handleStoreStatusChange() {
        if (FeatureFlagCustomMetadata.getFeatureFlag('ICRM1_1782') == false) {
            return;
        }
        List<Account> recordsToProcess = new List<Account>();
        Id storeRecordTypeId = Utils.getRecordTypeId('Account', Accounts.STORE_RECORD_TYPE);

        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);
            if (
                accountRecord.Brand__c == Contacts.BRAND_AUSSIE &&
                accountRecord.RecordTypeId == storeRecordTypeId &&
                accountRecord.Store_Status__c == Accounts.STORE_STATUS_INACTIVE &&
                Utils.hasAnyFieldChanged(oldAccount, accountRecord, new List<String>{ 'Store_Status__c' })
            ) {
                recordsToProcess.add(accountRecord);
            }
        }

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).handleStoreStatusChange();
        }
    }

    private void handleRestrictionStatusChange() {
        List<Account> recordsToProcess = new List<Account>(
            (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Restriction_Status__c })
        );
        if (recordsToProcess.isEmpty()) {
            return;
        }
        Map<Id, Contact> contactByAccountId = new Map<Id, Contact>();
        for (Contact contactRecord : ContactsSelector.newInstance().selectByAccountId(Utils.extractIdFieldSet(recordsToProcess, 'Id'))) {
            contactByAccountId.put(contactRecord.AccountId, contactRecord);
        }

        for (Account accountRecord : recordsToProcess) {
            Account oldAccountRecord = (Account) existingRecords.get(accountRecord.Id);
            /**
             * As the RestrictionStatus NotSet would have prevented tbx-account-in being sent out when the customer
             * was first created/reengaged, send leadId when this is changed, by setting the leadId data to static
             * variable to be used later when tbx-account-in message is created
             */
            if (oldAccountRecord.Restriction_Status__c == Accounts.RS_NOT_SET) {
                String customerKey = accountRecord.Lead_Id__c;
                TbxCustomerData customerData = new TbxCustomerData();
                customerData.leadId = accountRecord.Lead_Id__c;
                Contact contactRecord = contactByAccountId.get(accountRecord.Id);
                customerData.origin = contactRecord?.Funnel_Origin__c;
                customerData.loanValue = contactRecord?.Current_Loan_Value__c;
                customerData.propertyUse = contactRecord?.Property_Use__c;
                customerData.securityValue = contactRecord?.Security_Value__c;
                customerData.purpose = contactRecord?.Purpose__c;
                customerData.eligibleForFHOG = contactRecord?.Eligible_For_FHOG__c;
                customerData.deposit = contactRecord?.Deposit__c;
                ToolboxOutboundService.tbxCustomerMap.put(customerKey, customerData);
            }
        }
    }

    @testVisible
    private static List<Account> getWorkflowUpdatedAccounts(List<Account> accounts) {
        List<Account> validAccounts = new List<Account>();

        for (Account acc : accounts) {
            // Skip duplicate accounts (ending with " - Duplicate")
            if (acc.Name != null && acc.Name.endsWith(' - Duplicate')) {
                continue;
            }
            if (acc.IsLeadActive__c == true && acc.Lendi_Customer_Uuid__c != null) {
                validAccounts.add(acc);
            }
        }

        return validAccounts;
    }

    private void publishToolboxAccountEvent(Boolean isInsert) {
        List<Account> accountsToProcess = new List<Account>();
        Set<Id> customerRecordTypeIds = Utils.extractIdFieldSet(
            RecordTypesSelector.newInstance()
                .getBySObjectAndDevNames('Account', new Set<String>{ Accounts.CUSTOMER_RECORD_TYPE, Accounts.LEGACY_AUSSIE_RECORD_TYPE }),
            'Id'
        );
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = isInsert ? null : (Account) existingRecords.get(accountRecord.Id);
            if (
                accountRecord.Brand__c == Contacts.BRAND_AUSSIE &&
                customerRecordTypeIds.contains(accountRecord.RecordTypeId) &&
                Utils.hasAnyFieldChanged(oldAccount, accountRecord, new List<String>{ 'External_Id__c', 'Restriction_Status__c', 'Store__c' })
            ) {
                accountsToProcess.add(accountRecord);
            }
        }

        if (accountsToProcess.isEmpty() == false) {
            ToolboxOutboundService.publishToolboxAccountEventsDeferred(
                isInsert ? Event.EventType.RECORD_CREATED : Event.EventType.RECORD_UPDATED,
                Utils.extractIdFieldSet(accountsToProcess, 'Id')
            );
        }
    }

    private void publishStoreMessage(Boolean isInsert) {
        Set<Id> storeAccountIdSet = new Set<Id>();
        Id storeRecordTypeId = Utils.getRecordTypeId('Account', Accounts.STORE_RECORD_TYPE);

        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = isInsert ? null : (Account) existingRecords.get(accountRecord.Id);
            if (
                accountRecord.Brand__c == Contacts.BRAND_AUSSIE &&
                accountRecord.RecordTypeId == storeRecordTypeId &&
                accountRecord.Store_Status__c == Accounts.STORE_STATUS_ACTIVE &&
                Utils.hasAnyFieldChanged(
                    oldAccount,
                    accountRecord,
                    new List<String>{
                        'Name',
                        'Phone',
                        'Email__c',
                        'ALI_Company_Auth_Rep_Number_Store__c',
                        'Contractual_Entity_Store__c',
                        'Fax',
                        'BillingStreet',
                        'BillingCity',
                        'BillingState',
                        'BillingCountry',
                        'BillingPostalCode',
                        'BillingLatitude',
                        'BillingLongitude',
                        'Restriction_Status__c',
                        'Store_Opt_In_Status__c'
                    }
                )
            ) {
                storeAccountIdSet.add(accountRecord.Id);
            }
        }

        if (storeAccountIdSet.isEmpty() == false) {
            CMSService.publishCmsStoreEvent(storeAccountIdSet, isInsert ? Event.EventType.RECORD_CREATED : Event.EventType.RECORD_UPDATED);
        }
    }

    private void publishTeamMemberEvent() {
        List<Account> accountList = new List<Account>(
            (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Restriction_Status__c })
        );
        if (accountList.isEmpty() == false) {
            Set<Id> accountIdSet = new Set<Id>();
            Id storeRecordTypeId = Utils.getRecordTypeId('Account', Accounts.STORE_RECORD_TYPE);
            for (Account accountRecord : accountList) {
                if (accountRecord.Restriction_Status__c != null && accountRecord.RecordTypeId == storeRecordTypeId) {
                    accountIdSet.add(accountRecord.Id);
                }
            }
            if (accountIdSet.isEmpty()) {
                return;
            }
            List<Contact> contactList = ContactsSelector.newInstance().selectByAccountId(accountIdSet);
            Set<Id> contactIdSet = Utils.extractIdFieldSet(contactList, 'Id');
            ContactService.publishTeamMemberEvent(contactIdSet, Event.EventType.RECORD_UPDATED, true);
        }
    }

    private void validateStoreTerritory(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert ? (List<Account>) getRecords() : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store_Territory__c })
        );

        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).validateStoreTerritory();
        }
    }

    private void populatePreviousOwner(Map<Id, SObject> existingRecords) {
        List<Account> recordsToProcess = new List<Account>((List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId }));
        if (recordsToProcess.isEmpty()) {
            return;
        }
        Id brokerRTypeId = RecordTypesSelector.newInstance().getBySObjectAndDevName('Contact', Contacts.BROKER_RECORD_TYPE).Id;
        List<Account> oldAccountList = new List<Account>();
        for (Account newAccount : recordsToProcess) {
            oldAccountList.add((Account) existingRecords.get(newAccount.Id));
        }
        Set<Id> userIdSet = Utils.extractIdFieldSet(oldAccountList, 'OwnerId');
        Map<Id, Contact> userIdByBroker = ContactsSelector.newInstance().selectByLinkedUserId(userIdSet, brokerRTypeId);

        for (Account accountRecord : recordsToProcess) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);

            if (userIdByBroker.containsKey(oldAccount.OwnerId)) {
                accountRecord.Previous_Owner__c = oldAccount.OwnerId;
            }
        }
    }

    private void populatePreviousStore(Map<Id, SObject> existingRecords) {
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);

            if (oldAccount.Store__c == accountRecord.Store__c) {
                continue;
            }
            accountRecord.Previous_Store__c = oldAccount.Store__c;
        }
    }

    private void clearPrimaryStore(Map<Id, SObject> existingRecords) {
        if (FeatureFlagCustomMetadata.getFeatureFlag('Enable_Appointment_Overflow') == false) {
            return;
        }
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccount = (Account) existingRecords.get(accountRecord.Id);

            if (oldAccount.Store__c == accountRecord.Store__c) {
                continue;
            }
            if (oldAccount.Store__c == AccountsSelector.newInstance().getOverflowStore().Id) {
                // Clear primary store if the customer changes from overflow to any other store
                accountRecord.Primary_Store__c = null;
            }
            accountRecord.Previous_Store__c = oldAccount.Store__c;
        }
    }

    private void syncStoreAccountRecordsToAussieforce(Boolean isInsert) {
        Set<Schema.SObjectField> changedFieldsSet = new Set<Schema.SobjectField>();
        changedFieldsSet.addAll(AussieforceSyncOutServiceImpl.ACCOUNT_TYPE_HEAD_OFFICE_SYNC_FIELDS);
        changedFieldsSet.addAll(AussieforceSyncOutServiceImpl.ACCOUNT_TYPE_MINI_REGION_SYNC_FIELDS);
        changedFieldsSet.addAll(AussieforceSyncOutServiceImpl.ACCOUNT_TYPE_RETAIL_SYNC_FIELDS);

        Id storeRecordTypeId = Utils.getRecordTypeId('Account', Accounts.STORE_RECORD_TYPE);

        //Only process store records where fields for sync have changed
        List<Account> accountRecordsToProcess = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            Account oldAccountRecord = isInsert ? null : (Account) existingRecords.get(accountRecord.Id);
            if (accountRecord.RecordTypeId == storeRecordTypeId && Utils.hasAnyFieldChanged(oldAccountRecord, accountRecord, changedFieldsSet)) {
                accountRecordsToProcess.add(accountRecord);
            }
        }

        if (accountRecordsToProcess.isEmpty() == false) {
            AussieforceSyncOutService.syncStoreAccountRecords(accountRecordsToProcess);
        }
    }

    private void setDefaulUser(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert ? (List<Account>) getRecords() : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.OwnerId })
        );
        if (recordsToProcess.isEmpty()) {
            return;
        }
        Utils.setDefaultUser(recordsToProcess, 'Account');
    }

    private void updateDisabledAccount() {
        Id legacyLendiRecordType = Utils.getRecordTypeId('Account', Accounts.LEGACY_LENDI_RECORD_TYPE);
        List<Account> disabledAccountList = (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Is_Disabled__c });
        for (Account accountRecord : disabledAccountList) {
            if (accountRecord.Is_Disabled__c == true) {
                accountRecord.RecordTypeId = legacyLendiRecordType;
            }
        }
    }

    private void updateDisabledRecords() {
        List<Account> changedAccountList = (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Is_Disabled__c });
        if (changedAccountList.isEmpty() == false) {
            AccountService.updateDisabledRecords(changedAccountList);
        }
    }

    private void setIsNationalMarketPlace(Boolean isInsert) {
        List<Account> recordsToProcess = new List<Account>(
            isInsert ? (List<Account>) getRecords() : (List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c })
        );
        if (recordsToProcess.isEmpty() == false) {
            Accounts.newInstance(recordsToProcess).setIsNationalMarketPlace();
        }
    }

    private void enableSuburbRouting() {
        List<Account> recordsToProcess = new List<Account>((List<Account>) getChangedRecords(new Set<Schema.SObjectField>{ Account.Store__c }));
        Accounts.newInstance(recordsToProcess).enableSuburbRouting();
    }

    private Boolean isDuplicateAccount(Account acc) {
        return acc.Name != null && acc.Name.endsWith(' - Duplicate');
    }
}