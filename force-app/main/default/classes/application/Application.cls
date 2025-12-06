/**
 * @description Application Factory - Central dependency injection container
 * Following FFLib Apex Enterprise Patterns
 * @see https://github.com/apex-enterprise-patterns/fflib-apex-common
 * @author Brendan Milton
 * @date 2025-12-05
 */
public class Application {
    
    // UOW Context - Static variable at outer class level (Apex requirement)
    private static fflib_ISObjectUnitOfWork currentUOW;
    
    /**
     * @description Configure and create the UnitOfWork factory
     * Order matters! Parent objects should be registered before children
     */
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork = 
        new fflib_Application.UnitOfWorkFactory(
            new List<SObjectType>{
                // Standard Objects (Parents first)
                Account.SObjectType,
                Contact.SObjectType,
                
                // Custom Objects - Level 1 (No dependencies)
                Competition__c.SObjectType,
                
                // Custom Objects - Level 2 (Depend on Level 1)
                Fixture__c.SObjectType,
                Team_Season_Stats__c.SObjectType,
                Player_Season_Stats__c.SObjectType,
                
                // Custom Objects - Level 3 (Depend on Level 2)
                Fixture_Period__c.SObjectType,
                Fixture_Participation__c.SObjectType,
                Commentary__c.SObjectType,
                Lineup__c.SObjectType,
                
                // Custom Objects - Level 4 (Depend on Level 3)
                Commentary_Event__c.SObjectType,
                
                // Custom Objects - Level 5 (Depend on Level 4)
                Social_Engagement__c.SObjectType,
                
                // News (Can reference any)
                News_Article__c.SObjectType
            }
        );
    
    /**
     * @description Configure and create the Selector factory
     * Maps SObjectType to Selector implementation
     */
    public static final fflib_Application.SelectorFactory Selector = 
        new fflib_Application.SelectorFactory(
            new Map<SObjectType, Type>{
                // Standard Objects
                Account.SObjectType => TeamsSelector.class,
                Contact.SObjectType => PlayersSelector.class,
                
                // Custom Objects
                Competition__c.SObjectType => CompetitionsSelector.class,
                Fixture__c.SObjectType => FixturesSelector.class,
                Fixture_Period__c.SObjectType => FixturePeriodsSelector.class,
                Fixture_Participation__c.SObjectType => FixtureParticipationsSelector.class,
                Commentary__c.SObjectType => CommentariesSelector.class,
                Commentary_Event__c.SObjectType => CommentaryEventsSelector.class,
                Social_Engagement__c.SObjectType => SocialEngagementsSelector.class,
                Team_Season_Stats__c.SObjectType => TeamSeasonStatsSelector.class,
                Player_Season_Stats__c.SObjectType => PlayerSeasonStatsSelector.class
            }
        );
    
    /**
     * @description Configure and create the Domain factory
     * Maps SObjectType to Domain implementation constructor
     */
    public static final fflib_Application.DomainFactory Domain = 
        new fflib_Application.DomainFactory(
            Application.Selector,
            new Map<SObjectType, Type>{
                // Standard Objects
                Account.SObjectType => Teams.Constructor.class,
                Contact.SObjectType => Players.Constructor.class,
                
                // Custom Objects
                Competition__c.SObjectType => Competitions.Constructor.class,
                Fixture__c.SObjectType => Fixtures.Constructor.class,
                Commentary_Event__c.SObjectType => CommentaryEvents.Constructor.class,
                Social_Engagement__c.SObjectType => SocialEngagements.Constructor.class
            }
        );
    
    /**
     * @description Configure and create the Service factory
     * Maps Service interface to implementation
     */
    public static final fflib_Application.ServiceFactory Service = 
        new fflib_Application.ServiceFactory(
            new Map<Type, Type>{
                IESPNSyncService.class => ESPNSyncServiceImpl.class,
                ISocialSharingService.class => SocialSharingServiceImpl.class,
                IEngagementService.class => EngagementServiceImpl.class
            }
        );
    
    // =========================================================================
    // UOW CONTEXT METHODS - Must be at outer class level due to static restriction
    // =========================================================================
    
    /**
     * @description Create a new UOW for this transaction
     * Should ONLY be called from entry points (controllers, triggers, batch)
     * @return The new UnitOfWork instance
     */
    public static fflib_ISObjectUnitOfWork createUOW() {
        if (currentUOW != null) {
            System.debug(LoggingLevel.WARN, 'UOW already exists in context. Returning existing UOW.');
            return currentUOW;
        }
        currentUOW = Application.UnitOfWork.newInstance();
        return currentUOW;
    }
    
    /**
     * @description Get the current UOW for this transaction
     * Services and helpers should use this, never create their own
     * @return The current UnitOfWork instance
     */
    public static fflib_ISObjectUnitOfWork getUOW() {
        if (currentUOW == null) {
            System.debug(LoggingLevel.WARN, 'No UOW in context. Creating new UOW.');
            currentUOW = Application.UnitOfWork.newInstance();
        }
        return currentUOW;
    }
    
    /**
     * @description Check if a UOW exists in the current context
     * @return Boolean indicating if UOW exists
     */
    public static Boolean hasUOW() {
        return currentUOW != null;
    }
    
    /**
     * @description Remove and return the current UOW
     * Call this in finally block after commitWork()
     * @return The UOW that was removed
     */
    public static fflib_ISObjectUnitOfWork clearUOW() {
        fflib_ISObjectUnitOfWork uow = currentUOW;
        currentUOW = null;
        return uow;
    }
    
    /**
     * @description Commit work and clean up context
     * Convenience method for entry points
     */
    public static void commitAndClear() {
        if (currentUOW != null) {
            try {
                currentUOW.commitWork();
            } finally {
                currentUOW = null;
            }
        }
    }
}
