@isTest
public with sharing class HT_ProjectTriggerHandlerTest {

	@TestSetup
	static void makeData(){
    String mockResponseBody = '{ "result": "success" }';
    STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200, 'Complete', mockResponseBody, null);
    Test.setMock(HttpCalloutMock.class, fakeresp);
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
		strk__Project__c testProject = new strk__Project__c(
			strk__Site__c = testSite.Id,
			strk__ProjectTemplate__c = testTemplate.Id,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM',
            Category__c = 'Collocation'
		);

		Database.insert( testProject );
		insert new Project_Extension__c(Project__c = testProject.Id);
	}

	@isTest
	static void TestSyncProjectToSite(){

		strk__Project__C project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];

		project.NTP_to_Customer_A__c = date.today();
		update project;
		project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];
		strk__Site__c site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];
		system.assertEquals(date.today(), site.Customer_Ready__C);

	}
	@isTest
	static void TestSyncProjectToSitenoSync(){

		strk__Site__c site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];
		site.Customer_Ready__c = date.today().addDays(-2);
		update site;
		site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];

		strk__Project__C project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];
		project.NTP_to_Customer_A__c = date.today();
        project.Lease_or_Amendment_FE_A__c = date.today();
		update project;

		project.NTP_to_Customer_A__c = date.today();
		system.assertEquals(date.today().addDays(-2), site.Customer_Ready__C);

	}
	@isTest
	static void TestSyncProjectContractorToSite(){
        
    String mockResponseBody = '{ "result": "success" }';
    STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200, 'Complete', mockResponseBody, null);
    Test.setMock(HttpCalloutMock.class, fakeresp);
		strk__project__c proj = new strk__project__c(
			strk__Site__c = [select id from strk__Site__c].Id,
			strk__ProjectTemplate__c = [SELECT id FROM strk__project_template__c WHERE name LIKE '%test%'].id,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM'
		);
        Test.startTest();
		insert proj;

		//proj.general_contractor_company__c = 'test company';
        proj.NTP_to_Customer_A__c = null;
        //proj.strk__Project_Start_Date_A__c = system.today();
		update proj;
		strk__Site__c site = [SELECT id FROM strk__Site__c Limit 1];
		//system.assert(site.general_contractor_company__c.contains('test company'));
		Project_Extension__c testPE =  [SELECT Id FROM Project_Extension__c LIMIT 1];
        update testPE;
        HT_ProjectTriggerHandler.createAllAgreements(new Map<String,Id>{'Project__c' => proj.Id, 'Project_Acceptance__c' => null});
        Test.stopTest();
        delete testPE;
        try{
            delete proj;
        }catch(exception ex){}
        try{
            delete site;
        }catch(exception ex){}
	}
}