public class HT_RelatedAgreementTriggerHandler {
    public static void executeBeforeInertTrigger(List<Related_Agreement__c> newList){
        
        List<Id> agreementIdsList = new List<Id>();
        
        for(Related_Agreement__c singleRecord : newList){
            if(singleRecord.FE_Date__c != null && singleRecord.Rent_Commencement_Date__c <= system.TODAY()){
                singleRecord.Is_Commenced__c = TRUE;
            }else{
                singleRecord.Is_Commenced__c = FALSE;
            }
            
            if(singleRecord.SDP_Active_Record__c == TRUE && singleRecord.Agreement__c != null){
                agreementIdsList.add(singleRecord.Agreement__c);
            }  
        }
        
       if(!agreementIdsList.isEmpty()) updateSDPActiveCheckbox(agreementIdsList);
    }
    public static void executeAfterInertTrigger(List<Related_Agreement__c> newList){
        List<Id> agreementIdsList = new List<Id>();        
        
        for(Related_Agreement__c singleRecord : newList){
            agreementIdsList.add(singleRecord.Agreement__c);
        }          
        processAllAgreementRecords(newList, agreementIdsList);
    }
    
    public static void executeBeforeUpdateTrigger(List<Related_Agreement__c> newList, Map<Id,Related_Agreement__c>  oldMap){
        
        List<Id> agreementIdsList = new List<Id>();
        
        for(Related_Agreement__c singleRecord : newList){
            if( (singleRecord.FE_Date__c != oldMap.get(singleRecord.Id).FE_Date__c ||
                 singleRecord.Rent_Commencement_Date__c != oldMap.get(singleRecord.Id).Rent_Commencement_Date__c)){
                     if(singleRecord.FE_Date__c != null && singleRecord.Rent_Commencement_Date__c <= system.TODAY()){
                          singleRecord.Is_Commenced__c = TRUE;
                     }else{
                         singleRecord.Is_Commenced__c = FALSE;
                     }               
                 }
            
            if(singleRecord.SDP_Active_Record__c == TRUE && singleRecord.Agreement__c != null){
                agreementIdsList.add(singleRecord.Agreement__c);
            } 
        }
        
        
       if(!agreementIdsList.isEmpty()) updateSDPActiveCheckbox(agreementIdsList);
    }
    
    public static void processAllAgreementRecords(List<Related_Agreement__c> newList, List<Id> agreementIdsList){
                     Map<Id, All_Agreement__c> allAgreementAgreementMap = new Map<Id, All_Agreement__c>();
        
        List<All_Agreement__c> upsertAllAgreementList = new List<All_Agreement__c>();
        List<All_Agreement__c> updatableAllAgreements = [SELECT Id, Project__c, Related_Agreement__c, Project_Acceptance__c, Agreement__c FROM All_Agreement__c
                                                         WHERE Agreement__c IN :agreementIdsList];
        
        for(All_Agreement__c singleRecord : updatableAllAgreements){
            system.debug(singleRecord);
            if( singleRecord.Agreement__c != null && ((allAgreementAgreementMap.containsKey(singleRecord.Agreement__c) && 
                allAgreementAgreementMap.get(singleRecord.Agreement__c).Related_Agreement__c != null) ||
               !allAgreementAgreementMap.containsKey(singleRecord.Agreement__c))){
                   allAgreementAgreementMap.put(singleRecord.Agreement__c, singleRecord);   
               }
        }
        
        for(Related_Agreement__c singleRecord : newList){
            if( singleRecord.Agreement__c != null && !allAgreementAgreementMap.keyset().isEmpty() &&
               allAgreementAgreementMap.containsKey(singleRecord.Agreement__c)){                      
                   All_Agreement__c allAgreementRecord = allAgreementAgreementMap.get(singleRecord.Agreement__c);
                   if(allAgreementRecord.Related_Agreement__c == NULL){
                       allAgreementRecord.Related_Agreement__c = singleRecord.Id;
                       upsertAllAgreementList.add(allAgreementRecord);
                   }else{
                       upsertAllAgreementList.add( HT_ProjectTriggerHandler.createAllAgreements(
                           new Map<String,Id>{'Project__c' => allAgreementRecord.Project__c,
                               'Project_Acceptance__c' => allAgreementRecord.Project_Acceptance__c,
                               'Agreement__c' => allAgreementRecord.Agreement__c,                                
                               'Related_Agreement__c' => singleRecord.Id}));
                       
                   }
               }            
        }
        
         if(!upsertAllAgreementList.isEmpty()){
            upsert upsertAllAgreementList;
        }
       
    }
    
      public static void updateSDPActiveCheckbox(List<Id> agreementIdList) { 
        List<Related_Agreement__c> updateRelatedAgreementList = [SELECT Id, SDP_Active_Record__c FROM Related_Agreement__c 
                                                WHERE SDP_Active_Record__c=TRUE AND Agreement__c IN :agreementIdList];
        
        for(Related_Agreement__c singleRecord : updateRelatedAgreementList){
            singleRecord.SDP_Active_Record__c = FALSE;
        }
        
        if(!updateRelatedAgreementList.isEmpty()){
            update updateRelatedAgreementList;
        }
        
    }
    
  
    
    
}