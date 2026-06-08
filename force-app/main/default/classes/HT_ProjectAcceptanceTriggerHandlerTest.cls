@IsTest
private class HT_ProjectAcceptanceTriggerHandlerTest {
     @IsTest
    static void HT_testCreateProjectAcceptance() {
        strk__Project_Template__c attTemplate = new strk__Project_Template__c(
            Name = Label.SITE_DEVELOPMENT_ATT_WITH_HNS_PROJECT_TEMPLATE,
            strk__Project_Extension_Objects__c = String.valueOf( Site_Development_AT_T__c.SObjectType ),
            strk__Active__c = true,
            strk__Category__c = Uniti_Constants.PROJECT_TEMP_CATEGORY_TOWERS
        );
        insert attTemplate;
        
        strk__Site__c site = new strk__Site__c(
            Name = 'Test site',
            Site_ID__c = 'TestSiteId'
        );
        insert site;
        
        Project_Acceptance__c prjAcceptance = new Project_Acceptance__c();
        //prjAcceptance.Approval_Status__c = 'Auto Approved';
        prjAcceptance.Category__c = 'Collocation';
        prjAcceptance.Project_Type__c = 'Existing (EXT)';
        prjAcceptance.Total_Capex__c = 0;
        prjAcceptance.Project_Template__c = attTemplate.Id;
        prjAcceptance.Site__c = site.Id;
        insert prjAcceptance;
       system.debug(HT_ProjectAcceptanceTriggerHandler.templateIdMap);
        
        Project_Acceptance__c prjAcceptance1 = new Project_Acceptance__c();
        prjAcceptance1.Approval_Status__c = 'New';
        prjAcceptance1.Project_Template__c = attTemplate.Id;
        prjAcceptance1.Site__c = site.Id;
        prjAcceptance1.Category__c = 'collocation';
        prjAcceptance1.Project_Type__c = 'Existing (EXT)';
        insert prjAcceptance1;
        prjAcceptance1.Approval_Status__c = 'Approved';
        update prjAcceptance1;
        
        Project_Acceptance__c prjAcceptance2 = new Project_Acceptance__c();
        prjAcceptance2.Approval_Status__c = 'New';
        prjAcceptance2.Project_Template__c = attTemplate.Id;
        prjAcceptance2.Site__c = site.Id;
        prjAcceptance2.Category__c = 'Development';
        prjAcceptance2.SD_Narrative__c ='test';
        prjAcceptance2.SBO_accept_reject_F__c = system.today();
        prjAcceptance2.Project_Type__c = 'Existing (EXT)';
        insert prjAcceptance2;
        prjAcceptance2.Approval_Status__c = 'Approved';
        update prjAcceptance2;
        
        Project_Acceptance__c prjAcceptanceDel = new Project_Acceptance__c();
        prjAcceptanceDel.Approval_Status__c = 'New';
        prjAcceptanceDel.Project_Template__c = attTemplate.Id;
        prjAcceptanceDel.Site__c = site.Id;
        insert prjAcceptanceDel;
        delete prjAcceptanceDel;
    }

}