@isTest
private class HT_UnitEconomicsTriggerHandlerTest {

    @testSetup
    static void setupData() {
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


        // Create Unit_Economics__c record that will be used for insert trigger
        Unit_Economics__c ueInsert = new Unit_Economics__c(
         
            Project__c = testProject.Id,
            Latest_Unit_Economics__c = true
        );
        insert ueInsert;

        // Create Unit_Economics__c record for update test (not auto-approved)
        Unit_Economics__c ueUpdate = new Unit_Economics__c(
         
            Project__c = testProject.Id,
            Latest_Unit_Economics__c = false,
            X8_Year_IRR__c = 12,
            Unlevered_IRR_w_Pipeline_Colo__c = 10,
            Total_Capex__c=1000,
            
            Approval_Status__c = 'Draft'
        );
        insert ueUpdate;
    }

    @isTest
    static void testExecuteBeforeInsertTrigger() {
        strk__Project__C  project = [SELECT id FROM strk__Project__c Limit 1];
        HT_NewUEController.createUE(project.Id);  


        Unit_Economics__c ue = new Unit_Economics__c(
           
            Project__c = project.Id,
            Latest_Unit_Economics__c = true
        );

        List<Unit_Economics__c> newList = new List<Unit_Economics__c>{ue};

        Test.startTest();
        HT_UnitEconomicsTriggerHandler.executeBeforeInertTrigger(newList);
        Test.stopTest();

        System.assertEquals(true, ue.Latest_Unit_Economics__c, 'Latest_Unit_Economics__c should remain true');
    }

    

    @isTest
    static void testUpdateUEApprovedCheckbox() {
        Unit_Economics__c ue = [SELECT Id, Project__c FROM Unit_Economics__c WHERE Latest_Unit_Economics__c = true LIMIT 1];

        Test.startTest();
        HT_UnitEconomicsTriggerHandler.updateUEApprovedCheckbox(new List<Id>{ue.Project__c});
        Test.stopTest();

        Unit_Economics__c updatedUE = [SELECT Id, Latest_Unit_Economics__c FROM Unit_Economics__c WHERE Id = :ue.Id];
        System.assertEquals(false, updatedUE.Latest_Unit_Economics__c, 'Latest_Unit_Economics__c should be set to false');
    }

}