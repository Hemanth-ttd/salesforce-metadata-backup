public class HT_AgreementBannerController {
    
    @AuraEnabled(cacheable=true)
    public static string getBannerMessage(Id recordId){
        String returnValue ='';
        Agreement__c currentAgreementRecord = [SELECT Id, Site__c FROM Agreement__c WHERE Id=:recordId];
        
        List<Agreement__c> siteAgreementRecordsList = [SELECT Id,Name, Agreement_Type__c, HT_RevShare__c, Rent_Reduction__c
                                                       FROM Agreement__c WHERE Site__c=:currentAgreementRecord.Site__c AND 
                                                       ( (Agreement_Type__c='Ground' AND HT_RevShare__c = TRUE) OR 
                                                        ((Agreement_Type__c='Anchor' AND Rent_Reduction__c = TRUE))) Order by Agreement_Type__c DESC];
        Boolean isRentReductionfound = false;
        Boolean isRevSharefound = false;
        for(Agreement__c singleRecord : siteAgreementRecordsList){
            
            if(singleRecord.Agreement_Type__c=='Ground' && singleRecord.HT_RevShare__c && !isRevSharefound ){
                returnValue +='Revenue Share is Enabled: <a href="/'+ singleRecord.Id +'" target="_blank">'+ singleRecord.Name +'</a> <br /> ';
                isRevSharefound = true;
            }
            if(singleRecord.Agreement_Type__c=='Anchor' && singleRecord.Rent_Reduction__c  && !isRentReductionfound){
                returnValue +=' Rent Reduction is Enabled:   <a href="/'+ singleRecord.Id +'" target="_blank">'+ singleRecord.Name +'</a>';
                isRentReductionfound = true;
            }
            if(isRentReductionfound && isRevSharefound ){
                break;
            }
        }
        
        
        return returnValue;
    }
    
    
}