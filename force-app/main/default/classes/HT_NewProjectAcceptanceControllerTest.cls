@isTest
public class HT_NewProjectAcceptanceControllerTest {
    
    @isTest
    static void TestSyncProjectToSite(){
        
        strk__Site__c testSite = new strk__Site__c(
            Name = 'Test Site 123',
            Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId()
        );
        
        Database.insert( testSite );
        HT_NewProjectAcceptanceController.createProjectAcceptance(testSite.Id);
	}

}