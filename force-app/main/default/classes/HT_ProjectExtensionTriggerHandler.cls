global  without sharing class HT_ProjectExtensionTriggerHandler extends strk.StSubProjectExtendableTriggerHandler{

    public static List<Id> taskCreationProcessedIdList = new List<Id>();
    public static List<Task> insertingTaskList = new List<Task>(); 
    public strk.StNotificationEngine notificationEngine {get; set;}   
    public static final String objectName = 'Project_Extension__c';  
    global override void initializeExtended(String pSObjectName){
    }
    global override void bulkBeforeExtended(){
        if ( !Trigger.isDelete && notificationEngine == null) {           
            notificationEngine = new strk.StNotificationEngine();           
            notificationEngine.call('initialize', new Map<String, Object>{'objectType' => objectName, 'newRecords' => Trigger.new});       
        }   
    }
    global override void bulkAfterExtended(){
        if (!Trigger.isDelete && notificationEngine == null) {           
            notificationEngine = new strk.StNotificationEngine();           
            notificationEngine.call('initialize',    new Map<String, Object>{'objectType' => objectName, 'newRecords' =>  Trigger.new});       
        } 
    }
    global override void beforeInsertExtended(SObject pNewObj){
    }
    global override void afterInsertExtended(SObject pNewObj){
    }
    global override void beforeUpdateExtended(SObject pOldObj, SObject pNewObj){
       // if (!Test.isRunningTest()) {           
            notificationEngine.call('evaluateLogicBefore',  new Map<String, Object>{'objectType' => objectName, 'newRecord' => pNewObj, 'oldRecord' => pOldObj});       
      //  }  
    }
    global override void afterUpdateExtended(SObject pOldObj, SObject pNewObj){
        
       // if (!Test.isRunningTest()) {           
            notificationEngine.call('evaluateLogic', new Map<String, Object>{'objectType' => objectName, 'newRecord' => pNewObj, 'oldRecord' => pOldObj});       
      //  }             
        if(!taskCreationProcessedIdList.contains(pNewObj.Id)){
            List<Task> taskList =  HT_ProjectTriggerHandler.createTask( pNewObj, pOldObj, (Id) pNewObj.get('Project__c'));
            if(!taskList.isEmpty()){
                insertingTaskList.addAll(taskList);
                taskCreationProcessedIdList.add(pNewObj.Id);
            }
        }
    }
    global override void beforeDeleteExtended(SObject pNewObj){
    }
    global override void afterDeleteExtended(SObject pNewObj){
    }
    global override void andFinallyExtended(){
        if (Trigger.isAfter && !Trigger.isDelete) {           
            notificationEngine.call('andFinally', new Map<String, Object>());       
        } 
          if(!insertingTaskList.isEmpty()){
            insert insertingTaskList;
            insertingTaskList.clear();
        }
    }

}