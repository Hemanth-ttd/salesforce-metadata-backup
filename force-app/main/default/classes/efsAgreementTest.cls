@isTest

public class efsAgreementTest{
    
    @TestSetup
    static void dataSetup(){
        strk__Site__c newSite = new strk__Site__c(
            Name = 'Test Site 123',
            Site_ID__c = 'TestSiteId',
            BD_Lead__c = Userinfo.getUserId()
        );
        insert newSite;
        Agreement__c newAgreement = new Agreement__c(Name=newSite.Site_ID__c+'_1', Site__c = newSite.Id, Agreement_Type__c='Anchor',Ground_Interest__c='None');
        insert newAgreement;
       /* List<Related_Agreement__c> newRelatedAgreementList = new List<Related_Agreement__c>();
        for(Integer i=0 ; i <6 ; i++){
            newRelatedAgreementList.add(new Related_Agreement__c(Name=newSite.Site_ID__c+'_'+i, Agreement__c = newAgreement.Id));
        }
        insert newRelatedAgreementList;*/
        
    }

    static testMethod void mytestmethod(){
        Test.startTest();
          Agreement__c newAgreement = [SELECT Id,Name, Site__c, Site__r.Site_ID__c FROM Agreement__c LIMIT 1];
        system.debug('agreementName' + newAgreement.Name);
        Agreement__c newAgreement2 = new Agreement__c(Name=newAgreement.Name+'_11',
                                                      Rent_Commencement_Date__c = system.TODAY(),
                                                      Status__c ='Fully Executed',
                                                      Site__c = newAgreement.Site__c,
                                                      Agreement_Type__c='Anchor',
                                                      Ground_Interest__c='None');
        insert newAgreement2;
        update newAgreement2;
        Test.stopTest();
    }
}