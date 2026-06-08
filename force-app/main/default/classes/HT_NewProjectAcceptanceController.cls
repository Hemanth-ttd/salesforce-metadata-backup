public class HT_NewProjectAcceptanceController {
    
    @AuraEnabled
    public static Id createProjectAcceptance (Id siteId)
    {
        strk__Site__c currentSite = [SELECT Id,BD_Lead__c,RUCA_Code__c,RUCA_Description__c FROM strk__Site__c WHERE Id =:siteId];
        Project_Acceptance__c newProjectAcceptanceRecord = new Project_Acceptance__c(Site__c = currentSite.Id);
        newProjectAcceptanceRecord.BD_Lead__c = currentSite.BD_Lead__c;
        newProjectAcceptanceRecord.RUCA_Code__c = currentSite.RUCA_Code__c;
        newProjectAcceptanceRecord.Classification__c = currentSite.RUCA_Description__c;
        Team_config__mdt teamDetails = Team_config__mdt.getInstance('New_Project_Acceptance_Team_config');
        if(teamDetails != null){
            newProjectAcceptanceRecord.Chief_Development_Officer__c =  teamDetails.Chief_Development_Officer__c;// '0058W00000D7AqsQAF';
            newProjectAcceptanceRecord.Chief_Executive_Officer__c = teamDetails.Chief_Executive_Officer__c;//'0058W00000D7AqsQAF';
            newProjectAcceptanceRecord.Chief_Financial_Officer__c =teamDetails.Chief_Financial_Officer__c;// '0058W00000D7AqsQAF';
            newProjectAcceptanceRecord.BD_Sr_Vice_President__c = teamDetails.BD_Sr_Vice_President__c;//'0058W00000D7AqsQAF';
            newProjectAcceptanceRecord.Finance_Sr_Vice_President__c = teamDetails.Finance_Sr_Vice_President__c;//'0058W00000D7AqsQAF';
            newProjectAcceptanceRecord.Attorney__c = teamDetails.Attorney__c;//'0058W00000D7AqsQAF';
        }
        insert newProjectAcceptanceRecord;
        return newProjectAcceptanceRecord.Id;
    }    
}