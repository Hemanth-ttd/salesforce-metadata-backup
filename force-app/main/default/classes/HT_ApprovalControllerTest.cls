@isTest
public class HT_ApprovalControllerTest {
    
   
    @isTest
    static void testGetPendingApprovals() {
            List<strk__Approver__c> pendingApprovals = HT_ApprovalController.getPendingApprovals('','All Pending Approvals');
            List<strk__Approver__c> myPendingApprovals = HT_ApprovalController.getPendingApprovals('','My Pending Approvals');
            List<strk__Approver__c> overdueApprovals = HT_ApprovalController.getPendingApprovals('','Overdue Approvals');
            List<strk__Approver__c> unitEconomicsApprovals = HT_ApprovalController.getPendingApprovals('','Unit Economics Approvals');
            List<strk__Approver__c> projectAccptanceApprovals = HT_ApprovalController.getPendingApprovals('','Project Acceptance Approvals');
        try{
             HT_ApprovalController.approveOrReject(userinfo.getUserId(),'Approved', 'Approved via test');
        }catch(exception ex){}
    }
    
    /* @isTest
    static void testGetPendingApprovalsLoggedInUsr() {
        Group reAdminQueue = [SELECT Id FROM Group WHERE DeveloperName = 'RE_Admin' AND Type = 'Queue' LIMIT 1];
        strk__Approver__c approver = new strk__Approver__c();
        approver.strk__Status__c = 'Pending';
        approver.strk__Object_API__c = 'Unit_Economics__c';
        approver.strk__Actual_Approver__c = UserInfo.getUserId();
        insert approver;
        
        List<strk__Approver__c> loggedInUsrPendingApprovals = HT_ApprovalController.getPendingApprovals(approver.Id,null);
        try{
             HT_ApprovalController.approveOrReject(userinfo.getUserId(),'Approved', 'Approved via test');
        }catch(exception ex){}
    }
*/
    
}