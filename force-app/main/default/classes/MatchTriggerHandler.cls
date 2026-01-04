/**
 * @description Trigger handler for Match__c record-level security enforcement
 * Enforces access control based on Match_Level__c and user permission sets
 * @author Brendan Milton
 * @date 2025-12-31
 */
public with sharing class MatchTriggerHandler {
    
    // Permission set names
    private static final String PROFESSIONAL_MATCH_ADMIN = 'Professional_Match_Admin';
    private static final String PROFESSIONAL_MATCH_USER = 'Professional_Match_User';
    private static final String AMATEUR_MATCH_ADMIN = 'Amateur_Match_Admin';
    private static final String AMATEUR_MATCH_USER = 'Amateur_Match_User';
    private static final String ESPN_INTERNAL_USERS = 'ESPN_Internal_Users';
    
    // Match level values
    private static final String MATCH_LEVEL_PROFESSIONAL = 'Professional';
    private static final String MATCH_LEVEL_SEMI_PROFESSIONAL = 'Semi-Professional';
    private static final String MATCH_LEVEL_AMATEUR = 'Amateur';
    
    // Cache user permission sets
    private static Set<String> userPermissionSets = null;
    
    /**
     * @description Main handler method called from trigger
     */
    public static void handle() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                validateInsert((List<Match__c>) Trigger.new);
            } else if (Trigger.isUpdate) {
                validateUpdate((List<Match__c>) Trigger.new, (Map<Id, Match__c>) Trigger.oldMap);
            } else if (Trigger.isDelete) {
                validateDelete((List<Match__c>) Trigger.old);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handleAfterInsert((List<Match__c>) Trigger.new);
            } else if (Trigger.isUpdate) {
                handleAfterUpdate((List<Match__c>) Trigger.new, (Map<Id, Match__c>) Trigger.oldMap);
            }
        }
    }
    
    /**
     * @description Validate insert operations
     * @param newMatches List of new Match__c records
     */
    private static void validateInsert(List<Match__c> newMatches) {
        Set<String> userPermSets = getUserPermissionSets();
        
        for (Match__c match : newMatches) {
            String matchLevel = match.Match_Level__c;
            
            // Skip validation for System Administrators or users with ESPN_Internal_Users
            if (isSystemAdmin() || userPermSets.contains(ESPN_INTERNAL_USERS)) {
                continue;
            }
            
            // Validate based on match level
            if (matchLevel == MATCH_LEVEL_PROFESSIONAL) {
                if (!userPermSets.contains(PROFESSIONAL_MATCH_ADMIN) && 
                    !userPermSets.contains(PROFESSIONAL_MATCH_USER)) {
                    match.addError('You do not have permission to create Professional matches. ' +
                                 'Please assign Professional_Match_Admin or Professional_Match_User permission set.');
                }
            } else if (matchLevel == MATCH_LEVEL_SEMI_PROFESSIONAL || matchLevel == MATCH_LEVEL_AMATEUR) {
                if (!userPermSets.contains(AMATEUR_MATCH_ADMIN) && 
                    !userPermSets.contains(AMATEUR_MATCH_USER)) {
                    match.addError('You do not have permission to create ' + matchLevel + ' matches. ' +
                                 'Please assign Amateur_Match_Admin or Amateur_Match_User permission set.');
                }
            }
        }
    }
    
    /**
     * @description Validate update operations
     * @param newMatches List of updated Match__c records
     * @param oldMap Map of old Match__c records
     */
    private static void validateUpdate(List<Match__c> newMatches, Map<Id, Match__c> oldMap) {
        Set<String> userPermSets = getUserPermissionSets();
        
        for (Match__c match : newMatches) {
            Match__c oldMatch = oldMap.get(match.Id);
            String newMatchLevel = match.Match_Level__c;
            String oldMatchLevel = oldMatch.Match_Level__c;
            
            // Skip validation for System Administrators or users with ESPN_Internal_Users
            if (isSystemAdmin() || userPermSets.contains(ESPN_INTERNAL_USERS)) {
                continue;
            }
            
            // Check if match level changed
            if (newMatchLevel != oldMatchLevel) {
                // Validate new match level access
                if (newMatchLevel == MATCH_LEVEL_PROFESSIONAL) {
                    if (!userPermSets.contains(PROFESSIONAL_MATCH_ADMIN)) {
                        match.addError('You do not have permission to change match level to Professional. ' +
                                     'Please assign Professional_Match_Admin permission set.');
                    }
                } else if (newMatchLevel == MATCH_LEVEL_SEMI_PROFESSIONAL || newMatchLevel == MATCH_LEVEL_AMATEUR) {
                    if (!userPermSets.contains(AMATEUR_MATCH_ADMIN)) {
                        match.addError('You do not have permission to change match level to ' + newMatchLevel + '. ' +
                                     'Please assign Amateur_Match_Admin permission set.');
                    }
                }
            } else {
                // Match level unchanged, validate based on current level
                if (newMatchLevel == MATCH_LEVEL_PROFESSIONAL) {
                    if (!userPermSets.contains(PROFESSIONAL_MATCH_ADMIN) && 
                        !userPermSets.contains(PROFESSIONAL_MATCH_USER)) {
                        match.addError('You do not have permission to edit Professional matches. ' +
                                     'Please assign Professional_Match_Admin or Professional_Match_User permission set.');
                    }
                } else if (newMatchLevel == MATCH_LEVEL_SEMI_PROFESSIONAL || newMatchLevel == MATCH_LEVEL_AMATEUR) {
                    if (!userPermSets.contains(AMATEUR_MATCH_ADMIN) && 
                        !userPermSets.contains(AMATEUR_MATCH_USER)) {
                        match.addError('You do not have permission to edit ' + newMatchLevel + ' matches. ' +
                                     'Please assign Amateur_Match_Admin or Amateur_Match_User permission set.');
                    }
                }
            }
        }
    }
    
    /**
     * @description Validate delete operations
     * @param oldMatches List of Match__c records being deleted
     */
    private static void validateDelete(List<Match__c> oldMatches) {
        Set<String> userPermSets = getUserPermissionSets();
        
        for (Match__c match : oldMatches) {
            String matchLevel = match.Match_Level__c;
            
            // Skip validation for System Administrators or users with ESPN_Internal_Users
            if (isSystemAdmin() || userPermSets.contains(ESPN_INTERNAL_USERS)) {
                continue;
            }
            
            // Validate based on match level
            if (matchLevel == MATCH_LEVEL_PROFESSIONAL) {
                if (!userPermSets.contains(PROFESSIONAL_MATCH_ADMIN)) {
                    match.addError('You do not have permission to delete Professional matches. ' +
                                 'Please assign Professional_Match_Admin permission set.');
                }
            } else if (matchLevel == MATCH_LEVEL_SEMI_PROFESSIONAL || matchLevel == MATCH_LEVEL_AMATEUR) {
                if (!userPermSets.contains(AMATEUR_MATCH_ADMIN)) {
                    match.addError('You do not have permission to delete ' + matchLevel + ' matches. ' +
                                 'Please assign Amateur_Match_Admin permission set.');
                }
            }
        }
    }
    
    /**
     * @description Get user's assigned permission sets
     * @return Set of permission set names
     */
    private static Set<String> getUserPermissionSets() {
        if (userPermissionSets != null) {
            return userPermissionSets;
        }
        
        userPermissionSets = new Set<String>();
        
        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.IsOwnedByProfile = false
        ];
        
        for (PermissionSetAssignment psa : assignments) {
            userPermissionSets.add(psa.PermissionSet.Name);
        }
        
        return userPermissionSets;
    }
    
    /**
     * @description Check if current user is System Administrator
     * @return Boolean indicating if user is System Admin
     */
    private static Boolean isSystemAdmin() {
        try {
            Profile userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
            return userProfile.Name == 'System Administrator';
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * @description Handle after insert - auto-resolve ESPN Event ID
     * @param newMatches List of new Match__c records
     */
    private static void handleAfterInsert(List<Match__c> newMatches) {
        Set<Id> matchesToResolve = new Set<Id>();
        
        for (Match__c match : newMatches) {
            // Only attempt auto-resolution if:
            // 1. ESPN_Event_ID__c is blank
            // 2. Match_Date_Time__c is set
            // 3. Competition__c is set
            // 4. At least one team is set
            // 5. Match is Professional level (or we can make it configurable)
            if (String.isBlank(match.ESPN_Event_ID__c) &&
                match.Match_Date_Time__c != null &&
                match.Competition__c != null &&
                (match.Home_Team__c != null || match.Away_Team__c != null)) {
                
                // Only auto-resolve for Professional matches to avoid unnecessary API calls
                // Can be expanded later if needed
                if (match.Match_Level__c == MATCH_LEVEL_PROFESSIONAL) {
                    matchesToResolve.add(match.Id);
                }
            }
        }
        
        if (!matchesToResolve.isEmpty()) {
            // Enqueue async job to resolve Event IDs (callouts not allowed in triggers)
            System.enqueueJob(new ESPNEventIdResolverQueueable(matchesToResolve));
            System.debug(LoggingLevel.INFO, 'MatchTriggerHandler: Enqueued ESPN Event ID resolution for ' + matchesToResolve.size() + ' match(es)');
        }
    }
    
    /**
     * @description Handle after update - auto-resolve ESPN Event ID if conditions changed
     * @param newMatches List of updated Match__c records
     * @param oldMap Map of old Match__c records
     */
    private static void handleAfterUpdate(List<Match__c> newMatches, Map<Id, Match__c> oldMap) {
        Set<Id> matchesToResolve = new Set<Id>();
        
        for (Match__c match : newMatches) {
            Match__c oldMatch = oldMap.get(match.Id);
            
            // Only attempt auto-resolution if:
            // 1. ESPN_Event_ID__c is blank (or was just cleared)
            // 2. One of the key fields changed (Match_Date_Time__c, Home_Team__c, Away_Team__c, Competition__c)
            // 3. Required fields are now set
            Boolean shouldResolve = String.isBlank(match.ESPN_Event_ID__c) &&
                match.Match_Date_Time__c != null &&
                match.Competition__c != null &&
                (match.Home_Team__c != null || match.Away_Team__c != null) &&
                match.Match_Level__c == MATCH_LEVEL_PROFESSIONAL;
            
            if (shouldResolve) {
                // Check if a relevant field changed
                // Also trigger if Match_Level__c changed to Professional (from null or other level)
                Boolean fieldChanged = 
                    match.Match_Date_Time__c != oldMatch.Match_Date_Time__c ||
                    match.Home_Team__c != oldMatch.Home_Team__c ||
                    match.Away_Team__c != oldMatch.Away_Team__c ||
                    match.Competition__c != oldMatch.Competition__c ||
                    match.Match_Level__c != oldMatch.Match_Level__c ||
                    (String.isNotBlank(oldMatch.ESPN_Event_ID__c) && String.isBlank(match.ESPN_Event_ID__c));
                
                if (fieldChanged) {
                    matchesToResolve.add(match.Id);
                }
            }
        }
        
        if (!matchesToResolve.isEmpty()) {
            // Enqueue async job to resolve Event IDs (callouts not allowed in triggers)
            System.enqueueJob(new ESPNEventIdResolverQueueable(matchesToResolve));
            System.debug(LoggingLevel.INFO, 'MatchTriggerHandler: Enqueued ESPN Event ID resolution for ' + matchesToResolve.size() + ' updated match(es)');
        }
    }
}

