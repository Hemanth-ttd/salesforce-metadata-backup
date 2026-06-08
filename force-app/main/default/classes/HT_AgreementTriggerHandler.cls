public class HT_AgreementTriggerHandler {   
    public static Id agreementRecordTypeId = Schema.SObjectType.Agreement__c.getRecordTypeInfosByDeveloperName().get('Agreement').getRecordTypeId();
    public static Id relatedAgreementRecordTypeId = Schema.SObjectType.Agreement__c.getRecordTypeInfosByDeveloperName().get('Related_Agreement').getRecordTypeId();    
    public static Boolean isValidateOnEdit = TRUE;
    public static void executeBeforeInertTrigger(List<Agreement__c> newList){
        
        List<Id> agreementIdsList = new List<Id>();
        for(Agreement__c singleRecord : newList){
            if(singleRecord.Contract_Fully_Executed__c != null && singleRecord.Rent_Commencement_Date__c <= system.TODAY()){
                singleRecord.Is_Commenced__c = TRUE;
            }else{
                singleRecord.Is_Commenced__c = FALSE;
            }   
            if(singleRecord.recordTypeId == relatedAgreementRecordTypeId){
                if(singleRecord.Contract_Fully_Executed__c != null){
                   singleRecord.Status__c = 'Fully Executed'; 
                }
                if(singleRecord.Status__c == 'Fully Executed' && singleRecord.Agreement_Type__c == 'SDP'){
                    singleRecord.SDP_Active_Record__c = TRUE;
                }                
                if(singleRecord.SDP_Active_Record__c == TRUE && singleRecord.Parent_Agreement__c != null  && singleRecord.Agreement_Type__c == 'SDP'){
                    agreementIdsList.add(singleRecord.Parent_Agreement__c);
                } 
            }
 
        }
        
       if(!agreementIdsList.isEmpty()) updateSDPActiveCheckbox(agreementIdsList);
    }
    
    public static void executeAfterInertTrigger(List<Agreement__c> newList){
        List<Id> projectIdsList = new List<Id>();
        List<Agreement__c> updateAgreementList = new List<Agreement__c>();
        List<Id> taskGenerateagreementIdsList = new List<Id>();
            Map<Id, Integer> parentToChildCount = new Map<Id, Integer>();
        
        for(Agreement__c singleRecord : newList){    
             if(singleRecord.recordTypeId == agreementRecordTypeId)
                projectIdsList.add(singleRecord.Project__c); 
            if(singleRecord.NetSuite_External_ID__c == null){
                updateAgreementList.add(new Agreement__c(Id= singleRecord.id, NetSuite_External_ID__c= singleRecord.id,NetGain_Status__c='Pending'));
            } 
            
            if(singleRecord.recordTypeId == relatedAgreementRecordTypeId)  {
                if (singleRecord.Contract_Fully_Executed__c != null && singleRecord.Parent_Agreement__c != null && 
                    (singleRecord.Related_Agreement_Reason__c =='Revised SDP Amendment' || singleRecord.Related_Agreement_Reason__c =='Reconciliation Amendment')) {
                        taskGenerateagreementIdsList.add(singleRecord.Parent_Agreement__c);
                        parentToChildCount.put(singleRecord.Parent_Agreement__c, 1);
                    }
            }
        }         
            processAllAgreementRecords(newList, projectIdsList, new Map<Id, String>());
        if(!updateAgreementList.isEmpty()) update updateAgreementList;
        if(!taskGenerateagreementIdsList.isEmpty()) {
             List<Agreement__c> parentAgreements = [
                SELECT Id, Rent_Commencement_Date__c
                FROM Agreement__c
                WHERE Id IN :taskGenerateagreementIdsList AND Rent_Commencement_Date__c != null
            ];
           insertTasksForParents(parentAgreements, parentToChildCount);
        }
        
        
    }
    
    public static void executeBeforeUpdateTrigger(List<Agreement__c> newList, Map<Id,Agreement__c>  oldMap){
        
        List<Id> agreementIdsList = new List<Id>();
         List<PermissionSetAssignment> permissionAssignments = [Select AssigneeId FROM PermissionSetAssignment WHERE AssigneeId=:Userinfo.getUserId() AND ( PermissionSet.Name IN ('RE_Contracts_Review_Team', 'Administrative_Review_Team', 'PC_Team') OR PermissionSet.Profile.Name ='System Administrator')];


        for(Agreement__c singleRecord : newList){
            
            if(isValidateOnEdit &&  permissionAssignments.isEmpty() && (oldMap.get(singleRecord.Id).Status__c =='Fully Executed' || oldMap.get(singleRecord.Id).Status__c =='Terminated')){                
                singleRecord.addError('Only RE Admin or RE Contracts team can make changes to agreement in status - Fully Executed Or Terminated.');
            }
            
            
            if( (singleRecord.Contract_Fully_Executed__c != oldMap.get(singleRecord.Id).Contract_Fully_Executed__c ||
                 singleRecord.Rent_Commencement_Date__c != oldMap.get(singleRecord.Id).Rent_Commencement_Date__c)){
                     if(singleRecord.Contract_Fully_Executed__c != null && singleRecord.Rent_Commencement_Date__c <= system.TODAY()){
                         singleRecord.Is_Commenced__c = TRUE;
                     }else{
                         singleRecord.Is_Commenced__c = FALSE;
                     }               
                 }
            if(singleRecord.recordTypeId == relatedAgreementRecordTypeId){                
                if(singleRecord.Contract_Fully_Executed__c != null){
                   singleRecord.Status__c = 'Fully Executed'; 
                }
                if(singleRecord.Status__c == 'Fully Executed' && singleRecord.Agreement_Type__c == 'SDP' && singleRecord.Status__c != oldMap.get(singleRecord.Id).Status__c){
                    singleRecord.SDP_Active_Record__c = TRUE;
                }  
                
                if(singleRecord.SDP_Active_Record__c != oldMap.get(singleRecord.Id).SDP_Active_Record__c && singleRecord.SDP_Active_Record__c == TRUE && 
                   singleRecord.Parent_Agreement__c != null && singleRecord.Agreement_Type__c == 'SDP'){
                       agreementIdsList.add(singleRecord.Parent_Agreement__c);
                   } 
            }
        }
       if(!agreementIdsList.isEmpty()) updateSDPActiveCheckbox(agreementIdsList);        
    }
    
    public static void executeAfterUpdateTrigger(List<Agreement__c> newList, Map<Id,Agreement__c>  oldMap){
        
        List<Task> taskList = new List<Task>();
        List<Id> projectIdsList = new List<Id>();
        List<Id> siteIDList = new List<Id>();
        List<Agreement__c> agreementsList = new List<Agreement__c>();
        List<Agreement__c> ActiveRevShareAgreementList = new List<Agreement__c>();
        List<Agreement__c> ActiveRentReductionAgreementList = new List<Agreement__c>();
        Map<Id, String> agreementProjectIdMap = new Map<Id, String>();
        List<Id> groundAgreementIds = new List<Id>();
        List<Id> groundInactiveRevShareAgreementIds = new List<Id>();
        List<Id> anchorAgreementIds = new List<Id>();
        List<Id> anchorInactiveRentReductionAgreementIds = new List<Id>();
        List<Id> taskGenerateagreementIdsList = new List<Id>();
        Map<Id, Integer> parentToChildCount = new Map<Id, Integer>();
        
        for(Agreement__c singleRecord : newList){
            
            if(singleRecord.recordTypeId == agreementRecordTypeId)  {
                if(singleRecord.Project__c != oldMap.get(singleRecord.Id).Project__c){
                    agreementsList.add(singleRecord);
                    projectIdsList.add(singleRecord.Project__c);
                    projectIdsList.add(oldMap.get(singleRecord.Id).Project__c);
                    agreementProjectIdMap.put(singleRecord.Id, singleRecord.Project__c +'&&'+ oldMap.get(singleRecord.Id).Project__c);  
                    
                }
                if(singleRecord.HT_RevShare__c != oldMap.get(singleRecord.Id).HT_RevShare__c  && singleRecord.Agreement_Type__c=='Ground'){                
                    if(singleRecord.HT_RevShare__c== True){                
                        ActiveRevShareAgreementList.Add(singleRecord);
                        groundAgreementIds.Add(singleRecord.Id);
                        siteIDList.Add(singleRecord.Site__c);
                    }else{
                        groundInactiveRevShareAgreementIds.Add(singleRecord.Id); 
                    }      
                }
                if(singleRecord.Rent_Reduction__c != oldMap.get(singleRecord.Id).Rent_Reduction__c && singleRecord.Agreement_Type__c=='Anchor' ){
                    if(singleRecord.Rent_Reduction__c== True){  
                        ActiveRentReductionAgreementList.Add(singleRecord);
                        anchorAgreementIds.Add(singleRecord.Id);
                        siteIDList.Add(singleRecord.Site__c);
                    }else{
                        anchorInactiveRentReductionAgreementIds.Add(singleRecord.Id); 
                    }                
                }
                
                if(singleRecord.Rent_Commencement_Date__c != null && singleRecord.Rent_Commencement_Date__c != oldMap.get(singleRecord.Id).Rent_Commencement_Date__c && singleRecord.Agreement_Type__c=='Anchor' ){                    
                    taskGenerateagreementIdsList.add(singleRecord.Id);
                }
            }
            if(singleRecord.recordTypeId == relatedAgreementRecordTypeId)  {
                if (singleRecord.Contract_Fully_Executed__c != null && singleRecord.Parent_Agreement__c != null && 
                    (singleRecord.Related_Agreement_Reason__c =='Revised SDP Amendment' || singleRecord.Related_Agreement_Reason__c =='Reconciliation Amendment') &&
                    singleRecord.Contract_Fully_Executed__c != oldMap.get(singleRecord.Id).Contract_Fully_Executed__c) {
                        taskGenerateagreementIdsList.add(singleRecord.Parent_Agreement__c);
                        parentToChildCount.put(singleRecord.Parent_Agreement__c, 1);
                    }
            }
            
            //Added logic for auto task creation
            List<Task> returnList = HT_ProjectTriggerHandler.createTask(singleRecord,oldMap.get(singleRecord.Id), singleRecord.Id);
            if(!returnList.isEmpty())
                taskList.addAll(returnList);
        }
        
        
        if(! agreementsList.isEmpty())
            processAllAgreementRecords(agreementsList, projectIdsList, agreementProjectIdMap);
        
        if(! ActiveRevShareAgreementList.isEmpty())
            CreateRevShareRecordsForAgreement(ActiveRevShareAgreementList,groundAgreementIds,siteIDList);
        
        if(! groundInactiveRevShareAgreementIds.isEmpty())
            DisableRevShareRecordsForAgreement(groundInactiveRevShareAgreementIds);
        
        if(! ActiveRentReductionAgreementList.isEmpty())
            CreateRentReductionRecordsForAgreement(ActiveRentReductionAgreementList,anchorAgreementIds,siteIDList);
        if(! anchorInactiveRentReductionAgreementIds.isEmpty())
            DisableRentReductionRecordsForAgreement(anchorInactiveRentReductionAgreementIds);
        
        if(!taskGenerateagreementIdsList.isEmpty()) {
            List<Agreement__c> parentAgreements = [
                SELECT Id, Rent_Commencement_Date__c,
                (SELECT id from Child_RelatedAgreements__r WHERE Contract_Fully_Executed__c != null AND 
                 Related_Agreement_Reason__c IN ('Revised SDP Amendment', 'Reconciliation Amendment' )) 
                FROM Agreement__c
                WHERE Id IN :taskGenerateagreementIdsList AND Rent_Commencement_Date__c != null
            ];
            if(parentToChildCount.keyset().isEmpty())   {
                for (Agreement__c parentAgreement : parentAgreements) {
                    parentToChildCount.put(parentAgreement.Id, parentAgreement.Child_RelatedAgreements__r.size());
                }   
            }            
            insertTasksForParents(parentAgreements, parentToChildCount);
        }
        
        if(!taskList.isEmpty())            
            insert taskList;       
        
    }
    //Added By Masthan Andela as part of Case-00001937 on 07-31-2024
    public static void calculateRollup(List<Agreement__c> newList, Map<Id,Agreement__c>  oldMap){
        List<Id> siteIdsList = new List<Id>();
        Map<Id,List<Id>> siteGroundLeaseMap = new Map<Id,List<Id>>();
        List<Agreement__c> updateAgreementList = new List<Agreement__c>();
        Map<Id, AggregateResult> siteAggregateResultsMap = new Map<Id, AggregateResult>();
        List<Id> parentAgreementIdsList = new List<Id>();
        
        
        if(trigger.isDelete){
            for(Agreement__c singleRecord: oldMap.values()){
                if( singleRecord.recordTypeId == agreementRecordTypeId){
                    siteIdsList.add(singleRecord.Site__c);
                }else if(singleRecord.recordTypeId == relatedAgreementRecordTypeId){
                    parentAgreementIdsList.add(singleRecord.Parent_Agreement__c);
                }
            }
        }else{
            for(Agreement__c singleRecord : newList){
                
                if( singleRecord.recordTypeId == agreementRecordTypeId && (trigger.isInsert || trigger.isUndelete  || 
                   (trigger.isUpdate && singleRecord.Agreement_Type__c !='Ground' && (singleRecord.All_In_Commenced__c !=  oldMap.get(singleRecord.Id).All_In_Commenced__c ||
                   singleRecord.All_In_Executed_Not_Commenced__c !=  oldMap.get(singleRecord.Id).All_In_Executed_Not_Commenced__c ||
                   singleRecord.Revenue_Share_Included__c !=  oldMap.get(singleRecord.Id).Revenue_Share_Included__c )))){
                       siteIdsList.add(singleRecord.Site__c);
                       if(trigger.isUpdate)    siteIdsList.add( oldMap.get(singleRecord.Id).Site__c);            
                 }else if(singleRecord.Parent_Agreement__c != null && singleRecord.recordTypeId == relatedAgreementRecordTypeId &&
                          (trigger.isInsert || trigger.isUndelete  ||
                            (trigger.isUpdate && 
                             (singleRecord.Is_Commenced__c !=  oldMap.get(singleRecord.Id).Is_Commenced__c ||  
                              singleRecord.LeaseNet_Monthly_Rate__c  !=  oldMap.get(singleRecord.Id).LeaseNet_Monthly_Rate__c ||
                              singleRecord.Initial_Rent__c  !=  oldMap.get(singleRecord.Id).Initial_Rent__c  ) ))){
                                   parentAgreementIdsList.add(singleRecord.Parent_Agreement__c);
                                   if(trigger.isUpdate)    parentAgreementIdsList.add( oldMap.get(singleRecord.Id).Parent_Agreement__c);   
                }
            }
        }
        
      
        if(!siteIdsList.isEmpty()){
            for(Agreement__c groundLease : [SELECT Id,Site__c FROM Agreement__c WHERE Site__c IN :siteIdsList AND Agreement_Type__c ='Ground' AND RecordTypeId =: agreementRecordTypeId]){
                if(!siteGroundLeaseMap.containsKey(groundLease.Site__c)){
                    siteGroundLeaseMap.put(groundLease.Site__c, new List<Id>());
                }            
                siteGroundLeaseMap.get(groundLease.Site__c).add(groundLease.Id);
            }
            
            for(AggregateResult  aggregateRecord : [SELECT SUM(All_In_Commenced__c) All_In_Commenced__c, 
                                                    SUM(All_In_Executed_Not_Commenced__c) All_In_Executed_Not_Commenced__c,
                                                    SUM(Total_Revenue_Share__c) Total_Revenue_Share__c,
                                                    Site__c Site__c FROM Agreement__c
                                                    WHERE Revenue_Share_Included__c = TRUE AND Site__c IN :siteIdsList AND 
                                                    Agreement_Type__c !='Ground' AND 
                                                    Agreement_Type__c !='SDP' AND RecordTypeId =: agreementRecordTypeId GROUP BY Site__c]){
                                                        
                                                        siteAggregateResultsMap.put((Id)aggregateRecord.get('Site__c'), aggregateRecord);
                                                            
                                                            }
            
            
            for(Id siteId : siteGroundLeaseMap.keyset() ){ 
                for(Id agreementId : siteGroundLeaseMap.get(siteId) ){
                    Agreement__c updateAgreement = new Agreement__c(Id=agreementId, Sum_of_All_In_Commenced__c=0,
                                                                    Sum_of_All_In_Executed_Not_Commenced__c = 0 );
                    if(siteAggregateResultsMap.containsKey(siteId)){
                        updateAgreement.Sum_of_All_In_Commenced__c= (decimal)siteAggregateResultsMap.get(siteId).get('All_In_Commenced__c');
                        updateAgreement.Sum_of_All_In_Executed_Not_Commenced__c= (decimal)siteAggregateResultsMap.get(siteId).get('All_In_Executed_Not_Commenced__c');
                        updateAgreement.Sum_of_Total_Revenue_Share__c= (decimal)siteAggregateResultsMap.get(siteId).get('Total_Revenue_Share__c');
                    }
                    updateAgreementList.add(updateAgreement);  
                } 
            }
            
            if(!updateAgreementList.isEmpty()){
                isValidateOnEdit = FALSE;
                update updateAgreementList;
            }
        }
        
        
        if(!parentAgreementIdsList.isEmpty()){
            calculateReatedAgreementRollup(parentAgreementIdsList);
        }
        
        
    }
    
    
    public static void calculateReatedAgreementRollup( List<Id> parentAgreementIdsList){
        
        List<Agreement__c> updateAgreementList = new List<Agreement__c>();
        
        for(AggregateResult  aggregateRecord : [SELECT SUM(Commenced__c) Commenced__c, 
                                                SUM(Executed_Not_Commenced__c) Executed_Not_Commenced__c,
                                                Parent_Agreement__c Parent_Agreement__c FROM Agreement__c
                                                WHERE Parent_Agreement__c IN :parentAgreementIdsList AND 
                                                RecordTypeId =: relatedAgreementRecordTypeId GROUP BY Parent_Agreement__c]){
                                                    
                                                    updateAgreementList.add(new Agreement__c(Id= (Id)aggregateRecord.get('Parent_Agreement__c'),
                                                                                            Agreement_Total_Commenced__c = (decimal)aggregateRecord.get('Commenced__c'),
                                                                                            Agreement_Executed_Not_Commenced__c = (decimal)aggregateRecord.get('Executed_Not_Commenced__c')
                                                                                            ));
                                                    
                                                }
        
        if(!updateAgreementList.isEmpty()){
            isValidateOnEdit = FALSE;
            update updateAgreementList;
        }
    }
    
    
    public static void processAllAgreementRecords(List<Agreement__c> newList, List<Id> projectIdList, Map<Id, String> agreementProjectIdMap){
        
        Map<Id, All_Agreement__c> allAgreementProjectMap = new Map<Id, All_Agreement__c>();
        Map<Id, List<All_Agreement__c>> allAgreementAgreementMap = new Map<Id, List<All_Agreement__c>>();
        List<All_Agreement__c> upsertAllAgreementList = new List<All_Agreement__c>();
        List<All_Agreement__c> deleteAllAgreementList = new List<All_Agreement__c>();
        
        
        List<All_Agreement__c> updatableAllAgreements = [SELECT Id, Project__c, Related_Agreement__c, Project_Acceptance__c, Agreement__c FROM All_Agreement__c
                                                         WHERE Project__c IN :projectIdList OR Agreement__c IN :agreementProjectIdMap.keyset()];
        
        system.debug(agreementProjectIdMap.keyset());
        for(All_Agreement__c singleRecord : updatableAllAgreements){
            system.debug(singleRecord);
            if( singleRecord.Project__c != null && ((allAgreementProjectMap.containsKey(singleRecord.Project__c) && 
                                                     allAgreementProjectMap.get(singleRecord.Project__c).Agreement__c != null) ||
                                                    !allAgreementProjectMap.containsKey(singleRecord.Project__c))){
                                                        allAgreementProjectMap.put(singleRecord.Project__c, singleRecord);   
                                                    }
            if(singleRecord.Agreement__c != null){
                if(!allAgreementAgreementMap.containsKey(singleRecord.Agreement__c)){
                    allAgreementAgreementMap.put(singleRecord.Agreement__c, new List<All_Agreement__c>());
                }
                allAgreementAgreementMap.get(singleRecord.Agreement__c).add(singleRecord);                     
            }
        }
        
        system.debug(allAgreementProjectMap);
        
        for(Agreement__c singleRecord : newList){
            
            String oldProjectId = '';
            if(!agreementProjectIdMap.keyset().isEmpty()){
                system.debug(agreementProjectIdMap);
                oldProjectId = agreementProjectIdMap.get(singleRecord.Id).split('&&')[1];
                oldProjectId = oldProjectId != 'null' ? oldProjectId :'';
            }
            if(String.isBlank(oldProjectId) && singleRecord.Project__c != null && allAgreementProjectMap != null && !allAgreementProjectMap.keyset().isEmpty() &&
               allAgreementProjectMap.containsKey(singleRecord.Project__c)){                      
                   All_Agreement__c allAgreementRecord = allAgreementProjectMap.get(singleRecord.Project__c);
                   
                   if(allAgreementAgreementMap != null && allAgreementAgreementMap.containsKey(singleRecord.Id)){
                       for(All_Agreement__c singleAgreementRecord : allAgreementAgreementMap.get(singleRecord.Id)){
                           singleAgreementRecord.Project__c = singleRecord.Project__c;
                           singleAgreementRecord.Project_Acceptance__c = allAgreementRecord.Project_Acceptance__c;
                           upsertAllAgreementList.add(singleAgreementRecord); 
                       }
                       
                   }else if(allAgreementRecord.Agreement__c != NULL){
                       upsertAllAgreementList.add( HT_ProjectTriggerHandler.createAllAgreements(new Map<String,Id>{'Project__c' => singleRecord.Project__c,
                           'Project_Acceptance__c' => allAgreementRecord.Project_Acceptance__c,
                           'Agreement__c' => singleRecord.Id}));
                       
                   }
                   
                   if(allAgreementRecord.Agreement__c == NULL && !allAgreementAgreementMap.containsKey(singleRecord.Id)){
                       allAgreementRecord.Agreement__c = singleRecord.Id;
                       upsertAllAgreementList.add(allAgreementRecord);
                   }else  if(allAgreementRecord.Agreement__c == NULL && allAgreementAgreementMap.containsKey(singleRecord.Id)){
                       deleteAllAgreementList.add(allAgreementRecord);
                   }
                   
               }else if(String.isNotBlank(oldProjectId) ){      
                   All_Agreement__c allAgreementRecord = allAgreementProjectMap.get(singleRecord.Project__c);
                   boolean isRunRecord = false;
                   if(allAgreementAgreementMap != null && allAgreementAgreementMap.containsKey(singleRecord.Id)){
                       for(All_Agreement__c singleAgreementRecord : allAgreementAgreementMap.get(singleRecord.Id)){
                           if(singleRecord.Project__c != null){
                               singleAgreementRecord.Project__c = singleRecord.Project__c;
                               singleAgreementRecord.Project_Acceptance__c = allAgreementRecord.Project_Acceptance__c;                                
                               upsertAllAgreementList.add(singleAgreementRecord); 
                           }else{
                               singleAgreementRecord.Project__c = null;
                               singleAgreementRecord.Project_Acceptance__c = null;
                               if(isRunRecord ){
                                   deleteAllAgreementList.add(singleAgreementRecord);
                               }else{                                    
                                   upsertAllAgreementList.add(singleAgreementRecord); 
                               }
                               if(singleAgreementRecord.Related_Agreement__c == NULL){
                                   isRunRecord = true;
                               }
                           }
                           
                       }
                   }
                   system.debug(allAgreementAgreementMap);
               }else {
                   upsertAllAgreementList.add(HT_ProjectTriggerHandler.createAllAgreements(new Map<String,Id>{'Agreement__c' => singleRecord.Id}));                  
               }
        }  
        system.debug(upsertAllAgreementList);
        system.debug(deleteAllAgreementList);
        // system.assertequals('test','false');
        if(!upsertAllAgreementList.isEmpty()){
            upsert upsertAllAgreementList;
        }
        if(!deleteAllAgreementList.isEmpty()){
            delete deleteAllAgreementList;
        }
    }
    
    
    public static void CreateRevShareRecordsForAgreement(List<Agreement__c> newList,List<Id> groundAgreementIds , List<Id> siteIDList){
        List<HT_Revshare__c> revshareRecords = new List<HT_Revshare__c>();
        List<HT_RevShare__C> existingRevShareRecords = [SELECT Id , GroundLeaseAgreement__c,ColocationAgreement__c FROM HT_RevShare__C WHERE GroundLeaseAgreement__c in  :groundAgreementIds ];
        List<Agreement__c> colocationAllAgreements = [SELECT Id, Site__c FROM Agreement__c WHERE Site__c in :siteIDList AND (Agreement_Type__c = 'Colocation' OR Agreement_Type__c = 'Anchor') ];
        Map<Id,List<Agreement__c>> siteAgreementMap = new Map<Id,List<Agreement__c>>();
        Map<Id,List<Id>> groundExistingRevShareMap = new Map<Id,List<Id>>();
        Map<Id, HT_RevShare__C> collocationRevShareMap = new Map<Id,HT_RevShare__C>();
        
        
        for(HT_RevShare__C singleRecord:existingRevShareRecords) {
            collocationRevShareMap.put(singleRecord.ColocationAgreement__c, singleRecord);
        }
        
        for(Agreement__c singleAgreement:colocationAllAgreements){
            if(!siteAgreementMap.containsKey(singleAgreement.Site__c)){
                siteAgreementMap.put(singleAgreement.Site__c, new List<Agreement__c>());
            }            
            siteAgreementMap.get(singleAgreement.Site__c).add(singleAgreement);
        }
        
        List<HT_RevShare__c> addRevShare = new  List<HT_RevShare__c>();
        
        for(Agreement__c singleRecord:newList){  
            
            if (siteAgreementMap.containsKey(singleRecord.Site__c)  && !siteAgreementMap.get(singleRecord.Site__c).isEmpty() ) {
                
                List<Agreement__c> linkedColocationAgreements = new List<Agreement__c>(); 
                
                for (Agreement__c linkedColos: siteAgreementMap.get(singleRecord.Site__c)){
                    if(!collocationRevShareMap.containsKey(linkedColos.Id))
                        addRevShare.Add( new HT_RevShare__c(GroundLeaseAgreement__c=singleRecord.Id, ColocationAgreement__c= linkedColos.Id));
                }
                
            }
        }
        
        if (!addRevShare.isEmpty()) {
            system.Debug('Entered Update was made for colocation ' +addRevShare );
            insert addRevShare;
        } 
    }
    public static void CreateRentReductionRecordsForAgreement(List<Agreement__c> newList,List<Id> anchorAgreementIds , List<Id> siteIDList){
        system.Debug('Entered Update for disablingHK ' +anchorAgreementIds);
        List<HT_RentReduction__c> rentReductionRecords = new List<HT_RentReduction__c>();
        List<HT_RentReduction__c> existingRentReductionRecords = [SELECT Id , AnchorAgreement__c,ColocationAgreement__c FROM HT_RentReduction__c WHERE AnchorAgreement__c in  :anchorAgreementIds ];
        List<Agreement__c> colocationAllAgreements = [SELECT Id, Site__c FROM Agreement__c WHERE Site__c in :siteIDList AND (Agreement_Type__c = 'Colocation') ];
        Map<Id,List<Agreement__c>> siteAgreementMap = new Map<Id,List<Agreement__c>>();
        Map<Id,List<Id>> anchorExistingRntReductionMap = new Map<Id,List<Id>>();
        Map<Id, HT_RentReduction__c> collocationRentReductionMap = new Map<Id,HT_RentReduction__c>();
        
        
        for(HT_RentReduction__c singleRecord:existingRentReductionRecords) {
            collocationRentReductionMap.put(singleRecord.ColocationAgreement__c, singleRecord);
        }
        for(Agreement__c singleAgreement:colocationAllAgreements){
            if(!siteAgreementMap.containsKey(singleAgreement.Site__c)){
                siteAgreementMap.put(singleAgreement.Site__c, new List<Agreement__c>());
            }            
            siteAgreementMap.get(singleAgreement.Site__c).add(singleAgreement);
        }
        
        List<HT_RentReduction__c> addRentReduction = new  List<HT_RentReduction__c>();
        
        for(Agreement__c singleRecord:newList){  
            
            if (siteAgreementMap.containsKey(singleRecord.Site__c)  && !siteAgreementMap.get(singleRecord.Site__c).isEmpty() ) {
                
                List<Agreement__c> linkedColocationAgreements = new List<Agreement__c>(); 
                
                for (Agreement__c linkedColos: siteAgreementMap.get(singleRecord.Site__c)){
                    if(!collocationRentReductionMap.containsKey(linkedColos.Id))
                        addRentReduction.Add( new HT_RentReduction__c(AnchorAgreement__c=singleRecord.Id, ColocationAgreement__c= linkedColos.Id));
                }
            }
        }
        
        if (!addRentReduction.isEmpty()) {
            insert addRentReduction;
        }
        
        
        
        
        
    }
    // when ground lease rev share is disabled , uncheck the associated colocation agreement revshare checkbox.
    public static void DisableRevShareRecordsForAgreement(List<Id> groundAgreementIds ){
        List<HT_Revshare__c> revshareRecords = new List<HT_Revshare__c>();
        List<Id> colocationAgreementIDs = new List<Id>();
        List<Agreement__c> colocation = new List<Agreement__c>();
        List<Agreement__c> listToUpdate = new List<Agreement__c>();
        List<HT_RevShare__C> existingRevShareRecords = [SELECT Id , GroundLeaseAgreement__c,ColocationAgreement__c FROM HT_RevShare__C WHERE GroundLeaseAgreement__c in  :groundAgreementIds ];
        for(HT_RevShare__C  currentRecord:existingRevShareRecords){  
            
            if(currentRecord.ColocationAgreement__c!=null)
            {
                colocationAgreementIDs.add(currentRecord.ColocationAgreement__c);
                listToUpdate.Add(new Agreement__c(Id=currentRecord.ColocationAgreement__c,Revenue_Share_Included__c=false));
            }
            
        }
        Update listToUpdate;
        
        
    }
    public static void DisableRentReductionRecordsForAgreement(List<Id> anchorAgreementIds ){
        List<HT_RentReduction__c> revshareRecords = new List<HT_RentReduction__c>();
        List<Id> colocationAgreementIDs = new List<Id>();
        List<Agreement__c> colocation = new List<Agreement__c>();
        List<Agreement__c> listToUpdate = new List<Agreement__c>();
        List<HT_RentReduction__c> existingRentReductionRecords = [SELECT Id , AnchorAgreement__c,ColocationAgreement__c FROM HT_RentReduction__c WHERE AnchorAgreement__c in  :anchorAgreementIds ];
        for(HT_RentReduction__c  currentRecord:existingRentReductionRecords){  
            
            if(currentRecord.ColocationAgreement__c!=null)
            {
                colocationAgreementIDs.add(currentRecord.ColocationAgreement__c);
                listToUpdate.Add(new Agreement__c(Id=currentRecord.ColocationAgreement__c,Rent_Reduction_Included__c=false));
            }
            
        }
        Update listToUpdate;
        
        
    }
    
    public static void updateSDPActiveCheckbox(List<Id> agreementIdList) { 
        List<Agreement__c> updateAgreementList = [SELECT Id, SDP_Active_Record__c FROM Agreement__c 
                                                                 WHERE SDP_Active_Record__c=TRUE AND Parent_Agreement__c IN :agreementIdList];
        for(Agreement__c singleRecord : updateAgreementList){
            singleRecord.SDP_Active_Record__c = FALSE;
        }
        
        if(!updateAgreementList.isEmpty()){
            update updateAgreementList;
        }        
    }
    
    
    public static void insertTasksForParents(List<Agreement__c> parents, Map<Id, Integer> taskCountMap) {
        if (parents.isEmpty() || taskCountMap.isEmpty()) return;
        
        Group reAdminQueue = [SELECT Id FROM Group WHERE DeveloperName = 'RE_Admin' AND Type = 'Queue' LIMIT 1];
        
        List<Task> tasksToCreate = new List<Task>();
        
        for (Agreement__c parent : parents) {
            Integer count = taskCountMap.get(parent.Id);
            for (Integer i = 0; i < count; i++) {
                tasksToCreate.add(new Task(Subject = 'Amendment FE, Push Mod', WhatId = parent.Id,  OwnerId = reAdminQueue.Id, Status = 'Not Started', Priority = 'Normal'));
            }
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}