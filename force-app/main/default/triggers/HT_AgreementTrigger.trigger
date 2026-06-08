trigger HT_AgreementTrigger on Agreement__c  (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
     if(trigger.isBefore && trigger.isInsert){
        HT_AgreementTriggerHandler.executeBeforeInertTrigger(trigger.new);
    }   
     if(trigger.isAfter && trigger.isInsert){
        HT_AgreementTriggerHandler.executeAfterInertTrigger(trigger.new);
    } 
    if(trigger.isBefore && trigger.isUpdate){  
        HT_AgreementTriggerHandler.executeBeforeUpdateTrigger(trigger.new, trigger.oldMap);      
    }
    if(trigger.isAfter && trigger.isUpdate){  
        HT_AgreementTriggerHandler.executeAfterUpdateTrigger(trigger.new, trigger.oldMap);      
    }
    
    HT_AgreementTriggerHandler.calculateRollup(trigger.new, trigger.oldMap);
    
    //added for history tracking
     strk.StTriggerFactory.executeTrigger(HT_SitetrackerTriggerHandler.class, true);
    
}