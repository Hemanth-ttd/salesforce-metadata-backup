/**
 * Created by TUpadhyaya on 8/7/2018.
 */
global without sharing class IntegrationResponseTriggerHandler implements strk.StITrigger {
	List<strk__Project__c> updatedProjects;
/*
     * This method is called once in the beginning of each trigger context
     * and should be used for initializing information.  The name of the
     * SObjectType will be passed as a string to the method. 
    */
    public void initialize(String sObjectTypeName) {
    	updatedProjects = new List<strk__Project__c>();
    }      
     
    /*
     * The bulkBefore() and bulkAfter() methods are called once for each trigger
     * event (once for entire Trigger.new), prior to executing the individual methods below. 
     * You can access the Trigger context variables here (Trigger.new and Trigger.old) as needed
     * provided they are available, e.g Trigger.old not available in before insert event
    */
    public void bulkBefore() {}
    public void bulkAfter()  {
    	if(Trigger.isInsert){
    		for(SObject record : Trigger.new){
    			 Integration_Response__c integrationResp = ( Integration_Response__c ) record;
    			 if(String.isNotBlank(integrationResp.Project__c) && String.isNotBlank(integrationResp.Response_Message__c)){
                    strk__Project__c tempProj = new strk__Project__c(id=integrationResp.Project__c,Latest_Integration_Response__c = integrationResp.Response_Message__c);
                    if(String.isNotBlank(integrationResp.External_Project_ID__c)){
                        tempProj.Oracle_ID__c = integrationResp.External_Project_ID__c;
                    }
                    updatedProjects.add(tempProj);
				}
    		}
    	}
    } 
     
    /*
     * The following methods are executed for each record in the trigger context,
     * e.g. Trigger.New and should be used to process information on each individual record.
     * There should not be any SOQL or complex operations in these methods, as those
     * should be in the bulk methods above, and access through cached Lists / Maps
    */
    public void beforeUpdate(SObject oldso, SObject newso)  {}
    public void beforeInsert(SObject newso)                 {}
    public void beforeDelete(SObject so)                    {}       
    public void afterUpdate (SObject oldso, SObject newso)  {}  
    public void afterInsert (SObject newso)                 {}
    public void afterDelete (SObject so)                    {}
     
    /*
     * This method is executed once per trigger event, after the processing of all the
     * individual lifecycle methods
    */
    public void andFinally() {

    	try{
    		if(!updatedProjects.isEmpty()){
    			update updatedProjects;
    		}
    	}catch(Exception e){
    		System.debug(' Unable to update projects because of: ' + e);
    	}
    }
  
}