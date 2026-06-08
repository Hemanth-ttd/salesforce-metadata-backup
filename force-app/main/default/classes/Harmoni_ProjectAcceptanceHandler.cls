/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2023 SITETRACKER, INC., All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of Sitetracker.
 * The intellectual and technical concepts contained herein are proprietary to Sitetracker and
 * may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Sitetracker. Access to the source code contained
 * herein is hereby forbidden to anyone except current Sitetracker employees, managers or
 * contractors who have executed Confidentiality and Non-disclosure agreements explicitly
 * covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure
 * of this source code, which includes information that is confidential and/or proprietary, and
 * is a trade secret, of Sitetracker.
 *
 * @description Harmoni_ProjectAcceptanceHandler
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
global without sharing virtual class Harmoni_ProjectAcceptanceHandler implements strk.StITrigger {
    Map<Id, Project_Acceptance__c> projAccRecsWithApprovalProcessTemplateChange = new Map<Id, Project_Acceptance__c>();
    Static boolean approvalAssigned = false;

    global void initialize(String obj) {
        // call the customer handler
        initializeCustomerExtended(obj);

        // ... Sitetracker logic down here
        if( Trigger.isAfter && !Trigger.isDelete ) {
            Harmoni_STApprovalUtility.initReviewerMatrices();
        }
    }

    global void bulkBefore() {
        // call the customer handler
        bulkBeforeCustomerExtended();

        // ... Sitetracker logic down here
    }

    global void bulkAfter() {
        // call the customer handler
        bulkAfterCustomerExtended();
        projAccRecsWithApprovalProcessTemplateChange = new Map<Id, Project_Acceptance__c>();

        // ... Sitetracker logic down here
    }

    global void beforeInsert(SObject newObject) {
        // call the customer handler
        beforeInsertCustomerExtended(newObject);

        // ... Sitetracker logic down here
        Harmoni_STApprovalUtility.handleSetupApprovalProcessTemplateFieldOnSObject(newObject);
    }

    global void afterInsert(SObject newObject) {
        // call the customer handler
        afterInsertCustomerExtended(newObject);

        // ... Sitetracker logic down here
        Harmoni_STApprovalUtility.handleInitialApprovalAssignmentAfterInsert(
            newObject,
            Uniti_Constants.PROJECT_ACCEPTANCE_OBJECT_TYPE,
            projAccRecsWithApprovalProcessTemplateChange
        );
    }

    global void beforeUpdate(SObject oldObject, SObject newObject) {
        // call the customer handler
        beforeUpdateCustomerExtended(oldObject, newObject);

        // ... Sitetracker logic down here
        Harmoni_STApprovalUtility.handleSetupApprovalProcessTemplateFieldChangeOnSObject(newObject);
    }

    global void afterUpdate(SObject oldObject, SObject newObject) {
        // call the customer handler
        afterUpdateCustomerExtended(oldObject, newObject);

        // ... Sitetracker logic down here
        if (Harmoni_STApprovalUtility.checkOnUpdateApprovalFieldChange(oldObject, newObject)) {
            Harmoni_STApprovalUtility.handleInitialApprovalAssignmentAfterUpdate(
                oldObject,
                newObject,
                Uniti_Constants.PROJECT_ACCEPTANCE_OBJECT_TYPE,
                projAccRecsWithApprovalProcessTemplateChange
            );
        }
    }

    global void beforeDelete(SObject so) {
        // call the customer handler
        beforeDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    global void afterDelete(SObject so) {
        // call the customer handler
        afterDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    global void andFinally() {
        // call the customer handler
        andFinallyCustomerExtended();

        // ... Sitetracker logic down here
        if(!approvalAssigned && Trigger.isAfter && !projAccRecsWithApprovalProcessTemplateChange.isEmpty()){
            Harmoni_STApprovalUtility.handleFinalApprovalProcessSetupOnAfter(
                Uniti_Constants.PROJECT_ACCEPTANCE_OBJECT_TYPE,
                projAccRecsWithApprovalProcessTemplateChange
            );
            approvalAssigned = true;
            projAccRecsWithApprovalProcessTemplateChange.clear();
        }
    }

    /**
     *  Extendable methods for customer logic
    */
    public virtual void initializeCustomerExtended(String objectName) {}
    public virtual void bulkBeforeCustomerExtended() {}
    public virtual void bulkAfterCustomerExtended() {}
    public virtual void beforeInsertCustomerExtended( SObject newSo ) {}
    public virtual void afterInsertCustomerExtended( SObject newSo ) {}
    public virtual void beforeUpdateCustomerExtended( SObject oldSo, SObject newSo ) {}
    public virtual void afterUpdateCustomerExtended( SObject oldSo, SObject newSo ) {}
    public virtual void beforeDeleteCustomerExtended( SObject oldSo ) {}
    public virtual void afterDeleteCustomerExtended( SObject oldSo ) {}
    public virtual void andFinallyCustomerExtended() {}

}