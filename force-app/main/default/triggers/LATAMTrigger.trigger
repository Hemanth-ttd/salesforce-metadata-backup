trigger LATAMTrigger on LATAM__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    strk.StTriggerFactory.createAndExecuteHandler(UnitiLATAMTriggerHandler.class,'LATAM__c'); 
}