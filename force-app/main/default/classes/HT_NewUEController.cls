public class HT_NewUEController {
    
    @AuraEnabled
    public static Id createUE (Id projectId)
    {
       
        strk__Project__c currentProject = [SELECT Id,strk__Site__c, strk__Site__r.BD_Lead__c, (SELECT Id FROM Unit_Economics__r WHERE Project_Acceptance__c = null) FROM strk__Project__c WHERE Id =:projectId];
        Unit_Economics__c newUE = new Unit_Economics__c(Project__c = currentProject.Id, Site__c = currentProject.strk__Site__c);
          newUE.BD_Lead__c = currentProject.strk__Site__r.BD_Lead__c;
         newUE.Version__c = currentProject.Unit_Economics__r == null ? 2: currentProject.Unit_Economics__r.size()+2;
        // newProjectAcceptanceRecord.RUCA_Code__c = currentSite.RUCA_Code__c;
        //  newProjectAcceptanceRecord.Classification__c = currentSite.RUCA_Description__c;
        Team_config__mdt teamDetails = Team_config__mdt.getInstance('New_Project_Acceptance_Team_config');
        if(teamDetails != null){
            newUE.Chief_Development_Officer__c =  teamDetails.Chief_Development_Officer__c;// '0058W00000D7AqsQAF';
            newUE.Chief_Executive_Officer__c = teamDetails.Chief_Executive_Officer__c;//'0058W00000D7AqsQAF';
            newUE.Chief_Financial_Officer__c =teamDetails.Chief_Financial_Officer__c;// '0058W00000D7AqsQAF';
            newUE.BD_Sr_Vice_President__c = teamDetails.BD_Sr_Vice_President__c;//'0058W00000D7AqsQAF';
            newUE.Finance_Sr_Vice_President__c = teamDetails.Finance_Sr_Vice_President__c;//'0058W00000D7AqsQAF';
            newUE.Attorney__c = teamDetails.Attorney__c;//'0058W00000D7AqsQAF';
        }
      
        
         // Fetch last approved CAPEX
            Unit_Economics__c lastApprovedCapex;
            List<Unit_Economics__c> results = [
                SELECT Total_Capex__c 
                FROM Unit_Economics__c 
                WHERE Project__r.Id =:projectId
                    AND ( Approval_Status__c = 'Approved' OR Approval_Status__c = 'Bulk Approved')
                  //  AND Approval_Process_Template__c != NULL
               ORDER BY Approval_Process_Decision_Date__c DESC
               LIMIT 1
            ];

        
               if (!results.isEmpty()) {
                   lastApprovedCapex = results[0];
                    system.debug('Determine last approved capex'+  lastApprovedCapex);
                newUE.Approval_Process_Approved_Capex__c = 
            (lastApprovedCapex != null && lastApprovedCapex.Total_Capex__c != null) 
            ? lastApprovedCapex.Total_Capex__c 
                    : 0;}
                
        insert newUE;
        return newUE.Id;
    }   
    
}