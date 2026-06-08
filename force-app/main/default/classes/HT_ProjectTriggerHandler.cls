global without sharing class HT_ProjectTriggerHandler extends UnitiProjectTriggerHandler{
    public static List<Messaging.SingleEmailMessage> notificationsList = new List<Messaging.SingleEmailMessage>();
    public static List<Id> emailProcessedProjectIdList = new List<Id>();
    public static Map<Id, Project_Extension__c> updateExtenionMap = new Map<Id, Project_Extension__c>();
    relatedSObject relatedSites = new RelatedSobject(
        Trigger.new != null ? Trigger.new : Trigger.old,
        'strk__project__c',
        Schema.strk__project__c.strk__site__c
    );
    public static Oracle_PPM_Integration_Settings__mdt integrationSettings = Oracle_PPM_Integration_Settings__mdt.getInstance('Netsuite_Integration_Status');
    Public static Map<String,Task_Creation_Configurator__mdt> taskCreationConfigs{
       get{
            if(taskCreationConfigs == null){
                taskCreationConfigs = new Map<String,Task_Creation_Configurator__mdt>();
                for(Task_Creation_Configurator__mdt objectName : Task_Creation_Configurator__mdt.getAll().values()){
                    taskCreationConfigs.put(objectName.Object_Api_Name__c+'-'+objectName.Field_Api_Name__c,objectName);
                }
                
            }
            return taskCreationConfigs;
        }
        private set;
    }
    public static List<Id> taskCreationProcessedIdList = new List<Id>();
    public static List<Task> insertingTaskList = new List<Task>();
    public static boolean isAgreementCreationRun = false;
    
    public override void initializeCustomerExtended(String objectName) {
        system.debug(relatedSites);
    }
    public override void bulkBeforeCustomerExtended() {}
    public override void bulkAfterCustomerExtended() {
        if(integrationSettings.Value__c=='ON' &&  !Test.isRunningTest()){
            HT_BoomiNetSuiteIntegration.syncProjects(Trigger.New, (Map<Id,strk__Project__c>)Trigger.oldMap);
        }
    }
   public override void beforeInsertCustomerExtended( SObject newSo ) { 
        
        strk__Project__c newProj = (strk__Project__c) newSO;
        if(newProj.strk__Project_Template__c == Label.US_Collocation_Template_Name){
            newProj.Colocation_Request_F__c = System.today();
            newProj.Collocation_Request__c = System.today();
        }
                  if(newProj.Category__c == 'Development'){
         newProj.Payment_Issued_to_Landlord_F__c =   newProj.Construction_start_F__c;           
        }

    }
    
    public override void afterInsertCustomerExtended( SObject newSo ) { 
        strk__Project__c newProject = (strk__Project__c) newso;        
        if(!emailProcessedProjectIdList.contains(newProject.Id) && 
           (newProject.Category__c=='Collocation' || (newProject.strk__Project_Status__c =='Cancelled' && newProject.Reason_Code__c =='Opportunity Rejected'))){
            sendEmail(newProject);
            emailProcessedProjectIdList.add(newProject.Id);
           }
        if(!isAgreementCreationRun){
            ProcessAllAgreementCreation(newProject.Id);
            isAgreementCreationRun = true;
        }
    }
    public override void beforeUpdateCustomerExtended( SObject oldSo, SObject newSo ) { 
        strk__Project__c oldProject = (strk__Project__c) oldso;
        strk__Project__c newProject = (strk__Project__c) newso;        
        setProjectStatus(oldProject, newProject);
        if(oldProject.Monthly_Income__c != newProject.Monthly_Income__c && newProject.Monthly_Income__c == 0 && 
           newProject.strk__Project_Template__c =='US Collocation'){
               if(!updateExtenionMap.containsKey(newProject.Project_Extension__c)) {
                   updateExtenionMap.put( newProject.Project_Extension__c, new Project_Extension__c(Id = newProject.Project_Extension__c, Administrative_Review_A__c = date.parse('01/01/1900')));
               }
               newProject.Rent_commencement_A__c =  date.parse('01/01/1900');
        }
          if(newProject.Category__c == 'Development'){
         newProject.Payment_Issued_to_Landlord_F__c =   newProject.Construction_start_F__c;           
        }
               
 
        
        
    }
    public override void afterUpdateCustomerExtended( SObject oldSo, SObject newSo ) {  
        strk__Project__c oldProject = (strk__Project__c) oldso;
        strk__Project__c newProject = (strk__Project__c) newso; 
               
        
        if(!taskCreationProcessedIdList.contains(newso.Id)){
            List<Task> taskList = createTask(newso, oldso, newso.Id);
            if(!taskList.isEmpty()){
                insertingTaskList.addAll(taskList);
                taskCreationProcessedIdList.add(newso.Id);
            }
        }
        syncNTPCustomerReady(oldProject, newProject);
    }
    public override void beforeDeleteCustomerExtended( SObject oldSo ) {
        if(!FeatureManagement.checkPermission('Project_Delete_Access')){
            oldSo.addError('Project Can not be deleted. Please contact system admin');
        }
    }
    public override void afterDeleteCustomerExtended( SObject oldSo ) {}
    public override void andFinallyCustomerExtended() {        
        relatedSites.saveChangesToDB();   
        if(!insertingTaskList.isEmpty()){
            insert insertingTaskList;
            insertingTaskList.clear();
        }
         system.debug(notificationsList);
        if(!notificationsList.isEmpty() && userinfo.getProfileId() != '00e1I000001G58sQAC'){
            Messaging.sendEmail(notificationsList);
            notificationsList.clear();
        }
         if(!updateExtenionMap.isEmpty()){
            update updateExtenionMap.values();
            updateExtenionMap.clear();
        }
        
    }
    public void syncNTPCustomerReady(strk__Project__c oldProject, strk__Project__c newProject) {
        if (newProject.strk__Project_Template__c != null &&  newProject.strk__Project_Template__c.contains('Site Development')) {
            if (oldProject.NTP_to_Customer_A__c != newProject.NTP_to_customer_A__C) {
                relatedSites.updateObjects(
                    newProject,
                    Schema.strk__Project__c.NTP_to_Customer_A__c,
                    Schema.strk__Site__c.Customer_Ready__c
                );
            }
        }
    }
    
      public static void setProjectStatus(strk__Project__c oldProject, strk__Project__c newProject) {
        if (newProject.strk__Project_Template__c != null && newProject.strk__Project_Template__c.contains('US Operations') ) {
            if (oldProject.Construction_complete_A__c == null &&  oldProject.Construction_complete_A__c != newProject.Construction_complete_A__c) {
                newProject.strk__Project_Status__c = 'In Service';
            }else if (oldProject.strk__Project_Start_Date_A__c == null && oldProject.strk__Project_Start_Date_A__c != newProject.strk__Project_Start_Date_A__c) {
                newProject.strk__Project_Status__c = 'Construction';
            }
        }
    }
     public static List<Task> createTask(sObject currentRecord,sObject oldRecord, Id parentId){       
         
         List<Task> taskList = new List<Task>();
         Id recordId =currentRecord.Id;
         String objectAPIName = recordId.getSObjectType().getDescribe().getName();
         for(String singleKey : taskCreationConfigs.keySet()){
             String objectName = singleKey.split('-')[0];
             String fldName = singleKey.split('-')[1];
             if(objectName == objectAPIName){
                 Object fieldValue = currentRecord.get(fldName);
                 if( fieldValue!=null && ((oldRecord != null && oldRecord.get(fldName) != fieldValue) || oldRecord == null)){
                     Task tsk = new Task();
                     tsk.WhatId = parentId;
                     tsk.OwnerId = taskCreationConfigs.get(singleKey).Queue_Id__c!=null? taskCreationConfigs.get(singleKey).Queue_Id__c:null;
                     tsk.Description = taskCreationConfigs.get(singleKey).Comments__c!=null? taskCreationConfigs.get(singleKey).Comments__c:null;
                     tsk.Subject = taskCreationConfigs.get(singleKey).Subject__c!=null ? taskCreationConfigs.get(singleKey).Subject__c : '' ;
                     taskList.add(tsk);
                 }
             }
         }
         return taskList;
    }
    public void sendEmail(strk__Project__c prj){
        try{
        strk__Site__c  siteRec = [Select Id,Site_ID__c,Name,BD_Lead__r.Email,strk__Site_Type__c from strk__Site__c where Id=:prj.strk__Site__c];
        String notifierList = System.Label.New_Colo_Project_Notify_List;
        List<String> projectNotifierList = new List<String>();            
                string subject='The Project has been created';
        if(String.isNotBlank(notifierList)){
            projectNotifierList = notifierList.split(',');
        }
            List<String> toaddresses = new List<String>();
            if(String.isNotBlank(siteRec.BD_Lead__r.Email)){
                toaddresses.add(siteRec.BD_Lead__r.Email); 
            }
            if(prj.Reason_Code__c == 'Opportunity Rejected' && prj.strk__Project_Manager__c != null){
                User projectManager = [SELECT Id,Email FROM User WHERE Id =:prj.strk__Project_Manager__c];
                toaddresses.add(projectManager.Email);
                subject = 'The Project has been canceled';
            }
            if(!toaddresses.isEmpty()){
                String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm() + '/'; 
                Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();             
                mymail.setToAddresses(toaddresses);
                if(!projectNotifierList.isEmpty()){
                    mymail.setCcAddresses(projectNotifierList);
                }
            mymail.setSubject(subject);
            mymail.setPlainTextBody(subject);
            String body = '<p>'+subject+'</p><br/><br/>Please find the details below<br/><br/>';
            body+='Site ID: '+siteRec.Site_ID__c+'<br/>Site Name: '+siteRec.Name+'<br/>Project ID: '+prj.Name+'<br/>Customer: '+prj.strk__Customer__c+'<br/>Category: '+prj.Category__c+'<br/>Budget Cost: '+prj.Budget_Cost__c+'<br/>Site Type: '+siteRec.strk__Site_Type__c;   
            body+='<br/><br/>For more details, click the following link<br/><br/>';
            body+=sfdcURL+prj.Id;
            mymail.setHtmlBody(body);
                notificationsList.add(mymail);
            }
        }catch(Exception ex){}
    } 
    @future
    public static void ProcessAllAgreementCreation(Id newProjectId){
        try{
        Project_Acceptance__c projAcceptance = [SELECT Id FROM Project_Acceptance__c WHERE Project__c =:newProjectId];
        insert HT_ProjectTriggerHandler.createAllAgreements(new Map<String,Id>{'Project__c' => newProjectId, 'Project_Acceptance__c' => projAcceptance.Id});
        
        } catch (Exception ex) {
		Harmoni_Utility.insertErrorReport(
			UserInfo.getUserId(),
			ex.getMessage(),
			ex.getStackTraceString(),
			'HT_ProjectTriggerHandler- All Agreement Creation',
			'Critical',
			true
		);
	}
    }
     public static All_Agreement__c createAllAgreements(Map<String, Id> fieldValueMap) { 
        All_Agreement__c newRecord =  new All_Agreement__c();         
         for(String fieldName : fieldValueMap.keyset()){
             newRecord.put(fieldName, fieldValueMap.get(fieldName));             
         }
        
       return newRecord;
    }
    
}