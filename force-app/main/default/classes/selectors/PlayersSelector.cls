/**
 * @description Selector implementation for Contact (Players)
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class PlayersSelector extends fflib_SObjectSelector implements IPlayersSelector {
    
    public static IPlayersSelector newInstance() {
        return (IPlayersSelector) Application.Selector.newInstance(Contact.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Contact.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Contact.Id,
            Contact.FirstName,
            Contact.LastName,
            Contact.Name,
            Contact.ESPN_Player_ID__c,
            Contact.Current_Team__c,
            Contact.Position__c,
            Contact.Jersey_Number__c,
            Contact.Player_Role__c,
            Contact.Profile_Image_URL__c,
            Contact.Date_of_Birth__c,
            Contact.Nationality__c,
            Contact.Height__c,
            Contact.Weight__c
        };
    }
    
    public List<Contact> selectById(Set<Id> contactIds) {
        return (List<Contact>) selectSObjectsById(contactIds);
    }
    
    public List<Contact> selectByTeamIds(Set<Id> teamIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Current_Team__c IN :teamIds AND Player_Role__c = \'Player\'')
            .setOrdering('Jersey_Number__c', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Contact>) Database.query(query.toSOQL());
    }
    
    public List<Contact> selectByESPNPlayerIds(Set<String> espnPlayerIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('ESPN_Player_ID__c IN :espnPlayerIds');
        return (List<Contact>) Database.query(query.toSOQL());
    }
    
    public List<Contact> selectByIdWithTeam(Set<Id> contactIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Current_Team__r.Name')
            .selectField('Current_Team__r.ESPN_Team_ID__c')
            .selectField('Current_Team__r.Sport__c')
            .selectField('Current_Team__r.Logo_Url__c')
            .setCondition('Id IN :contactIds');
        return (List<Contact>) Database.query(query.toSOQL());
    }
}

