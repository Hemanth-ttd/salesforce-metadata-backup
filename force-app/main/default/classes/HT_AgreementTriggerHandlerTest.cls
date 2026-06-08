@isTest
public class HT_AgreementTriggerHandlerTest {
    
	@TestSetup
	static void dataSetup(){
        strk__Site__c newSite = new strk__Site__c(
			Name = 'Test Site 123',
			Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId(),
             strk__Zip_Code__c= String.valueof(Math.floor(Math.random() * 90000).intValue() + 10000)
		);
        insert newSite;
      
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

        List<Agreement__c> agreementList = new  List<Agreement__c>();       
        agreementList.add(new Agreement__c(Name=newSite.Site_ID__c+'_3', Colocation_No__c='00', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Anchor',Ground_Interest__c='None'));        
        agreementList.add(new Agreement__c(Name=newSite.Site_ID__c+'_1', Colocation_No__c='00', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Ground',Ground_Interest__c='Lease'));        
        agreementList.add( new Agreement__c(Name=newSite.Site_ID__c+'_4',Colocation_No__c='04', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Colocation',Ground_Interest__c='None'));        
        agreementList.add( new Agreement__c(Name=newSite.Site_ID__c+'_5',Colocation_No__c='05', Site__c = newSite.Id, Project__c= testProject.Id,  Agreement_Type__c='Colocation',Ground_Interest__c='None'));    
        agreementList.add( new Agreement__c(Name=newSite.Site_ID__c+'_20', Colocation_No__c='00', Site__c = newSite.Id, Project__c= testProject.Id, Status__c = 'Fully Executed',  Agreement_Type__c='SDP',Ground_Interest__c='None', RecordTypeId = HT_AgreementTriggerHandler.relatedAgreementRecordTypeId));
       
        insert agreementList;

        
         insert new Agreement__c(Name=newSite.Site_ID__c+'_20', Colocation_No__c='00', Site__c = newSite.Id, SDP_Active_Record__c=TRUE, Status__c = 'Fully Executed', Related_Agreement_Type__c ='SDP Revision/Version',
                                 Parent_Agreement__c= agreementList[4].Id, Agreement_Type__c='SDP',Ground_Interest__c='None', RecordTypeId = HT_AgreementTriggerHandler.relatedAgreementRecordTypeId);
    }
    
	@isTest
	static void executeBeforeInsertTriggerTest(){
        Agreement__c newAgreement = [SELECT Id,Name, Site__c, Site__r.Site_ID__c, Project__r.strk__ProjectTemplate__c FROM Agreement__c LIMIT 1];
        
        Agreement__c newAgreement2 = new Agreement__c(Name=newAgreement.Name+'_11',
                                                      Rent_Commencement_Date__c = system.TODAY(),
                                                       Contract_Fully_Executed__c =system.TODAY(),
                                                      Site__c = newAgreement.Site__c,
                                                      Agreement_Type__c='Anchor',
                                                      Ground_Interest__c='None');
        insert newAgreement2;
        
        String mockResponseBody = '{ "result": "success" }';
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200, 'Complete', mockResponseBody, null);
        Test.setMock(HttpCalloutMock.class, fakeresp);
        
        	strk__Project__c testProject1 = new strk__Project__c(
			strk__Site__c = newAgreement.Site__c,
			strk__ProjectTemplate__c = newAgreement.Project__r.strk__ProjectTemplate__c,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM',
            Category__c = 'Collocation'
		);
        
        insert testProject1;
        
        Project_Acceptance__c prjAcceptance = new Project_Acceptance__c();
        //prjAcceptance.Approval_Status__c = 'Auto Approved';
       // prjAcceptance.Category__c = 'Collocation';
       // prjAcceptance.Project_Type__c = 'Existing (EXT)';
        prjAcceptance.Total_Capex__c = 0;
        prjAcceptance.Project_Template__c = newAgreement.Project__r.strk__ProjectTemplate__c;
        prjAcceptance.Site__c = newAgreement.Site__c;
        prjAcceptance.Project__c = testProject1.Id;
        insert prjAcceptance;
        
        insert new All_Agreement__c(Project__c = testProject1.Id, Project_Acceptance__c = prjAcceptance.Id);
        insert new All_Agreement__c(Project__c = testProject1.Id, Project_Acceptance__c = prjAcceptance.Id);
        
        newAgreement.Project__c = testProject1.Id;
        update newAgreement;
        newAgreement.Project__c =null;
        update newAgreement;
        
    }
    	@isTest
	static void executeBeforeUpdateTriggerTest(){
        Agreement__c newAgreement = [SELECT Id, Site__c, Site__r.Site_ID__c FROM Agreement__c LIMIT 1];
        newAgreement.Rent_Commencement_Date__c = system.TODAY();
        newAgreement.Contract_Fully_Executed__c =system.TODAY();
        update newAgreement;
        newAgreement.Rent_Commencement_Date__c = system.TODAY().addDays(2);
        update newAgreement;
        
         Agreement__c newAgreementGround = [SELECT Id, Site__c, Site__r.Site_ID__c FROM Agreement__c  where Agreement_Type__c='Ground' LIMIT 1];
        
        newAgreementGround.HT_RevShare__c = true;
        update newAgreementGround;
       
    }
    
      	@isTest
	static void executeRevShareBeforeUpdateTriggerTest(){
       
         Agreement__c newAgreementGround = [SELECT Id, Site__c, Site__r.Site_ID__c FROM Agreement__c  where Agreement_Type__c='Ground' LIMIT 1];
        
        newAgreementGround.HT_RevShare__c = true;
        update newAgreementGround;
        
        newAgreementGround.HT_RevShare__c = false;
        update newAgreementGround;
        
    }
    
          	@isTest
	static void executeRentReductionBeforeUpdateTriggerTest(){
       
         Agreement__c newAgreementGround = [SELECT Id, Site__c, Site__r.Site_ID__c FROM Agreement__c  where Agreement_Type__c='Anchor' LIMIT 1];
        
        newAgreementGround.Rent_Reduction__c = true;
        update newAgreementGround;
        
        newAgreementGround.Rent_Reduction__c = false;
        update newAgreementGround;
        
    }
    
}