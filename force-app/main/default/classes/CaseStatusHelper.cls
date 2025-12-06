public without sharing class CaseStatusHelper {
    
    @InvocableMethod(label='Case Status'
                    description='Returns the current status of a Case when user asks for it. For example, user can say "what is the status of case 00001234?" or "get case status for case number 00001234"')
    public static List<String> getCaseStatus(List<String> caseNumber) {
        
        Case c = [SELECT Id, Status FROM Case WHERE CaseNumber = :caseNumber[0] LIMIT 1];
        return new List<String> { c.Status };
    }
}

