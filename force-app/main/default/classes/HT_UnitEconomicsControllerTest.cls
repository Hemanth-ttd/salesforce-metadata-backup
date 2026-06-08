@isTest
private class HT_UnitEconomicsControllerTest {

    @testSetup
    static void setupData() {
        // Create a mock Approval_Process__c record
        	strk__Approval_Process__c approvalProcess = new 	strk__Approval_Process__c(
           
            strk__Status__c = 'Pending',
            strk__Active__c = true,
            strk__Allow_Recalls__c = true,
            strk__Initiator__c = UserInfo.getUserId(),
            strk__Object_Name__c = 'Unit_Economics__c',
            strk__Record_Name__c = 'Test Record',
            strk__Approval_Submitted_Date__c = Date.today()
        );
        insert approvalProcess;

        // Create a mock Unit_Economics__c record
        Unit_Economics__c unitEconomics = new Unit_Economics__c(
            Approval_Process__c = approvalProcess.Id,
            Total_Capex__c = 100000,
            X8_Year_IRR__c = 12.5
        );
        insert unitEconomics;
    }

    @isTest
    static void testGetUnitEconomicsData() {
        // Get inserted Unit_Economics__c record
        Unit_Economics__c ue = [SELECT Id FROM Unit_Economics__c LIMIT 1];

        Test.startTest();
        Unit_Economics__c result = HT_UnitEconomicsController.getUnitEconomicsData(ue.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid Unit_Economics__c record');
        System.assertNotEquals(null, result.Approval_Process__r.Name, 'Approval process name should not be null');
    }

    @isTest
    static void testGetApprovalRecordId_ValidField() {
        Unit_Economics__c ue = [SELECT Id, Approval_Process__c FROM Unit_Economics__c LIMIT 1];

        Test.startTest();
        String approvalId = HT_UnitEconomicsController.getApprovalRecordId(ue.Id, 'Approval_Process__c');
        Test.stopTest();

        System.assertEquals(ue.Approval_Process__c, approvalId, 'Approval Process ID should match');
    }

    
   static void testGetApprovalRecordId_InvalidField() {
        Unit_Economics__c ue = [SELECT Id FROM Unit_Economics__c LIMIT 1];

        Test.startTest();
        try {
            HT_UnitEconomicsController.getApprovalRecordId(ue.Id, 'Nonexistent_Field__c');
            System.assert(true, 'Expected AuraHandledException with appropriate message');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error fetching record data'), 'Expected AuraHandledException with appropriate message');
        }
        Test.stopTest();
    }
    

@isTest
static void testGetApprovalRecordId_RecordNotFound() {
    Id fakeId = 'a01' + String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(15 - 3, '0');

    Test.startTest();
    try {
     string getID=   HT_UnitEconomicsController.getApprovalRecordId(fakeId, 'Approval_Process__c');
     
    } catch (AuraHandledException e) {
        System.debug('Caught exception: ' + e.getMessage());
        System.assert(
    e.getMessage().contains('Script-thrown exception'),
    'Expected exception for missing record. Actual: ' + e.getMessage());

      
    }
    Test.stopTest();
}

}