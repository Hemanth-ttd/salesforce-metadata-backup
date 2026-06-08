global class HT_IsCommencedUpdateBatch  implements Schedulable,Database.Batchable<SObject>{
    string stringQuery;
    global HT_IsCommencedUpdateBatch(String query){
        stringQuery = query;
    }
    
    global void execute(SchedulableContext ctx){        
        Database.executeBatch(new HT_IsCommencedUpdateBatch(stringQuery));        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
       /* string stringQuery = 'SELECT Id,Is_Commenced__c FROM Related_Agreement__c WHERE Status__c = \'Fully Executed\''+
            ' AND Rent_Commencement_Date__c = TODAY AND Is_Commenced__c = FALSE';*/
        return Database.getQueryLocator(stringQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        for(SObject singleRecord : scope){
            singleRecord.put('Is_Commenced__c',TRUE);            
        }   
        update scope;
    }
    global void finish(Database.BatchableContext BC) {

    }

}