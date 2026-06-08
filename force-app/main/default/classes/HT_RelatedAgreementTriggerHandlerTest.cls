@isTest
public class HT_RelatedAgreementTriggerHandlerTest {
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
        
    }
    
    @isTest
    static void executeBeforeUpdateTriggerTest(){
        Agreement__c newAgreement = [SELECT Id,Name FROM Agreement__c LIMIT 1];
        
        List<Related_Agreement__c> newRelatedAgreementList = new List<Related_Agreement__c>();
        Related_Agreement__c newRelatedAgreement1 = new Related_Agreement__c(Name=newAgreement.Name+'_10',
                                                                             Status__c ='Fully Executed',
                                                                             Rent_Commencement_Date__c = system.TODAY(),
                                                                             Agreement__c = newAgreement.Id);
        newRelatedAgreementList.add(newRelatedAgreement1);
        Related_Agreement__c newRelatedAgreement2 = new Related_Agreement__c(Name=newAgreement.Name+'_11',
                                                                             Status__c ='Fully Executed',
                                                                             Agreement__c = newAgreement.Id);
        newRelatedAgreementList.add(newRelatedAgreement2);
        insert newRelatedAgreementList;
        
        newRelatedAgreementList = new List<Related_Agreement__c>();
        newRelatedAgreement1.Status__c = null;
        newRelatedAgreementList.add(newRelatedAgreement1);
        
        newRelatedAgreement2.Commencement_Date__c = system.TODAY();
        newRelatedAgreementList.add(newRelatedAgreement2);
        
        update newRelatedAgreementList;
        
    }
    
    
}