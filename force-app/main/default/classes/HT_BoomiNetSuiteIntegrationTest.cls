@istest
public class HT_BoomiNetSuiteIntegrationTest {
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
    static void testPublishPlatformEvent() {
        String mockResponseBody = '{ "result": "success" }';
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',mockResponseBody,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);
        Test.startTest();
         strk__Site__c testSite = [Select Id from strk__Site__c limit 1];  
         strk__Project_Template__c testTemplate= [Select Id from strk__Project_Template__c limit 1];
         strk__Project__c testProject = new strk__Project__c(
            strk__Site__c = testSite.Id,
            strk__ProjectTemplate__c = testTemplate.Id,
            strk__Project_Status__c = '',
            strk__Project_Start_Date_F__c = System.today(),
            strk__Project_Type__c = 'ABM',
            Category__c = 'Collocation'
        );
        
        Database.insert( testProject );
          testProject.Category__c = 'Operations';
          update testProject;
        Test.stopTest();
        strk__Project__c proj = [Select Id,Latest_Integration_Response__c from strk__Project__c limit 1];
        System.assertEquals(proj.Latest_Integration_Response__c,'Record has been processing for sending to netgain');
    } 
}