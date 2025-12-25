/**
 * @description Selector implementation for Season__c
 * Data access layer - queries only, no business logic, no DML
 * @author AI Assistant
 * @date 2025-12-24
 */
public inherited sharing class SeasonsSelector extends fflib_SObjectSelector {
    
    /**
     * @description Factory method to create new instance
     * @return SeasonsSelector New selector instance
     */
    public static SeasonsSelector newInstance() {
        return (SeasonsSelector) Application.Selector.newInstance(Season__c.SObjectType);
    }
    
    /**
     * @description Define the SObject type for this selector
     * @return SObjectType for Season__c
     */
    public Schema.SObjectType getSObjectType() {
        return Season__c.SObjectType;
    }
    
    /**
     * @description Define the default fields to query
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Season__c.Id,
            Season__c.Name,
            Season__c.Start_Date__c,
            Season__c.End_Date__c,
            Season__c.Sport__c,
            Season__c.Season_Type__c
        };
    }
    
    /**
     * @description Select seasons by record IDs
     * @param seasonIds Set of Season__c record IDs
     * @return List of Season__c records
     */
    public List<Season__c> selectById(Set<Id> seasonIds) {
        return (List<Season__c>) selectSObjectsById(seasonIds);
    }
    
    /**
     * @description Select seasons by name
     * @param names Set of season names
     * @return List of Season__c records
     */
    public List<Season__c> selectByName(Set<String> names) {
        return Database.query(
            newQueryFactory()
                .setCondition('Name IN :names')
                .toSOQL()
        );
    }
    
    /**
     * @description Select seasons by sport
     * @param sportType Sport to filter by
     * @return List of Season__c records
     */
    public List<Season__c> selectBySport(String sportType) {
        return Database.query(
            newQueryFactory()
                .setCondition('Sport__c = :sportType')
                .toSOQL()
        );
    }
    
    /**
     * @description Select currently active season
     * @return List of Season__c records (current season)
     */
    public List<Season__c> selectActiveSeason() {
        Date today = Date.today();
        return Database.query(
            newQueryFactory()
                .setCondition('Start_Date__c <= :today AND End_Date__c >= :today')
                .toSOQL()
        );
    }
}

