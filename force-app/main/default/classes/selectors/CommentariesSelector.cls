/**
 * @description Selector for Commentary__c
 * @deprecated This selector references the legacy Commentary__c object which has been superseded by Match_Moment__c.
 *             The Commentary__c.Fixture__c field should be updated to reference Match__c instead of the old Fixture__c object.
 *             Consider using MatchMomentsSelector for new development.
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class CommentariesSelector extends fflib_SObjectSelector {
    
    public static CommentariesSelector newInstance() {
        return (CommentariesSelector) Application.Selector.newInstance(Commentary__c.SObjectType);
    }
    
    public Schema.SObjectType getSObjectType() {
        return Commentary__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Commentary__c.Id,
            Commentary__c.Name,
            Commentary__c.Fixture__c,
            Commentary__c.Goals_Home__c,
            Commentary__c.Goals_Away__c
        };
    }
    
    public List<Commentary__c> selectById(Set<Id> ids) {
        return (List<Commentary__c>) selectSObjectsById(ids);
    }
    
    /**
     * @description Select commentaries by fixture IDs (legacy - Commentary__c uses Fixture__c, not Match__c)
     * @param fixtureIds Set of Fixture__c record IDs
     * @return Map of Fixture__c Id -> Commentary__c
     */
    public Map<Id, Commentary__c> selectByFixtureIds(Set<Id> fixtureIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Fixture__c IN :fixtureIds');
        
        List<Commentary__c> commentaries = (List<Commentary__c>) Database.query(query.toSOQL());
        
        Map<Id, Commentary__c> result = new Map<Id, Commentary__c>();
        for (Commentary__c comm : commentaries) {
            result.put(comm.Fixture__c, comm);
        }
        
        return result;
    }
}

