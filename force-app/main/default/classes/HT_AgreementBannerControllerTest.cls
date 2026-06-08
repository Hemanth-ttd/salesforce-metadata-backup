@isTest
public class HT_AgreementBannerControllerTest {
	@TestSetup
	static void dataSetup(){
        strk__Site__c newSite = new strk__Site__c(
			Name = 'Test Site 123',
			Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId()
		);
        insert newSite;
      
        
		strk__Project_Template__c testTemplate = new strk__Project_Template__c(
			strk__Active__c = true,
			Name = 'US Development'
		);
		insert new strk__Project_Template__c(
			strk__Active__c = true,
			Name = 'test template'
		);
		Database.insert( testTemplate );


		strk__Project__c testProject = new strk__Project__c(
			strk__Site__c = newSite.Id,
			strk__ProjectTemplate__c = testTemplate.Id,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM',
            Category__c = 'Collocation'
		);

		Database.insert( testProject );
		insert new Project_Extension__c(Project__c = testProject.Id);
           Project_Acceptance__c prjAcceptance = new Project_Acceptance__c();
        //prjAcceptance.Approval_Status__c = 'Auto Approved';
       // prjAcceptance.Category__c = 'Collocation';
       // prjAcceptance.Project_Type__c = 'Existing (EXT)';
        prjAcceptance.Total_Capex__c = 0;
        prjAcceptance.Project_Template__c = testTemplate.Id;
        prjAcceptance.Site__c = newSite.Id;
        prjAcceptance.Project__c = testProject.Id;
        insert prjAcceptance;
        
        insert new All_Agreement__c(Project__c = testProject.Id, Project_Acceptance__c = prjAcceptance.Id);
          Agreement__c newAgreement = new Agreement__c(Name=newSite.Site_ID__c+'_3', Site__c = newSite.Id, Project__c= testProject.Id, Rent_Reduction__c=true, Agreement_Type__c='Anchor',Ground_Interest__c='None');
        insert newAgreement;
           Agreement__c newAgreementGround = new Agreement__c(Name=newSite.Site_ID__c+'_1', Site__c = newSite.Id, Project__c= testProject.Id, HT_RevShare__c=true,  Agreement_Type__c='Ground',Ground_Interest__c='Lease');
        insert newAgreementGround;

           Agreement__c newAgreementColo = new Agreement__c(Name=newSite.Site_ID__c+'_4',Colocation_No__c='04', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Colocation',Ground_Interest__c='None');
        insert newAgreementColo;
 Agreement__c newAgreementColo5 = new Agreement__c(Name=newSite.Site_ID__c+'_5',Colocation_No__c='05', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Colocation',Ground_Interest__c='None');
        insert newAgreementColo5;

        
    }
    
	@isTest
    static void executeBeforeInsertTriggerTest(){
        Agreement__c newAgreement = [SELECT Id FROM Agreement__c WHERE Agreement_Type__c='Colocation' LIMIT 1];        
        HT_AgreementBannerController.getBannerMessage(newAgreement.Id);
        
    }
}