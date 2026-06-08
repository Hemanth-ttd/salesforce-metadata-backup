@isTest
public class HT_IsCommencedUpdateBatchTest {
    
    @TestSetup
    static void dataSetup(){
        strk__Site__c newSite = new strk__Site__c(
            Name = 'Test Site 123',
            Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId()
        );
        insert newSite;
        Agreement__c newAgreement = new Agreement__c(Name=newSite.Site_ID__c+'_1', Site__c = newSite.Id,
                                                      Commencement_Date__c = system.TODAY(),
                                                      Status__c ='Fully Executed', Agreement_Type__c='Anchor',Ground_Interest__c='None');
        insert newAgreement;        
    }
    @isTest
    static void batchExecuteTest(){
        string stringQuery = 'SELECT Id,Is_Commenced__c FROM Agreement__c WHERE Status__c = \'Fully Executed\''+
            ' AND Commencement_Date__c <= TODAY';
        
        Test.startTest();
        Database.executeBatch(new HT_IsCommencedUpdateBatch(stringQuery));
        Test.stopTest();
    }    @isTest
    static void scheduleExecuteTest(){
        string stringQuery = 'SELECT Id,Is_Commenced__c FROM Agreement__c WHERE Status__c = \'Fully Executed\''+
            ' AND Commencement_Date__c <= TODAY';
        String sch = '0 0 23 * * ?';
        Test.startTest();
        system.Schedule('newJob', sch, new HT_IsCommencedUpdateBatch(stringQuery));
        Test.stopTest();
    }
}