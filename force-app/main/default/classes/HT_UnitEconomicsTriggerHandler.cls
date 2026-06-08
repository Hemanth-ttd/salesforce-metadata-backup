public class HT_UnitEconomicsTriggerHandler {
    
   public static void executeBeforeInertTrigger(List<Unit_Economics__c> newList){
        List<Id> projectIdsList = new List<Id>();
   
        for(Unit_Economics__c singleRecord : newList){
            if(singleRecord.Latest_Unit_Economics__c == TRUE && singleRecord.Project__c != null){
                projectIdsList.add(singleRecord.Project__c);
            }            
        }
        
       if(!projectIdsList.isEmpty()) updateUEApprovedCheckbox(projectIdsList);
    }
    
    /*  public static void executeAfterInertTrigger(List<Unit_Economics__c> newList){
}*/
    
    public static void executeBeforeUpdateTrigger(List<Unit_Economics__c> newList, Map<Id,Unit_Economics__c>  oldMap){
        List<Id> projectIdsList = new List<Id>();
       
     
        for(Unit_Economics__c singleRecord : newList){
         //   Decimal IRRCompare = (singleRecord.X8_Year_IRR__c != null && singleRecord.Unlevered_IRR_w_Pipeline_Colo__c != null) ? 
   // (singleRecord.X8_Year_IRR__c > singleRecord.Unlevered_IRR_w_Pipeline_Colo__c ? singleRecord.X8_Year_IRR__c : singleRecord.Unlevered_IRR_w_Pipeline_Colo__c) :
    //(singleRecord.X8_Year_IRR__c != null ? singleRecord.X8_Year_IRR__c : (singleRecord.Unlevered_IRR_w_Pipeline_Colo__c != null ? singleRecord.Unlevered_IRR_w_Pipeline_Colo__c : 0));

            
           // decimal IRRCompare = Math.Max(singleRecord.X8_Year_IRR__c,singleRecord.Unlevered_IRR_w_Pipeline_Colo__c);
            // if(Math.Max(singleRecord.X8_Year_IRR__c,singleRecord.Unlevered_IRR_w_Pipeline_Colo__c) >=10 && singleRecord.ChangedTotalCapex__c <50000 && 
              if(( singleRecord.X8_Year_IRR__c  >=10) && singleRecord.ChangedTotalCapex__c <50000 && 
                singleRecord.Approval_Status__c !='Auto Approved' &&  singleRecord.Approval_Status__c !='Approved'){
                singleRecord.Approval_Status__c='Auto Approved';
                singleRecord.Approval_Process_Decision_Date__c = DateTime.Now();
                singleRecord.Latest_Unit_Economics__c = TRUE;                   
            }
            
            if (singleRecord.Approval_Status__c == 'Approved' && oldMap.get(singleRecord.Id).Approval_Status__c != 'Approved') {
                singleRecord.Approval_Process_Decision_Date__c = DateTime.Now();
                singleRecord.Latest_Unit_Economics__c = TRUE;  
            }              
            
           if(singleRecord.Latest_Unit_Economics__c == TRUE
             &&                singleRecord.Latest_Unit_Economics__c != oldMap.get(singleRecord.Id).Latest_Unit_Economics__c &&
               singleRecord.Project__c != null)
           
           {
                   projectIdsList.add(singleRecord.Project__c);
                  
               }           
        }
       if(!projectIdsList.isEmpty())  updateUEApprovedCheckbox(projectIdsList);
        
    }
    
    /*  public static void executeAfterUpdateTrigger(List<Unit_Economics__c> newList, Map<Id,Unit_Economics__c>  oldMap){

}*/
    
    
 /*   public static void updateUEApprovedCheckbox(List<Id> projectIdsList , Set<Id> newRecordIds) { 
        List<Unit_Economics__c> updateUEList = [SELECT Id, Latest_Unit_Economics__c FROM Unit_Economics__c 
                                                WHERE Latest_Unit_Economics__c=TRUE AND Project__c IN :projectIdsList  AND Id NOT IN :newRecordIds];
        
        for(Unit_Economics__c singleRecord : updateUEList){
            singleRecord.Latest_Unit_Economics__c = FALSE;
        }
        system.debug('Update UE List' + updateUEList);
        if(!updateUEList.isEmpty()){
            update updateUEList;
        }
        
    }*/
    
       public static void updateUEApprovedCheckbox(List<Id> projectIdsList ) { 
        List<Unit_Economics__c> updateUEList = [SELECT Id, Latest_Unit_Economics__c FROM Unit_Economics__c 
                                                WHERE Latest_Unit_Economics__c=TRUE AND Project__c IN :projectIdsList ];
        
        for(Unit_Economics__c singleRecord : updateUEList){
            singleRecord.Latest_Unit_Economics__c = FALSE;
        }
        system.debug('Update UE List' + updateUEList);
        if(!updateUEList.isEmpty()){
            update updateUEList;
        }
        
    }
    
}