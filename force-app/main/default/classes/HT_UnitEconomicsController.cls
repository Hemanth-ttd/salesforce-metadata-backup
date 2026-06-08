public with sharing class HT_UnitEconomicsController {
    @AuraEnabled
    public static Unit_Economics__c getUnitEconomicsData(Id recordId) {
        try {
            return [
                SELECT  Approval_Process__c,
                Approval_Process__r.Name,
                Approval_Process__r.strk__Status__c ,
                Approval_Process__r.strk__Active__c,
                Approval_Process__r.strk__Allow_Recalls__c,
                Approval_Process__r.strk__Initiator__c,
                Approval_Process__r.strk__Object_Name__c,
                Approval_Process__r.strk__Record_Name__c,
                Approval_Process__r.strk__Approval_Submitted_Date__c ,
                Approval_Process__r.Id, Total_Capex__c, X8_Year_IRR__c
                FROM Unit_Economics__c 
                WHERE Id = :recordId LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching unit economics data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getApprovalRecordId(Id recordId, String fieldName) {
        try{
            Schema.SObjectType sobjectType = recordId.getSObjectType();
            List<Sobject> responseRecords = Database.query('SELECT ID,'+fieldName+' FROM '+
                                                           sobjectType.getDescribe().getName() +
                                                           ' WHERE Id =:recordId');
            if(!responseRecords.isEmpty()){
                return String.valueof(responseRecords[0].get(fieldName));
            }else{
               throw new AuraHandledException('Error fetching record data: '+recordId);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching record data: ' + e.getMessage());
        }
    }
}