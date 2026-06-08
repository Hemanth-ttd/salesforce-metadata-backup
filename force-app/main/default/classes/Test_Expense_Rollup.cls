@isTest
private class Test_Expense_Rollup {
	@isTest static void Test_Expense_Rollup() {
		test.startTest();
			strk__Vendor_Payment__c vp = new strk__Vendor_Payment__c();

			insert(vp);

		test.stopTest();
		
	}
}