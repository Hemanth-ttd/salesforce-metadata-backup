trigger HT_RelatedAgreementTrigger on Related_Agreement__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(trigger.isBefore && trigger.isInsert){
        HT_RelatedAgreementTriggerHandler.executeBeforeInertTrigger(trigger.new);
    }
    if(trigger.isAfter && trigger.isInsert){
        HT_RelatedAgreementTriggerHandler.executeAfterInertTrigger(trigger.new);
    }    
    if(trigger.isBefore && trigger.isUpdate){  
        HT_RelatedAgreementTriggerHandler.executeBeforeUpdateTrigger(trigger.new, trigger.oldMap);      
    }
    
}