trigger HT_UnitEconomicsTrigger on Unit_Economics__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
   
    
  if(trigger.isBefore && trigger.isInsert){
        HT_UnitEconomicsTriggerHandler.executeBeforeInertTrigger(trigger.new);
    }   
    /*   if(trigger.isAfter && trigger.isInsert){
        HT_UnitEconomicsTriggerHandler.executeAfterInertTrigger(trigger.new);
    } */
   if(trigger.isBefore && trigger.isUpdate){  
        HT_UnitEconomicsTriggerHandler.executeBeforeUpdateTrigger(trigger.new, trigger.oldMap);      
    }
    /*if(trigger.isAfter && trigger.isUpdate){  
        HT_UnitEconomicsTriggerHandler.executeAfterUpdateTrigger(trigger.new, trigger.oldMap);      
    }*/
     //added for history tracking
     strk.StTriggerFactory.executeTrigger(HT_SitetrackerTriggerHandler.class, true);
    
}