/**
 * Created by TUpadhyaya on 8/14/2018.
 */

@IsTest
public with sharing class IntegrationResponseTriggerHandlerTest {


	@TestSetup
	static void setupTestData(){
		 // create fake body
        string body = '[ "Project", {"Construction_complete_A__c" : "","SubType_2__c" : "", "strk__County__c" : "","Budget_Cost__c" : "100.00","strk__Project_Status__c" : "",';
                body += '"Project_Name__c" : "Test Multiple 9","strk__Project_Type__c" : "","Reason_Code__c" : "","SubType_1_Alt__c" : "","Funding__c" : "CAP","Source__c" : "Uniti - AT&T Anchor",';
                body += '"strk__Customer__c" : "","Id" : "a0K0U000002LQGkUAO","Integration_State__c" : "OK","strk__Project_Template__c" : "","Country__c" : "United States","Site_ID_Formula__c" : "OKL01474",';
                body += '"SubType_1__c" : "","Justification__c" : "Test Justification","strk__Project_Start_Date_F__c" : "2018-11-06 00:00:00","SBO_received__c" : "","Integration_Project_Name__c" : "OKL01474_Garland Enid_Test Multiple 9",';
                body += '"Site_Name" : "Garland Enid","strk__Street_Address__c" : "1016 South Garland Road","strk__City__c" : "Enid","Category__c" : "Operations","Name" : "P-001992"}]';

        // instantiate HttpMock with fake response
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',body,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);
		strk__Project_Template__c pTemplate = new strk__Project_Template__c(strk__Active__c = true, Name = 'Test Site Inquiry');

		insert pTemplate;


		strk__Site__c site = new strk__Site__c (Name = 'Test Site',
            Site_ID__c = String.valueOf(Math.random()),
            strk__County__c = 'test county',
            Source__c = 'Uniti - AT&T Anchor',
            Country__c = 'United States',
            strk__Street_Address__c = '1016 South Garland Road',
            strk__City__c = 'Enid');
        if(site.Site_ID__c.length()>20){
            site.Site_ID__c = site.Site_ID__c.subString(0,19);
        }
        insert site;


		 strk__Project__c project = new strk__Project__c(
            strk__Site__c = site.Id,
            strk__ProjectTemplate__c = pTemplate.Id,
			strk__Project_Type__c = 'ABM'
        );


        Database.insert( project );

	}


	static testMethod void TestIntegrationResponseInsert(){
		strk__project__c proj = [SELECT id FROM strk__Project__c LIMIT 1];
		Integration_Response__c intResp = new Integration_Response__c(Project__c = proj.id, Response_Message__c = 'TEST', External_Project_ID__c ='123');

		insert intResp;


		strk__project__c proj2 = [SELECT id, Latest_Integration_Response__c FROM strk__Project__c LIMIT 1];
		System.assertEquals('TEST',proj2.Latest_Integration_Response__c);
	}


	static testMethod void TestIntegrationUpdateDelete(){
		strk__project__c proj = [SELECT id FROM strk__Project__c LIMIT 1];
		Integration_Response__c intResp = new Integration_Response__c(Project__c = proj.id, Response_Message__c = 'TEST');

		insert intResp;



		intResp.Response_Message__c = 'Update';
		update intResp;

		strk__project__c proj2 = [SELECT id, Latest_Integration_Response__c FROM strk__Project__c LIMIT 1];
		System.assertEquals('TEST',proj2.Latest_Integration_Response__c);


		delete intResp;


	}
}