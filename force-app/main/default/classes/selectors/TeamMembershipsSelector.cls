/**
 * @description Selector implementation for Team_Membership__c
 * Data access layer - queries only, no business logic, no DML
 * @author AI Assistant
 * @date 2025-12-24
 */
public inherited sharing class TeamMembershipsSelector extends fflib_SObjectSelector {
    
    /**
     * @description Factory method to create new instance
     * @return TeamMembershipsSelector New selector instance
     */
    public static TeamMembershipsSelector newInstance() {
        return (TeamMembershipsSelector) Application.Selector.newInstance(Team_Membership__c.SObjectType);
    }
    
    /**
     * @description Define the SObject type for this selector
     * @return SObjectType for Team_Membership__c
     */
    public Schema.SObjectType getSObjectType() {
        return Team_Membership__c.SObjectType;
    }
    
    /**
     * @description Define the default fields to query
     * @return List of SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Team_Membership__c.Id,
            Team_Membership__c.Name,
            Team_Membership__c.Player__c,
            Team_Membership__c.Team__c,
            Team_Membership__c.Start_Date__c,
            Team_Membership__c.End_Date__c,
            Team_Membership__c.Status__c,
            Team_Membership__c.Jersey_Number__c,
            Team_Membership__c.Position__c,
            Team_Membership__c.Transfer_Fee__c,
            Team_Membership__c.Loan_Fee__c
        };
    }
    
    /**
     * @description Select memberships by record IDs
     * @param membershipIds Set of Team_Membership__c record IDs
     * @return List of Team_Membership__c records
     */
    public List<Team_Membership__c> selectById(Set<Id> membershipIds) {
        return (List<Team_Membership__c>) selectSObjectsById(membershipIds);
    }
    
    /**
     * @description Select memberships by player ID
     * @param playerIds Set of Contact (player) IDs
     * @return List of Team_Membership__c records
     */
    public List<Team_Membership__c> selectByPlayerId(Set<Id> playerIds) {
        return Database.query(
            newQueryFactory()
                .setCondition('Player__c IN :playerIds')
                .setOrdering('Start_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }
    
    /**
     * @description Select memberships by team ID
     * @param teamIds Set of Account (team) IDs
     * @return List of Team_Membership__c records
     */
    public List<Team_Membership__c> selectByTeamId(Set<Id> teamIds) {
        return Database.query(
            newQueryFactory()
                .setCondition('Team__c IN :teamIds')
                .toSOQL()
        );
    }
    
    /**
     * @description Select active memberships by player ID
     * @param playerIds Set of Contact (player) IDs
     * @return List of Team_Membership__c records
     */
    public List<Team_Membership__c> selectActiveByPlayerId(Set<Id> playerIds) {
        String activeStatus = 'Active';
        return Database.query(
            newQueryFactory()
                .setCondition('Player__c IN :playerIds AND Status__c = :activeStatus')
                .toSOQL()
        );
    }
    
    /**
     * @description Select career history for a player
     * @param playerId Contact (player) ID
     * @return List of Team_Membership__c records ordered by date
     */
    public List<Team_Membership__c> selectCareerHistory(Id playerId) {
        return Database.query(
            newQueryFactory()
                .setCondition('Player__c = :playerId')
                .setOrdering('Start_Date__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL()
        );
    }
}

