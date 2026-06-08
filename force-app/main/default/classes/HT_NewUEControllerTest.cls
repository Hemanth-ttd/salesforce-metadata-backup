@isTest
public class HT_NewUEControllerTest {



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
    static void TestCreateUE(){        
        strk__Project__C project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];
        HT_NewUEController.createUE(project.Id);        
    }
	
}