global without sharing class HT_SiteTriggerHandler extends UnitiSiteTriggerHandler{
    
    
    public override void initializeCustomerExtended(String objectName) {}    
    public override void bulkBeforeCustomerExtended() {}
    public override void bulkAfterCustomerExtended() {}
    public override void beforeInsertCustomerExtended( SObject newSo ) {}    
    public override void afterInsertCustomerExtended( SObject newSo ) {}
    public override void beforeUpdateCustomerExtended( SObject oldSo, SObject newSo ) {
    }
    public override void afterUpdateCustomerExtended( SObject oldSite, SObject newSite ) {}
    public override void beforeDeleteCustomerExtended( SObject oldSo ) {
        if(!FeatureManagement.checkPermission('Site_Delete_Access')){
            oldSo.addError('Project Can not be deleted. Please contact system admin');
        }}
    public override void afterDeleteCustomerExtended( SObject oldSo ) {}
    public override void andFinallyCustomerExtended() {           
        
    }
}