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
 * @description Utility class for the Approval Process and Reviewer Matrix
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
global class Harmoni_STApprovalUtility {
    /**
    * @description Configurations where Approval process is enabled
    **/
    public static List<strk__SiteTraker_Object__mdt> triggerConfigurations {
        get {
            if( triggerConfigurations == null ){
                triggerConfigurations = [
                    SELECT Id, DeveloperName, Label, strk__Object_2__r.QualifiedApiName,
                        strk__Approval_Process_Field_API__c, strk__Approval_Process_Template_Field_API__c,
                        strk__Enable_Approval_Process__c
                    FROM strk__SiteTraker_Object__mdt
                    WHERE strk__Enable_Approval_Process__c = true
                    ORDER BY Label ASC
                ];
            }
            return triggerConfigurations;
        }
        private set;
    }

    /**
    * @description Approval process fields mapped by object name from the object configurations
    */
    public static Map<String, String> approvalProcessFieldByObjectMap {
        get {
            if (approvalProcessFieldByObjectMap == null) {
                approvalProcessFieldByObjectMap = new Map<String, String>();

                for( strk__SiteTraker_Object__mdt config : triggerConfigurations ){
                    String objectName = config.strk__Object_2__r.QualifiedApiName != null
                        ? config.strk__Object_2__r.QualifiedApiName
                        : config.Label;

                    approvalProcessFieldByObjectMap.put(
                        objectName,
                        config.strk__Approval_Process_Field_API__c
                    );
                }
            }
            return approvalProcessFieldByObjectMap;
        }
        private set;
    }

    /**
    * @description Approval Process template fields mapped by object name from the object configurations
    */
    public static Map<String, String> approvalProcessTemplateFieldByObjectMap {
        get {
            if (approvalProcessTemplateFieldByObjectMap == null) {
                approvalProcessTemplateFieldByObjectMap = new Map<String, String>();

                for( strk__SiteTraker_Object__mdt config : triggerConfigurations ){
                    String objectName = config.strk__Object_2__r.QualifiedApiName != null
                        ? config.strk__Object_2__r.QualifiedApiName
                        : config.Label;

                    approvalProcessTemplateFieldByObjectMap.put(
                        objectName,
                        config.strk__Approval_Process_Template_Field_API__c
                    );
                }
            }

            return approvalProcessTemplateFieldByObjectMap;
        }
        private set;
    }

    /**
    * @description This is not initialized by default with purpose to not add a query for other non-related process here.
    * global utility with static get; set; variables will always run upon construction of classes
    * an initialize method is used below and can be called from the appropriate trigger handler initialize(string) methods
    */
    public static Map<String, List<Reviewer_Matrix__c>> matricesByObject {
        get {
            return matricesByObject;
        }
        private set;
    }

    /**
	* @description Used to initialize any variables here needed for the approval process assignment
	*/
    public static void initServices() {
        if (Harmoni_STApprovalUtility.matricesByObject == null) {
            Harmoni_STApprovalUtility.initReviewerMatrices();
        }
    }

    /**
    * @description Initializes the reviewer matrices so the query usage is only executed on demand.
    * NOTE: Add this method to the appropriate trigger handler initialize method
    */
    public static void initReviewerMatrices() {
        matricesByObject = new Map<String, List<Reviewer_Matrix__c>>();

        List<Reviewer_Matrix__c> matrices = [
            SELECT Id, Name, Approval_Process_Template__c, Object_API__c, Assignment_Criteria__c
            FROM Reviewer_Matrix__c
        ];

        if(Test.isRunningTest()){
            // a test utility is used here to get mock data for use during testing
            matrices = Harmoni_STApprovalUtility.generateReviewerMatricesForTest();
        }

        if (!matrices.isEmpty()) {
            for (Reviewer_Matrix__c matrix : matrices) {
                List<Reviewer_Matrix__c> current = matricesByObject.containsKey(matrix.Object_API__c)
                    ? matricesByObject.get(matrix.Object_API__c) : new List<Reviewer_Matrix__c>();
                current.add(matrix);
                matricesByObject.put(matrix.Object_API__c, current);
            }
        }
    }

    /**
     * @description Gets the approval template Id from the Reviewer matrix matching the criteria for the provided record
     * @param SObject pRecord: Context record
     * @return Id: Approval Process Template Id or Null
    */
    public static Id getApprovalTemplateFromAssignedMatrix(SObject pRecord) {
        Id result;
        String sObjectType = pRecord != null ? String.valueOf(pRecord.getSObjectType()) : null;
        Harmoni_STApprovalUtility.initServices();

        if (sObjectType != null) {
            List<Reviewer_Matrix__c> matrices = getMatricesForSObjectType(sObjectType);
            for (Reviewer_Matrix__c matrix : matrices) {
                Boolean doAssign = Harmoni_STApprovalUtility.tryEvaluateCriteria(pRecord, matrix.Assignment_Criteria__c);
                if (doAssign) {
                    result = matrix.Approval_Process_Template__c;
                    break;
                }
            }
        }

        return result;
    }

    /**
     * @description Evaluated review matrix criteria
     * @param SObject pRecord: Context record
     * @param String pCriteria: Condition passed as string
     * @return Boolean: true or false depending if condition is met
    */
    public static Boolean tryEvaluateCriteria(SObject pRecord, String pCriteria){
        Boolean result = false;
        try{
            result = strk.StBooleanLogicEvaluation.evaluate( pRecord, pCriteria );
        }
        catch( Exception ex ){
            result = false;
        }

        return result;
    }

    /**
     * @description Gets the list of Reviewer Matrices for the provided SObject Type
     * @param String pObjAPIName: The sObject Api Name
     * @return List<Reviewer_Matrix__c>: List of matrices or Empty list
    */
    public static List<Reviewer_Matrix__c> getMatricesForSObjectType(String pObjAPIName) {
        Harmoni_STApprovalUtility.initServices();

        return pObjAPIName != null && Harmoni_STApprovalUtility.matricesByObject.containsKey(pObjAPIName)
            ? Harmoni_STApprovalUtility.matricesByObject.get(pObjAPIName)
            : new List<Reviewer_Matrix__c>();
    }

    /**
     * @description Handles setting the approval process template to the approval process template field
     * when aligned to a reviewer matrix
     * @param SObject pRecord
    */
    public static void handleSetupApprovalProcessTemplateFieldOnSObject(SObject pRecord) {
        String objectApiName = pRecord != null ? String.valueOf(pRecord.getSObjectType()) : null;

        if (objectApiName != null) {
            String approvalTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(objectApiName);
            Id approvalTemplateId = Harmoni_STApprovalUtility.getApprovalTemplateFromAssignedMatrix(pRecord);

            if (approvalTemplateId != null && approvalTemplateField != null) {
                pRecord.put(approvalTemplateField, approvalTemplateId);
            }
        }
    }

    /**
     * @description Handles resetting the approval process template field if the record meets criteria for
     * reassigning of the approval process template
     *
     * @param record the record
     **/
    public static void handleSetupApprovalProcessTemplateFieldChangeOnSObject(SObject record) {
        String objectApiName = record != null ? String.valueOf(record.getSObjectType()) : null;

        if (objectApiName != null) {
            String approvalProcessTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(objectApiName);

            Id currentApprovalTemplateId = (Id) record.get(approvalProcessTemplateField);
            Id expectedApprovalTemplateId = Harmoni_STApprovalUtility.getApprovalTemplateFromAssignedMatrix(record);

            // Assign the new updated template Id if it is not aligned
            if (currentApprovalTemplateId != expectedApprovalTemplateId) {
                record.put(approvalProcessTemplateField, expectedApprovalTemplateId);
            }
        }
    }

    /**
     * @description Handles measuring change of approval process field for updated records
     *
     * @param oldSo the old record
     * @param newSo the new record
     *
     * @return FALSE if unchanged (default) | TRUE
     **/
    public static Boolean checkOnUpdateApprovalFieldChange(SObject oldSo, SObject newSo) {
        String objectApiName = newSo != null ? String.valueOf(newSo.getSObjectType()) : null;
        Boolean result = false;

        if (objectApiName != null) {
            String approvalProcessTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(objectApiName);

            result = oldSo.get(approvalProcessTemplateField) != newSo.get(approvalProcessTemplateField);
        }

        return result;
    }

    /**
     * @description Handles the final approval assignment work on insert
     * @param String pObjAPIName: The object Api Name that is being worked with
     * @param Map<Id, SObject> pMapRecWithApprovalProcTempChange: Records that need new assignment
    */
    public static void handleFinalApprovalProcessSetupOnAfter(
        String pObjAPIName,
        Map<Id, SObject> pMapRecWithApprovalProcTempChange
    ) {

        String approvalProcessField = Harmoni_STApprovalUtility.getApprovalProcessField(pObjAPIName);
        String approvalProcessTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(pObjAPIName);

        if (Trigger.isAfter && pMapRecWithApprovalProcTempChange != null && !pMapRecWithApprovalProcTempChange.isEmpty()) {
            Harmoni_STApprovalUtility.callApprovalService(
                null,
                null,
                approvalProcessTemplateField,
                approvalProcessField,
                pMapRecWithApprovalProcTempChange,
                'createApprovalProcessRecordsForSObjects'
            );
        }
    }

    /**
     * @description Handles the after insert process for the managed package approval setup
     * @param SObject pNewSObj: The new object
     * @param String pObjAPIName: The object api name
     * @param Map<Id, SObject> pMapRecWithApprovalProcTempChange: Records with template changes to pass in
    */
    public static void handleInitialApprovalAssignmentAfterInsert(
        SObject pNewSObj,
        String pObjAPIName,
        Map<Id, SObject> pMapRecWithApprovalProcTempChange
    ) {
        String approvalProcessField = Harmoni_STApprovalUtility.getApprovalProcessField(pObjAPIName);
        String approvalProcessTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(pObjAPIName);

        if (Trigger.isAfter && Trigger.isInsert) {
            Harmoni_STApprovalUtility.callApprovalService(
                null,
                pNewSObj,
                approvalProcessTemplateField,
                approvalProcessField,
                pMapRecWithApprovalProcTempChange,
                'approvalProcessTemplateChange'
            );
        }
    }

    /**
     * @description Handles the after update process for the managed package approval setup
     * @param SObject pOldSObj: The old object
     * @param SObject pNewSObj: The new object
     * @param String pObjAPIName: The object api name
     * @param Map<Id, SObject> pMapRecWithApprovalProcTempChange: Records with template changes to pass in
    */
    public static void handleInitialApprovalAssignmentAfterUpdate(
        SObject pOldSObj,
        SObject pNewSObj,
        String pObjAPIName,
        Map<Id, SObject> pMapRecWithApprovalProcTempChange
    ) {
        String approvalProcessField = Harmoni_STApprovalUtility.getApprovalProcessField(pObjAPIName);
        String approvalProcessTemplateField = Harmoni_STApprovalUtility.getApprovalProcessTemplateField(pObjAPIName);

        if (Trigger.isAfter && Trigger.isUpdate) {
            Harmoni_STApprovalUtility.callApprovalService(
                pOldSObj,
                pNewSObj,
                approvalProcessTemplateField,
                approvalProcessField,
                pMapRecWithApprovalProcTempChange,
                'approvalProcessTemplateChange'
            );
        }
    }

    /**
     * @description Calls the Sitetracker Callable for Approval Process setup
     * @param SObject pOldSObj: Old Record
     * @param SObject pNewSObj: New Record
     * @param String pApprovalProcTempField: Field to leverage for the approval process template
     * @param String pApprovalProcField: Field to leverage for the approval process field
     * @param Map<Id, SObject> pMapRecWithApprovalProcTempChange: Records that need new assignment
     * @param String pAction: The approval process action that is being called
    */
    public static void callApprovalService(
        SObject pOldSObj,
        SObject pNewSObj,
        String pApprovalProcTempField,
        String pApprovalProcField,
        Map<Id, SObject> pMapRecWithApprovalProcTempChange,
        String pAction
    ) {
        strk.StApprovalProcessServices approvalProcessServices = new strk.StApprovalProcessServices();
        Map<String, Object> args = new Map<String, Object>();

        args.put('oldSObject', pOldSObj);
        args.put('newSObject', pNewSObj);
        args.put('approvalProcessTemplateField', pApprovalProcTempField);
        args.put('approvalProcessField', pApprovalProcField);
        args.put('recordsWithApprovalProcessTemplateChange', pMapRecWithApprovalProcTempChange);

        approvalProcessServices.call(pAction, args);
    }

    public static String getApprovalProcessField(String pObjAPIName) {
        return Harmoni_STApprovalUtility.approvalProcessFieldByObjectMap.get(pObjAPIName);
    }

    public static String getApprovalProcessTemplateField(String pObjAPIName) {
        return Harmoni_STApprovalUtility.approvalProcessTemplateFieldByObjectMap.get(pObjAPIName);
    }

    /**
     * @description Generates Reviewer Matrices with basic assignment criteria
     * @return List<Reviewer_Matrix__c>: List of reviewer matrices with some default entry criteria
    */
    public static List<Reviewer_Matrix__c> generateReviewerMatricesForTest() {
        List<Reviewer_Matrix__c> results = new List<Reviewer_Matrix__c>();

        Harmoni_STApprovalUtility.createApprovalProcessItems();

        List<strk__Approval_Process_Template__c> templates = [
            SELECT Id, strk__Approval_Process_Template_Name__c, strk__Description__c, strk__Object_API__c
            FROM strk__Approval_Process_Template__c
        ];

        if (!templates.isEmpty()) {
            for (strk__Approval_Process_Template__c template : templates) {
                String objectName = template.strk__Object_API__c;
                String criteria = '['
                    + Harmoni_STApprovalUtility.approvalProcessFieldByObjectMap.get(objectName)
                    + ' == \'\']';

                Reviewer_Matrix__c matrix = new Reviewer_Matrix__c(
                    Object_API__c = objectName,
                    Approval_Process_Template__c = template.Id,
                    Assignment_Criteria__c = criteria
                );

                results.add(matrix);
            }
        }

        if (!results.isEmpty()) {
            insert results;
        }

        return results;
    }

    /**
    * @description Creates approval process templates that can be used with Reviewer matrices
    */
    public static void createApprovalProcessItems() {
        List<strk__Approval_Process_Template__c> templates = new List<strk__Approval_Process_Template__c>();

        for( String objectName : Harmoni_STApprovalUtility.approvalProcessTemplateFieldByObjectMap.keySet()){
            templates.add(
                new strk__Approval_Process_Template__c(
                    strk__Approval_Process_Template_Name__c = 'Test Template ' + objectName,
                    strk__Description__c = 'Approval Template for ' + objectName,
                    strk__Object_API__c = objectName,
                    strk__Active__c = true
                )
            );
        }

        insert templates;
    }
}