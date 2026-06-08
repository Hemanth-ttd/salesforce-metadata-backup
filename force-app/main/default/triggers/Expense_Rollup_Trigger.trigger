trigger Expense_Rollup_Trigger on strk__Vendor_Payment__c (after insert, after update) {
	
	/* Customer PO (Parent) */
	strk.StLookupRollupEngine.Context poCtx = new strk.StLookupRollupEngine.Context(
	        strk__Finance__c.SobjectType, // parent object
	        strk__Vendor_Payment__c.SobjectType,  // child object
	        Schema.SObjectType.strk__Vendor_Payment__c.fields.strk__Finance__c );// relationship field name
	 
	poCtx.add(
	     new strk.StLookupRollupEngine.RollupSummaryField( Schema.SObjectType.strk__Finance__c.fields.Actual_Spend_Total__c, // Parent field
	                                                       Schema.SObjectType.strk__Vendor_Payment__c.fields.Actual_Spend__c, // Child field
	                                                       strk.StLookupRollupEngine.RollupOperation.Sum)); 
	                                                           
	Sobject[] fRecords = strk.StLookupRollupEngine.rollUp(poCtx, Trigger.new);
	 
	Database.update(fRecords, false);

	strk.StLookupRollupEngine.Context newCtx = new strk.StLookupRollupEngine.Context(
	        strk__Finance__c.SobjectType, // parent object
	        strk__Vendor_Payment__c.SobjectType,  // child object
	        Schema.SObjectType.strk__Vendor_Payment__c.fields.strk__Finance__c );// relationship field name
	 
	newCtx.add(
	     new strk.StLookupRollupEngine.RollupSummaryField( Schema.SObjectType.strk__Finance__c.fields.Open_Spend_Total__c, // Parent field
	                                                       Schema.SObjectType.strk__Vendor_Payment__c.fields.Open_Spend__c, // Child field
	                                                       strk.StLookupRollupEngine.RollupOperation.Sum)); 
	                                                           
	Sobject[] foRecords = strk.StLookupRollupEngine.rollUp(newCtx, Trigger.new);
	 
	Database.update(foRecords, false);
	
}