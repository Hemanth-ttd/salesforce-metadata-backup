global class HT_NetSuiteProjectsSyncBatch implements Database.Batchable<SObject>, Database.Stateful,Schedulable,Database.AllowsCallouts  {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Netsuite_Status__c
            FROM strk__project__c
            WHERE Oracle_ID__c != null AND (Netsuite_Status__c='Sent' OR Netsuite_Status__c=null OR Netsuite_Status__c='Error')
        ]);
    }
    global void execute(Database.BatchableContext BC, List<strk__project__c> scope) {
        for (strk__project__c proj : scope) {
            try {
                HT_BoomiNetSuiteIntegration.sendToBoomi(proj.Id);
            } catch (Exception ex) {
                System.debug('Error processing project: ' + proj.Id + ', Error: ' + ex.getMessage());
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new HT_NetSuiteProjectsSyncBatch(), 1);
    }
}