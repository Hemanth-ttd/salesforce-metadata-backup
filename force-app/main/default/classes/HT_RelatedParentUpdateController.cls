public class HT_RelatedParentUpdateController {

    @AuraEnabled(cacheable=true)
    public static List<Sobject> getChildRecords (Id parentRecordId, String childObjectName, String childFieldSetName, String relationFieldName, String secondaryParentFeildName){
   	 String queryString ='SELECT Id, Name,'+ secondaryParentFeildName +' FROM '+childObjectName +' WHERE '+relationFieldName +' =:parentRecordId AND '+secondaryParentFeildName +'!= null';
       system.debug(queryString);
       // system.assert(false);
        List<Sobject> childRecordsList = database.query(queryString);
        return childRecordsList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FieldSetWrapper> getFieldSet(String fieldSetName, String objectName) {
        List<FieldSetWrapper> lstfieldWrapper = new List<FieldSetWrapper>();
        if (String.isNotBlank(fieldSetName) && String.isNotBlank(ObjectName)) {
            Schema.DescribeSObjectResult describeSObjectResult = Schema.describeSObjects(new List<String>{ObjectName})[0];
                
                
                //Schema.getGlobalDescribe().get(ObjectName).getDescribe();
            Map<String,Schema.SObjectField> objFieldMap = describeSObjectResult.fields.getMap();
            Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap().get(fieldSetName);
            if (fieldSetObj != null) {
                for(Schema.FieldSetMember fieldSet : fieldSetObj.getFields() ) {
                    lstfieldWrapper.add( new FieldSetWrapper(
                        String.ValueOf(fieldSet.getLabel()),
                        String.ValueOf(fieldSet.getFieldPath()), 
                        (fieldSet.getDBRequired() || fieldSet.getRequired()),
                        objFieldMap.get(String.ValueOf(fieldSet.getFieldPath())).getDescribe().getInlineHelpText(),
                        objFieldMap.get(String.ValueOf(fieldSet.getFieldPath())).getDescribe().isHtmlFormatted() &&
                        objFieldMap.get(String.ValueOf(fieldSet.getFieldPath())).getDescribe().isCalculated()
                    ));
                }
            }
        }
        return lstfieldWrapper; 
    }
    
    public class FieldSetWrapper {
        @AuraEnabled public String fieldName {get;set;}
        @AuraEnabled public String fieldLabel {get;set;}
        @AuraEnabled public Boolean isRequired {get;set;}
        @AuraEnabled public String helpText {get;set;}
        @AuraEnabled public Boolean isHtmlFormatted {get;set;}
        
        public FieldSetWrapper(String fieldLabel,String fieldName,Boolean isRequired, String helpText, Boolean isHtmlFormatted ) {
            this.fieldLabel  = fieldLabel;
            this.fieldName   = fieldName;
            this.isRequired  = isRequired;
            this.helpText    = helpText;
            this.isHtmlFormatted = isHtmlFormatted;
        }
    }
    
}