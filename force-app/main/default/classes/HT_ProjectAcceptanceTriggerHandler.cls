global without sharing class HT_ProjectAcceptanceTriggerHandler extends Harmoni_ProjectAcceptanceHandler{
    
    public static List<Lease_Up_Potential__c> leaseUpPotentialRecords = new List<Lease_Up_Potential__c>();
    public static Map<Id, strk__Project__c> newProjectMap = new  Map<Id, strk__Project__c>(); 
    public strk.StNotificationEngine notificationEngine {get; set;}   
    public static final String objectName = 'Project_Acceptance__c';   
    Public static Map<String,String> templateIdMap{
        get{
            if(templateIdMap == null){
                templateIdMap = new Map<String, String>();
                for(String singleValue : System.Label.templateIdConfig.split('&&')){
                    List<String> categoryTemplateId = singleValue.split('::');
                    templateIdMap.put(categoryTemplateId[0].toUpperCase(), categoryTemplateId[1]);
                }
              
            }
            return templateIdMap;
        }
        private set;
    }
    public static List<String> pickListValuesList {
        get {
            if( pickListValuesList == null ){
                pickListValuesList = new List<String>();
                Schema.DescribeFieldResult fieldResult = Lease_Up_Potential__c.Carrier__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    pickListValuesList.add(pickListVal.getLabel());
                } 
            }
            return pickListValuesList;
        }
        private set;
    }
    
    public override void initializeCustomerExtended(String objectName) {
    }
    
    public override void bulkBeforeCustomerExtended() {	
        if ( !Trigger.isDelete && notificationEngine == null) {           
            notificationEngine = new strk.StNotificationEngine();           
            notificationEngine.call('initialize', new Map<String, Object>{'objectType' => objectName, 'newRecords' => Trigger.new});       
        } 
		}
    public override void bulkAfterCustomerExtended() {
	
        if (!Trigger.isDelete && notificationEngine == null) {           
            notificationEngine = new strk.StNotificationEngine();           
            notificationEngine.call('initialize',    new Map<String, Object>{'objectType' => objectName, 'newRecords' =>  Trigger.new});       
        } 
		}
    public override void beforeInsertCustomerExtended( SObject newSo ) {
        
    }
    
    public override void afterInsertCustomerExtended( SObject newSo ) {   
         notificationEngine.call('evaluateLogic', new Map<String, Object>{'objectType' => objectName, 'newRecord' => newSo});       
   
        Project_Acceptance__c prjAcc = (Project_Acceptance__c)newSo;
        System.debug('status - afterInsertCustomerExtended' + prjAcc.Approval_Status__c);
        if(prjAcc.Approval_Status__c=='Approved' || prjAcc.Approval_Status__c=='Auto Approved' || prjAcc.Approval_Status__c=='Rejected'){
            createProject(newSo);
        }
        createLeaseUpPotentialRecords(newSo.Id);
        
    }
    public override void beforeUpdateCustomerExtended( SObject oldSo, SObject newSo ) {   
        Project_Acceptance__c newPrjAcc = (Project_Acceptance__c)newSo;
        Project_Acceptance__c oldPrjAcc = (Project_Acceptance__c)oldSo;
		 notificationEngine.call('evaluateLogicBefore',  new Map<String, Object>{'objectType' => objectName, 'newRecord' => newSo, 'oldRecord' => oldSo});       

        if(oldPrjAcc.Category__c != newPrjAcc.Category__c && newPrjAcc.Approval_Status__c != 'Auto Approved'
             && String.isBlank(newPrjAcc.Project__c) && (newPrjAcc.Category__c != 'Development' || (newPrjAcc.Category__c == 'Development' && newPrjAcc.Project_Type__c == 'MKT'))  ){
                newPrjAcc.Approval_Status__c = 'Auto Approved';
            }
        if(oldPrjAcc.Category__c != newPrjAcc.Category__c &&
           templateIdMap.containsKey(newPrjAcc.Category__c.toUpperCase())){
            newPrjAcc.Project_Template__c =  templateIdMap.get(newPrjAcc.Category__c.toUpperCase());
        }
        
    }
    public override void afterUpdateCustomerExtended( SObject oldSo, SObject newSo ) {
        Project_Acceptance__c prjAcc = (Project_Acceptance__c)newSo;
        Project_Acceptance__c oldPrjAcc = (Project_Acceptance__c)oldSo;
	          notificationEngine.call('evaluateLogic', new Map<String, Object>{'objectType' => objectName, 'newRecord' => newSo, 'oldRecord' => oldSo});       
   
		
        if(oldPrjAcc.Approval_Status__c!= prjAcc.Approval_Status__c  && String.isBlank(prjAcc.Project__c) && 
           (prjAcc.Approval_Status__c=='Approved' || prjAcc.Approval_Status__c=='Auto Approved' || 
            prjAcc.Approval_Status__c=='Rejected')){
                createProject(newSo);
            }
    }
    public override void beforeDeleteCustomerExtended( SObject oldSo ) {}
    public override void afterDeleteCustomerExtended( SObject oldSo ) {}
    public override void andFinallyCustomerExtended() {           
          if (Trigger.isAfter && !Trigger.isDelete) {           
            notificationEngine.call('andFinally', new Map<String, Object>());       
        } 
        //Update project value in Project Acceptance record once the project is created
        if(Trigger.isAfter && !newProjectMap.keySet().isEmpty()){
            insert newProjectMap.values();
            List<Project_Acceptance__c> updateprojectAcceptanceList = new List<Project_Acceptance__c>();
            List<Id> projectAcceptaceIdList = new List<Id>();
            for(Id projectAcceptanceId : newProjectMap.keySet()){       
                system.debug(newProjectMap.get(projectAcceptanceId).Id);
                updateprojectAcceptanceList.add(new Project_Acceptance__c(Id=projectAcceptanceId, Project__c =newProjectMap.get(projectAcceptanceId).Id));
                if(newProjectMap.get(projectAcceptanceId).Category__c == 'Development'){
                    projectAcceptaceIdList.add(projectAcceptanceId);
                }
            }
            newProjectMap.clear();
            if(!updateprojectAcceptanceList.isEmpty()){
                update updateprojectAcceptanceList; 
                if(!projectAcceptaceIdList.isEmpty())                
                    HT_CustomTwinFeilds.crateTwinfieldRecord(projectAcceptaceIdList, 'Project_Acceptance__c','Unit_Economics__c');
                updateprojectAcceptanceList.clear();
                projectAcceptaceIdList.clear();
            }
        }
        
        if(Trigger.isAfter && !leaseUpPotentialRecords.isEmpty()){
            insert leaseUpPotentialRecords;
            leaseUpPotentialRecords.clear();
        }
    }
    
    
    
    private void createProject(SObject newObject) { 
        Project_Acceptance__c prjAcc = (Project_Acceptance__c)newObject;
        
        strk__Project__c prj = new strk__Project__c();
        prj.strk__Site__c = prjAcc.Site__c;
        prj.strk__ProjectTemplate__c = prjAcc.Project_Template__c;
        prj.SBO_accept_reject_F__c = prjAcc.SBO_accept_reject_F__c;
        prj.strk__Customer__c = prjAcc.Customer__c;
        prj.Funding__c = prjAcc.Funding__c;
        prj.Category__c = prjAcc.Category__c;
        prj.strk__Project_Type__c = prjAcc.Project_Type__c;
        prj.Agreement__c = prjAcc.Agreement__c;
        prj.strk__Project_Manager__c = prjAcc.Project_Management_Director__c;
        prj.Tenant_Site_ID__c = prjAcc.Tenant_Site_ID__c;
        prj.Tenant_Site_Name__c = prjAcc.Tenant_Site_Name__c;
        prj.Budget_Cost__c = prjAcc.Hard_Capex__c;
        prj.FA__c = prjAcc.FA_Code__c;
        prj.Release__c = prjAcc.Release__c;
        prj.Zoning_Analysis_Determination__c = prjAcc.Zoning_Analysis_Determination__c;
        prj.ABM_Project_Type__c = prjAcc.ABM_Project_Type__c;
        prj.VzW_Relo_Scope__c = prjAcc.VzW_Additional_Scope__c;
        prj.Business_Unit__c =prjAcc.Business_Unit_Formula__c;
        if(prjAcc.Approval_Status__c == 'Rejected'){
            prj.strk__Project_Status__c ='Cancelled';
            prj.strk__Project_Status_Override__c =true;            
            prj.Reason_Code__c ='Opportunity Rejected';
            prj.Cancelled_Date_A__c =System.today();            
        }
        newProjectMap.put(prjAcc.Id, prj);
    }
    
    public void createLeaseUpPotentialRecords(Id acceptanceId){    
        for(String carrierValue:pickListValuesList){
            Lease_Up_Potential__c leasePot = new Lease_Up_Potential__c();
            leasePot.Carrier__c = carrierValue;
            leasePot.Project_Acceptance__c = acceptanceId;
            leaseUpPotentialRecords.add(leasePot);
        }
    }    
}