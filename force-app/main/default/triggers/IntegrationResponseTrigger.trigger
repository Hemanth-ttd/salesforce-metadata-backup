trigger IntegrationResponseTrigger on Integration_Response__c (after delete, after insert, after undelete, after update,
                                                 before delete, before insert, before update) {
	strk.StTriggerFactory.createAndExecuteHandler(IntegrationResponseTriggerHandler.class);
}