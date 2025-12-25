/**
 * @description Selector implementation for Award__c
 * Data access layer - queries only, no business logic, no DML
 * @author AI Assistant
 * @date 2025-12-24
 */
public inherited sharing class AwardsSelector extends fflib_SObjectSelector {
    
    /**
     * @description Factory method to create new instance
     * @return AwardsSelector New selector instance
     */
    public static AwardsSelector newInstance() {
        return (AwardsSelector) Application.Selector.newInstance(Award__c.SObjectType);
    }
    
    /**
     * @description Define the SObject type for this selector
     * @return SObjectType for Award__c
     */
    public Schema.SObjectType getSObjectType() {
        return Award__c.SObjectType;
    }
    
    /**
     * @description Define the default fields to query
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Award__c.Id,
            Award__c.Name,
            Award__c.Player__c,
            Award__c.Team__c,
            Award__c.Competition__c,
            Award__c.Season__c,
            Award__c.Award_Type__c,
            Award__c.Award_Category__c,
            Award__c.Year__c,
            Award__c.Season_Name__c,
            Award__c.Count__c,
            Award__c.Details__c,
            Award__c.Rank__c,
            Award__c.Sport__c,
            Award__c.Icon_URL__c,
            Award__c.Sort_Order__c
        };
    }
    
    /**
     * @description Select awards by record IDs
     * @param awardIds Set of Award__c record IDs
     * @return List of Award__c records
     */
    public List<Award__c> selectById(Set<Id> awardIds) {
        return (List<Award__c>) selectSObjectsById(awardIds);
    }
    
    /**
     * @description Select awards by player ID
     * @param playerIds Set of Contact (player) IDs
     * @return List of Award__c records
     */
    public List<Award__c> selectByPlayerId(Set<Id> playerIds) {
        return Database.query(
            newQueryFactory()
                .setCondition('Player__c IN :playerIds')
                .setOrdering('Sort_Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL()
        );
    }
    
    /**
     * @description Select awards by team ID
     * @param teamIds Set of Account (team) IDs
     * @return List of Award__c records
     */
    public List<Award__c> selectByTeamId(Set<Id> teamIds) {
        return Database.query(
            newQueryFactory()
                .setCondition('Team__c IN :teamIds')
                .toSOQL()
        );
    }
    
    /**
     * @description Select awards by season ID
     * @param seasonIds Set of Season__c IDs
     * @return List of Award__c records
     */
    public List<Award__c> selectBySeasonId(Set<Id> seasonIds) {
        return Database.query(
            newQueryFactory()
                .setCondition('Season__c IN :seasonIds')
                .toSOQL()
        );
    }
    
    /**
     * @description Select awards by category
     * @param category Award category picklist value
     * @return List of Award__c records
     */
    public List<Award__c> selectByCategory(String category) {
        return Database.query(
            newQueryFactory()
                .setCondition('Award_Category__c = :category')
                .toSOQL()
        );
    }
}

