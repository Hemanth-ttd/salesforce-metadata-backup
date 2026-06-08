public class HT_CustomTwinFeilds {
    Public Static SObjectType targetSObjectType;
    public static void crateTwinfieldRecord(List<Id> recordIdsList, String sourceObjectName, String targetObjectName){  
        List<Sobject> newRecordsList = new List<Sobject>();
        List<String> twinFeilds = getTwinFields(sourceObjectName, targetObjectName);
        List<Sobject> sourceRecordsList = database.query('SELECT Id, ' +String.join(twinFeilds,',') +'  FROM '+sourceObjectName +' WHERE Id IN :recordIdsList');
        for(Sobject singleRecord : sourceRecordsList) {
            Sobject newRecord = targetSObjectType.newSObject();
            for(String fieldName : twinFeilds){
                newRecord.put(fieldName, singleRecord.get(fieldName));
            }
            newRecord.put('Project_Acceptance__c',singleRecord.get('Id') );
            newRecord.put('Version__c',1);
            newRecord.put('Latest_Unit_Economics__c',TRUE);  
            newRecord.put('Approval_Process_Approved_Capex__c',singleRecord.get('Total_Capex__c'));
            newRecord.Put('Approval_Status__c','Approved');
            newRecord.Put('Approval_Process_Decision_Date__c', DateTime.Now());
            newRecordsList.add(newRecord);
        }
        if(!newRecordsList.isEmpty()){
            insert newRecordsList;
        }
    }
    
    
    
    public static List<String> getTwinFields(String sourceObjectName, String targetObjectName){  
        // 
        List<String> twinFieldsList = new List<String>();
        Map<String, Schema.SObjectField> sourceFieldsMap = new Map<String, Schema.SObjectField>();
        Map<String, Schema.SObjectField> targetFieldsMap = new Map<String, Schema.SObjectField>();
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{sourceObjectName,targetObjectName});
        
        for(Schema.DescribeSobjectResult res : results) {            
            if(res.getName() == sourceObjectName){
                sourceFieldsMap = res.fields.getMap();
            }
            if(res.getName() == targetObjectName){
                targetFieldsMap = res.fields.getMap();
                targetSObjectType = res.getSobjectType();
            }
            
        }
        for(String fieldName: sourceFieldsMap.keyset()){
            if(targetFieldsMap.containsKey(fieldName)){
                Schema.DescribeFieldResult  sourceField = sourceFieldsMap.get(fieldName).getDescribe();
                Schema.DescribeFieldResult  targetField = targetFieldsMap.get(fieldName).getDescribe();
                if(sourceField.getType() == targetField.getType() && targetField.isCustom() && targetField.isUpdateable()){
                    twinFieldsList.add(fieldName);
                }
                
            }
            
        }
        return twinFieldsList;
    }
    
}