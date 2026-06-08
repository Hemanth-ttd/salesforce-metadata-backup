@isTest
public class HT_BatchCSVEmailSenderTest {
    
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
			strk__Project_Start_Date_A__c = System.today(),
			strk__Project_Type__c = 'ABM',
            Category__c = 'Collocation'
		);

		Database.insert( testProject );
		insert new Project_Extension__c(Project__c = testProject.Id);
	}

    


    // Test method to test the batch job
    @isTest
    public static void testBatchCSVEmailSender() {
        strk__Project__c testproject  =[select Id,strk__Project_Start_Date_F__c,Project_Extension__c from strk__Project__c limit 1];
        testproject.Agreement_FE_A__c = System.today();
        testproject.strk__Project_Start_Date_A__c = System.today().addDays(-1);
        update testproject;
        
        testproject.Agreement_FE_A__c = System.today().addDays(-1);
        update testproject;
        
         Project_Extension__c testprojectExtenstion  =[select Id  from Project_Extension__c limit 1];
        testprojectExtenstion.Candidate_Search_A__c = System.today().Adddays(-12);
        update testprojectExtenstion;
        testprojectExtenstion.Candidate_Search_A__c = System.today();
        update testprojectExtenstion;
        
        // Step 2: Write the dynamic query string
        String query = 'SELECT Id, strk__Field__c, strk__Project__c, strk__Project__r.Project_Extension__c, strk__API_Field__c, strk__Old_Value__c, strk__New_Value__c ' +
                       'FROM strk__Project_History__c WHERE  strk__Field__c LIKE \'%(A)\'';
        
        // Step 3: Instantiate the batch class with the query string
        HT_BatchCSVEmailSender batchJob = new HT_BatchCSVEmailSender(query);
        
        // Step 4: Execute the batch job
        Test.startTest();
        Database.executeBatch(batchJob, 200);  // Adjust batch size if needed
        Test.stopTest();

        // Step 5: Verify the results
        // Since we don't have access to the email system in tests, we can mock it or check if the logic was executed correctly.
        
    }
}