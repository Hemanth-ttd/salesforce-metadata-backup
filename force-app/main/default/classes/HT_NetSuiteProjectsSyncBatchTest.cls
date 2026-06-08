@isTest
public class HT_NetSuiteProjectsSyncBatchTest{
    @TestSetup
    static void makeData(){
        strk__Project_Template__c testTemplate = new strk__Project_Template__c(
            strk__Active__c = true,
            Name = 'US Development'
        );
        
        insert new strk__Project_Template__c(
            strk__Active__c = true,
            Name = 'test template'
        );
        Database.insert( testTemplate );
        
        strk__Site__c testSite = new strk__Site__c(
            Name = 'Test Site 123',
            Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId()
        );
        
        Database.insert( testSite );
        
    }
 @isTest
static void testBatchExecution() {
    String mockResponseBody = '{ "result": "success" }';
    STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200, 'Complete', mockResponseBody, null);
    Test.setMock(HttpCalloutMock.class, fakeresp);

    strk__Site__c site = [SELECT Id FROM strk__Site__c LIMIT 1];
    strk__Project_Template__c template = [SELECT Id FROM strk__Project_Template__c LIMIT 1];

    strk__Project__c project = new strk__Project__c(
        strk__Site__c = site.Id,
        strk__ProjectTemplate__c = template.Id,
        strk__Project_Status__c = '',
        strk__Project_Start_Date_F__c = System.today(),
        strk__Project_Type__c = 'ABM',
        Category__c = 'Collocation'
    );

    Test.startTest();
    insert project;
    Database.executeBatch(new HT_NetSuiteProjectsSyncBatch(), 1);
    Test.stopTest();

    strk__Project__c proj = [SELECT Id, Latest_Integration_Response__c, Netsuite_Status__c 
                             FROM strk__Project__c LIMIT 1];

    System.assertNotEquals(null, proj.Netsuite_Status__c, 'Batch should update Netsuite_Status__c');
    System.assertEquals('Record has been processing for sending to netgain', proj.Latest_Integration_Response__c);
}

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule('Test NetSuite Batch Schedule', cronExp, new HT_NetSuiteProjectsSyncBatch());
        Test.stopTest();
    }
}