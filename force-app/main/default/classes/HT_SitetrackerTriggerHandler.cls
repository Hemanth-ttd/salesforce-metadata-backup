global class HT_SitetrackerTriggerHandler extends strk.StTriggerHandler implements strk.StITrigger {   
    global static String SOBJECT_TYPE;
    global  Map<Id, SObject> approvalProcessTemplateChangeRecordMap = new Map<Id, SObject>();
    global Static boolean approvalAssigned = false;
    global Static Boolean isApprovalEnabled;
    
    global override void initializeExtended( String sObjectName ){
        system.debug(sObjectName);
         Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{sObjectName});
                SOBJECT_TYPE = String.valueof(results[0].getSobjectType());
        isApprovalEnabled = strk__SiteTraker_Object__mdt.getAll().get(sObjectName.replace('__','_')).strk__Enable_Approval_Process__c;
   
        if( Trigger.isAfter && !Trigger.isDelete && isApprovalEnabled) {
            Harmoni_STApprovalUtility.initReviewerMatrices();
        }
    }   
    global override void bulkBeforeExtended(){}    
    global override void bulkAfterExtended(){
        approvalProcessTemplateChangeRecordMap = new Map<Id, SObject>();
    }   
    global override void beforeInsertExtended(SObject newObject){
        // ... Sitetracker logic down here
       if(isApprovalEnabled) Harmoni_STApprovalUtility.handleSetupApprovalProcessTemplateFieldOnSObject(newObject);
    } 
    global override void afterInsertExtended(SObject newObject){
          // ... Sitetracker logic down here
     if(isApprovalEnabled)   Harmoni_STApprovalUtility.handleInitialApprovalAssignmentAfterInsert(
            newObject, SOBJECT_TYPE, approvalProcessTemplateChangeRecordMap
        );
    }  
    global override void beforeUpdateExtended(SObject oldSo, SObject newObject){
        
        // ... Sitetracker logic down here
       if(isApprovalEnabled) Harmoni_STApprovalUtility.handleSetupApprovalProcessTemplateFieldChangeOnSObject(newObject);
        
    }   
    global override void afterUpdateExtended(SObject oldObject, SObject newObject){
        // ... Sitetracker logic down here
        if (isApprovalEnabled && Harmoni_STApprovalUtility.checkOnUpdateApprovalFieldChange(oldObject, newObject)) {
            Harmoni_STApprovalUtility.handleInitialApprovalAssignmentAfterUpdate(
                oldObject,
                newObject,
                SOBJECT_TYPE,
                approvalProcessTemplateChangeRecordMap
            );
        }
    } 
    global override void beforeDeleteExtended(SObject so){}   
    global override void afterDeleteExtended(SObject so){}   
    global override void andFinallyExtended(){
          // ... Sitetracker logic down here
        if(isApprovalEnabled && !approvalAssigned && Trigger.isAfter && !approvalProcessTemplateChangeRecordMap.isEmpty()){
            Harmoni_STApprovalUtility.handleFinalApprovalProcessSetupOnAfter(
                SOBJECT_TYPE,
                approvalProcessTemplateChangeRecordMap
            );
            approvalAssigned = true;
            approvalProcessTemplateChangeRecordMap.clear();
        }
    }
}