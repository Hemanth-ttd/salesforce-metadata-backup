public with sharing class MyActionItemsController {
    
    public List<strk__Action_Item__c> actionItems {get; set;}
    
    public MyActionItemsController() {
        actionItems = [SELECT Id, Name, strk__Site_Name__c, strk__Project__c, strk__Project_ID__c, strk__Project_ID__r.Name,
        				strk__Project_ID__r.strk__Site__c, strk__Priority_Level__c, strk__Description__c, CreatedDate, 
        				strk__Due_Date__c, strk__Due_Status__c, strk__Days_Remaining__c, CreatedById, strk__Assigned_To__c 
        				FROM strk__Action_Item__c WHERE (strk__Completion_Date__c = null AND strk__Status__c != 'Cancelled') AND
                        (strk__Assigned_To__c =:UserInfo.getUserId())
                        ORDER BY strk__Due_Date__c];
    }
    
}