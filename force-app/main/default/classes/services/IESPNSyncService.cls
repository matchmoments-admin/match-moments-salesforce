/**
 * @description Interface for ESPN Sync Service
 * Defines all ESPN synchronization operations
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IESPNSyncService {
    
    /**
     * @description Sync team data from ESPN
     * @param teamId Account (Team) record ID
     * @param uow Unit of Work instance (passed from entry point)
     * @return ESPNSyncResult with operation outcome
     */
    ESPNSyncResult syncTeam(Id teamId, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Sync player data from ESPN
     * @param playerId Contact (Player) record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    ESPNSyncResult syncPlayer(Id playerId, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Sync fixture data from ESPN
     * @param fixtureId Fixture__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    ESPNSyncResult syncFixture(Id fixtureId, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Sync all fixtures for a competition from ESPN
     * @param competitionId Competition__c record ID
     * @param uow Unit of Work instance
     * @return ESPNSyncResult with operation outcome
     */
    ESPNSyncResult syncCompetitionFixtures(Id competitionId, fflib_ISObjectUnitOfWork uow);
    
    /**
     * @description Bulk sync multiple teams
     * @param teamIds Set of Account (Team) record IDs
     * @param uow Unit of Work instance
     * @return List of ESPNSyncResult for each team
     */
    List<ESPNSyncResult> syncTeams(Set<Id> teamIds, fflib_ISObjectUnitOfWork uow);
}

