@isTest
private class FormControllerTest {
    @testSetup
    static void setupTestData(){
        string body = '[ "Project", {"Construction_complete_A__c" : "","SubType_2__c" : "", "strk__County__c" : "","Budget_Cost__c" : "100.00","strk__Project_Status__c" : "",';
                body += '"Project_Name__c" : "Test Multiple 9","strk__Project_Type__c" : "","Reason_Code__c" : "","SubType_1_Alt__c" : "","Funding__c" : "CAP","Source__c" : "Uniti - AT&T Anchor",';
                body += '"strk__Customer__c" : "","Id" : "a0K0U000002LQGkUAO","Integration_State__c" : "OK","strk__Project_Template__c" : "","Country__c" : "United States","Site_ID_Formula__c" : "OKL01474",';
                body += '"SubType_1__c" : "","Justification__c" : "Test Justification","strk__Project_Start_Date_F__c" : "2018-11-06 00:00:00","SBO_received__c" : "","Integration_Project_Name__c" : "OKL01474_Garland Enid_Test Multiple 9",';
                body += '"Site_Name" : "Garland Enid","strk__Street_Address__c" : "1016 South Garland Road","strk__City__c" : "Enid","Category__c" : "Operations","Name" : "P-001992"}]';

        // instantiate HttpMock with fake response
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',body,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);
        strk__Project_Template__c testTemplate = new strk__Project_Template__c(
                strk__Active__c = true,
                Name = 'Test Template 1'
        );

        insert testTemplate;

        strk__Site__c testSite = new strk__Site__c(
            Name = 'Test Site',
            Site_ID__c = String.valueOf(Math.random()),
            strk__County__c = 'test county',
            Source__c = 'Uniti - AT&T Anchor',
            Country__c = 'United States',
            strk__Street_Address__c = '1016 South Garland Road',
            strk__City__c = 'Enid'
        );

        insert testSite;

        strk__Project__c testProject = new strk__Project__c(
                strk__Site__c= testSite.Id,
                strk__ProjectTemplate__c = testTemplate.Id,
                strk__Project_Status__c = '',
                strk__Project_Start_Date_F__c = System.today(),
                strk__Project_Type__c = 'ABM'
        );

        insert testProject;

        strk__Activity__c testActivity = new strk__Activity__c(
        	strk__Project__c = testProject.Id);

        insert testActivity;

    }

	static testmethod void test() {
		strk__Project__c proj = [SELECT Id, strk__Site__c FROM strk__Project__c LIMIT 1];
		strk__Activity__c act = [SELECT Id FROM strk__Activity__c LIMIT 1];

		PageReference pg = Page.CloseoutsCompleteForm;
		Test.setCurrentPage(pg);

		ApexPages.currentPage().getParameters().put('actId',act.Id);

		ApexPages.StandardController stdController = new ApexPages.StandardController(proj);
		FormController frmController = new FormController(stdController);

		frmController.saveAndCloseForm();
		frmController.saveAndCompleteForm();
	}
}