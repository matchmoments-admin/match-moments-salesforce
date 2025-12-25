/**
 * @description Entry Point Controller for ESPN Quick Actions
 * 
 * FFLIB PATTERN: Entry points create UOW → call services → commit once
 * This controller is the ONLY place that creates and commits UOW
 * 
 * @author Brendan Milton
 * @date 2025-12-05
 */
public with sharing class ESPNActionControllerV2 {
    
    /**
     * @description Main entry point for Quick Actions
     * Creates UOW, calls appropriate service method, commits once
     * 
     * @param recordId The record ID of the triggering record
     * @param objectType The object type (Account, Contact, Match__c, Competition__c)
     * @return ESPNSyncResult Result of the operation
     */
    @AuraEnabled
    public static ESPNSyncResult getSportData(Id recordId, String objectType) {
        fflib_ISObjectUnitOfWork uow = null;
        ESPNSyncResult result;
        
        try {
            // 1. CREATE UOW (Entry point responsibility)
            uow = Application.createUOW();
            
            // 2. Get service instance
            IESPNSyncService syncService = ESPNSyncServiceImpl.newInstance();
            
            // 3. Route to appropriate service method based on object type
            if (objectType == 'Account') {
                result = syncService.syncTeam(recordId, uow);
                
            } else if (objectType == 'Contact') {
                result = syncService.syncPlayer(recordId, uow);
                
            } else if (objectType == 'Match__c') {
                result = syncService.syncFixture(recordId, uow);
                
            } else if (objectType == 'Competition__c') {
                result = syncService.syncCompetitionFixtures(recordId, uow);
                
            } else if (objectType == 'Opportunity') {
                // Legacy support - convert to new pattern
                result = handleLegacyOpportunity(recordId, uow);
                
            } else if (objectType == 'Opportunity_Group__c') {
                // Legacy support - convert to new pattern
                result = handleLegacyOpportunityGroup(recordId, uow);
                
            } else {
                result = ESPNSyncResult.failure('Unsupported object type: ' + objectType);
            }
            
            // 4. COMMIT UOW (Entry point responsibility) - ONLY if successful
            if (result != null && result.success) {
                uow.commitWork();
            }
            
        } catch (DmlException ex) {
            System.debug(LoggingLevel.ERROR, 'ESPNActionControllerV2 DML Exception: ' + ex.getMessage());
            result = ESPNSyncResult.failure('DML Error: ' + ex.getDmlMessage(0));
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ESPNActionControllerV2 Exception: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + ex.getStackTraceString());
            result = ESPNSyncResult.failure('Error: ' + ex.getMessage());
            
        } finally {
            // 5. CLEANUP UOW CONTEXT (Always, even on error)
            Application.clearUOW();
        }
        
        return result;
    }
    
    /**
     * @description Sync team data for an Account
     * Convenience method with implicit UOW management
     * @param accountId Account record ID
     * @return ESPNSyncResult
     */
    @AuraEnabled
    public static ESPNSyncResult syncTeam(Id accountId) {
        return getSportData(accountId, 'Account');
    }
    
    /**
     * @description Sync player data for a Contact
     * Convenience method with implicit UOW management
     * @param contactId Contact record ID
     * @return ESPNSyncResult
     */
    @AuraEnabled
    public static ESPNSyncResult syncPlayer(Id contactId) {
        return getSportData(contactId, 'Contact');
    }
    
    /**
     * @description Sync fixture data for a Match__c
     * Convenience method with implicit UOW management
     * @param fixtureId Match__c record ID
     * @return ESPNSyncResult
     */
    @AuraEnabled
    public static ESPNSyncResult syncFixture(Id fixtureId) {
        return getSportData(fixtureId, 'Match__c');
    }
    
    /**
     * @description Sync fixtures for a Competition__c
     * Convenience method with implicit UOW management
     * @param competitionId Competition__c record ID
     * @return ESPNSyncResult
     */
    @AuraEnabled
    public static ESPNSyncResult syncCompetitionFixtures(Id competitionId) {
        return getSportData(competitionId, 'Competition__c');
    }
    
    /**
     * @description Bulk sync multiple teams
     * @param teamIds List of Account record IDs
     * @return List<ESPNSyncResult>
     */
    @AuraEnabled
    public static List<ESPNSyncResult> syncTeamsBulk(List<Id> teamIds) {
        fflib_ISObjectUnitOfWork uow = null;
        List<ESPNSyncResult> results = new List<ESPNSyncResult>();
        
        try {
            uow = Application.createUOW();
            IESPNSyncService syncService = ESPNSyncServiceImpl.newInstance();
            
            results = syncService.syncTeams(new Set<Id>(teamIds), uow);
            
            // Check if any succeeded
            Boolean anySuccess = false;
            for (ESPNSyncResult result : results) {
                if (result.success) {
                    anySuccess = true;
                    break;
                }
            }
            
            if (anySuccess) {
                uow.commitWork();
            }
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ESPNActionControllerV2.syncTeamsBulk error: ' + ex.getMessage());
            results.add(ESPNSyncResult.failure('Bulk sync error: ' + ex.getMessage()));
            
        } finally {
            Application.clearUOW();
        }
        
        return results;
    }
    
    // =========================================================================
    // LEGACY SUPPORT METHODS
    // =========================================================================
    
    /**
     * @description Handle legacy Opportunity sync (maps to new Fixture pattern)
     * @param opportunityId Opportunity record ID
     * @param uow Unit of Work
     * @return ESPNSyncResult
     */
    private static ESPNSyncResult handleLegacyOpportunity(Id opportunityId, fflib_ISObjectUnitOfWork uow) {
        try {
            Opportunity opp = [
                SELECT Id, Name, ESPN_ID__c, Opportunity_Group__r.Sport__c, Opportunity_Group__r.ESPN_League_ID__c
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            String sportType = (opp.Opportunity_Group__c != null && opp.Opportunity_Group__r.Sport__c != null)
                ? opp.Opportunity_Group__r.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = (opp.Opportunity_Group__c != null && opp.Opportunity_Group__r.ESPN_League_ID__c != null)
                ? opp.Opportunity_Group__r.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            String eventId = opp.ESPN_ID__c;
            
            if (String.isBlank(eventId)) {
                return ESPNSyncResult.failure('ESPN_ID__c is required on the Opportunity', opportunityId);
            }
            
            // Get live feed from ESPN
            ESPNHttpService.ESPNLiveFeedResponse response = ESPNHttpService.getLiveFeed(espnSport, leagueCode, eventId);
            
            if (!response.success) {
                return ESPNSyncResult.failure('ESPN API error: ' + response.errorMessage, opportunityId);
            }
            
            // Update Opportunity
            Opportunity updatedOpp = new Opportunity(
                Id = opportunityId,
                Home_Score_Total__c = response.homeScore != null ? Decimal.valueOf(response.homeScore) : null,
                Away_Score_Total__c = response.awayScore != null ? Decimal.valueOf(response.awayScore) : null,
                Match_Status__c = response.matchStatus
            );
            
            if (String.isNotBlank(response.currentPeriod)) {
                updatedOpp.Current_Period__c = response.currentPeriod;
            }
            
            uow.registerDirty(updatedOpp);
            
            return ESPNSyncResult.success('Opportunity updated', opportunityId)
                .withData(JSON.serialize(response));
            
        } catch (Exception e) {
            return ESPNSyncResult.failure('Error: ' + e.getMessage(), opportunityId);
        }
    }
    
    /**
     * @description Handle legacy Opportunity_Group__c sync (maps to new Competition pattern)
     * @param oppGroupId Opportunity_Group__c record ID
     * @param uow Unit of Work
     * @return ESPNSyncResult
     */
    private static ESPNSyncResult handleLegacyOpportunityGroup(Id oppGroupId, fflib_ISObjectUnitOfWork uow) {
        try {
            Opportunity_Group__c oppGroup = [
                SELECT Id, Name, Sport__c, ESPN_League_ID__c 
                FROM Opportunity_Group__c 
                WHERE Id = :oppGroupId 
                LIMIT 1
            ];
            
            String sportType = String.isNotBlank(oppGroup.Sport__c) ? oppGroup.Sport__c : 'Soccer';
            String espnSport = SportUtils.normalizeSportForESPN(sportType);
            String leagueCode = String.isNotBlank(oppGroup.ESPN_League_ID__c) 
                ? oppGroup.ESPN_League_ID__c : SportUtils.getDefaultLeagueCode(sportType);
            
            // Get fixtures from ESPN
            Date today = Date.today();
            String dateStr = today.year() + String.valueOf(today.month()).leftPad(2, '0') + String.valueOf(today.day()).leftPad(2, '0');
            
            ESPNHttpService.ESPNScoreboardResponse response = ESPNHttpService.getFixtures(espnSport, leagueCode, dateStr);
            
            if (!response.success || response.events == null || response.events.isEmpty()) {
                return ESPNSyncResult.failure(
                    response.errorMessage != null ? response.errorMessage : 'No fixtures found',
                    oppGroupId
                );
            }
            
            // Get sport handler
            ISportDataHandler handler = SportUtils.getSportHandler(sportType);
            
            // Create Opportunity records for each fixture
            List<Opportunity> fixtures = new List<Opportunity>();
            
            for (ESPNHttpService.ESPNEvent event : response.events) {
                Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(event));
                Opportunity fixture = handler.mapFixture(eventMap, oppGroupId);
                fixtures.add(fixture);
            }
            
            // Register all with UOW
            for (Opportunity opp : fixtures) {
                if (opp.Id != null) {
                    uow.registerDirty(opp);
                } else {
                    uow.registerNew(opp);
                }
            }
            
            return ESPNSyncResult.success('Created/Updated ' + fixtures.size() + ' fixtures', oppGroupId)
                .withCounts(fixtures.size(), fixtures.size(), 0);
            
        } catch (Exception e) {
            return ESPNSyncResult.failure('Error: ' + e.getMessage(), oppGroupId);
        }
    }
}

