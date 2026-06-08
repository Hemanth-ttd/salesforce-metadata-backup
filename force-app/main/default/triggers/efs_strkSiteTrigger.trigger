trigger efs_strkSiteTrigger on strk__Site__c (after update, after insert) 
{
    if(trigger.isAfter && trigger.isInsert)
        efs__.EgnyteSyncQueueTrigger.onAfterInsert();
    else if(trigger.isAfter && trigger.isUpdate)
        efs__.EgnyteSyncQueueTrigger.onAfterUpdate();
}