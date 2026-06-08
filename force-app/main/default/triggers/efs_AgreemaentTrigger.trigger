trigger efs_AgreemaentTrigger on Agreement__c (after update, after insert)
{
    if(trigger.isAfter && trigger.isInsert)
        efs.EgnyteSyncQueueTrigger.onAfterInsert();
    else if(trigger.isAfter && trigger.isUpdate)
        efs.EgnyteSyncQueueTrigger.onAfterUpdate();
}