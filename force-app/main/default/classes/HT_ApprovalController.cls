public with sharing class HT_ApprovalController {
    
    
    @AuraEnabled(cacheable=true)
    public static List<strk__Approver__c> getPendingApprovals(String recordId,String approvalType) {
        
        String baseQuery = 
            'SELECT Id, Name, strk__User_Name__c, strk__Object_API__c, strk__Record_Id_Formula__c, ' +
            'strk__Approval_Queue_Name__c, strk__Status__c, strk__Review_Date_Time__c, strk__Actual_Approver__r.Name ' +
            'FROM strk__Approver__c WHERE (strk__Status__c = \'Pending\' OR strk__Status__c = \'Reassigned\')';
        
        Boolean filterOnUser = false;
        if (String.isBlank(recordId)) {
            if (String.isNotBlank(approvalType)) {
                switch on approvalType {
                    when 'My Pending Approvals' {
                        filterOnUser = true;
                    }
                    when 'All Pending Approvals' {
                        filterOnUser = false;
                    }
                    when 'Overdue Approvals' {
                        filterOnUser = false;
                        baseQuery += ' AND strk__Due_Date__c < TODAY';
                    }
                    when 'Unit Economics Approvals' {
                        filterOnUser = false;
                        baseQuery += ' AND strk__Object_API__c = \'Unit_Economics__c\'';
                    }
                    when 'Project Acceptance Approvals' {
                        filterOnUser = false;
                        baseQuery += ' AND strk__Object_API__c = \'Project_Acceptance__c\'';
                    }
                    when else {
                    }
                }
            }
        }else {
                filterOnUser = true;
            }
        
        if (filterOnUser) {
            baseQuery += ' AND strk__User_Id__c = \'' + UserInfo.getUserId() + '\'';
        }
        
        if (String.isNotBlank(recordId)) {
            baseQuery += ' AND strk__Record_Id_Formula__c = \'' + String.escapeSingleQuotes(recordId) + '\'';
        }
        
        baseQuery += ' ORDER BY strk__Due_Date__c DESC';
         System.debug('approvalType'+approvalType);
        System.debug('baseQuery'+baseQuery);
        
        return Database.query(baseQuery);
    }
    
    
    
    @AuraEnabled
    public static List<strk__Approver__c> approveOrReject(String workItemId, String submitAction, String comment) {
        try{
            update new strk__Approver__c(Id=workItemId, strk__Status__c=submitAction, strk__Comments__c=comment);
            return getPendingApprovals('',null);
        }catch(exception ex) {
            throw new AuraHandledException('Failed to process approval.');
        }
    }
}