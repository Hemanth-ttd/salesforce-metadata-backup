/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2024 SITETRACKER, INC., All Rights Reserved.
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
 * @description UnitiProjectTriggerHandler
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
global without sharing virtual class UnitiProjectTriggerHandler extends strk.StProjectTriggerHandler{
    relatedSObject relatedSites = new RelatedSobject(
        Trigger.new != null ? Trigger.new : Trigger.old,
        'strk__project__c',
        Schema.strk__project__c.strk__site__c
    );

    private strk.StNotificationEngine notificationEngine { get; set; }
    private static final String SOBJECT_API = 'strk__Project__c';

    /* Sets the status filter based upon the value in the project template */
    private void setStatusFilter(strk__Project__c project) {
        if (projectTemplates.containsKey(project.strk__ProjectTemplate__c)) {
            strk__Project_Template__c template = projectTemplates.get(project.strk__ProjectTemplate__c);
            project.Status_Filter__c = template.Status_Filter__c;
        }
    }

    /* Sets the cancelled Date on a Project */
    private void setCancelledDate(strk__Project__c newProj) {
        if (newProj.strk__Project_Status__c == 'Cancelled') {
            newProj.Cancelled_Date__c = Date.today();
        }
    }

    /*
     * Query for all aproject templates -- no need to limit to only those
     * in the trigger context since templates will always be < 100
     */
    private Map<Id, strk__Project_Template__c> projectTemplates {
        get {
            if (projectTemplates == null) {
                projectTemplates = new Map<Id, strk__Project_Template__c>(
                    [SELECT id, status_filter__c FROM strk__Project_Template__c LIMIT 1000]
                );
            }

            return projectTemplates;
        }
        set;
    }

    /**
     * This method is called once in the beginning of each trigger context
     * and should be used for initializing information.  The name of the
     * SObjectType will be passed as a string to the method.
     */
    global override void initialize(String obj) {
        // call the customer handler
        initializeCustomerExtended(obj);

        // ... Sitetracker logic down here
    }

    /**
     * The bulkBefore() and bulkAfter() methods are called once for each trigger
     * event (once for entire Trigger.new), prior to executing the individual methods below.
     * You can access the Trigger context variables here (Trigger.new and Trigger.old) as needed
     * provided they are available, e.g Trigger.old not available in before insert event
     */
    global override void bulkBefore() {
        // call the customer handler
        bulkBeforeCustomerExtended();

        // ... Sitetracker logic down here
        if (!Test.isRunningTest() && !Trigger.isDelete && notificationEngine == null) {
            notificationEngine = new strk.StNotificationEngine();
            notificationEngine.call('initialize',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecords' => Trigger.new});
        }
    }

    global override void bulkAfter() {
        // call the customer handler
        bulkAfterCustomerExtended();

        // ... Sitetracker logic down here
        if (!Test.isRunningTest() && !Trigger.isDelete && notificationEngine == null) {
            notificationEngine = new strk.StNotificationEngine();
            notificationEngine.call('initialize',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecords' => Trigger.new});
        }
    }

    /**
     * The following methods are executed for each record in the trigger context,
     * e.g. Trigger.New and should be used to process information on each individual record.
     * There should not be any SOQL or complex operations in these methods, as those
     * should be in the bulk methods above, and access through cached Lists / Maps
     */
    global override void beforeUpdate(SObject oldSo, SObject newSO) {
        // call the customer handler
        beforeUpdateCustomerExtended(oldSo, newSO);

        // ... Sitetracker logic down here
        strk__Project__c newProject = (strk__Project__c) newSO;
        strk__Project__c oldProject = (strk__Project__c) oldSo;
        try {
            setStatusFilter((strk__Project__c) newSO);
            UpdateCommentField.updateCommentField(oldso, newso, 'strk__Project__c');
        } catch (Exception e) {
            system.debug(LoggingLevel.ERROR, e.getMessage());
            system.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogicBefore',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newSo, 'oldRecord' => oldSo});
        }
    }

    global override void beforeInsert(SObject newSO) {
        // call the customer handler
        beforeInsertCustomerExtended(newSO);

        // ... Sitetracker logic down here
        strk__Project__c newProj = (strk__Project__c) newSO;
        setStatusFilter((strk__Project__c) newSO);
        if (newProj.Funding__c == 'OPX' && newProj.Category__c == 'Development') {
            newSO.addError('ERROR: Funding: \'OPX\' is not allowed on Projects with Category: \'Development\' ');
        }

        if(newProj.strk__Project_Template__c == Label.SITE_DEVELOPMENT_ATT_WITH_HNS_PROJECT_TEMPLATE){
            newProj.strk__Project_Start_Date_A__c = System.today();
            newProj.strk__Project_Start_Date_F__c = System.today();
        }
    }

    global override void beforeDelete(SObject so) {
        // call the customer handler
        beforeDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    global override void afterUpdate(SObject oldso, SObject newso) {
        // call the customer handler
        afterUpdateCustomerExtended(oldso, newso);

        // ... Sitetracker logic down here
        strk__Project__c oldProject = (strk__Project__c) oldso;
        strk__Project__c newProject = (strk__Project__c) newso;
        try {
            syncCustomerReady(oldProject, newProject);
        } catch (Exception e) {
            system.debug(LoggingLevel.ERROR, e.getMessage());
            system.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogic',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newso, 'oldRecord' => oldso});
        }
    }

    global override void afterInsert(SObject newso) {
        // call the customer handler
        afterInsertCustomerExtended(newso);

        // ... Sitetracker logic down here
        strk__Project__c newProject = (strk__Project__c) newso;
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogic',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newSo});
        }
    }

    global override void afterDelete(SObject so) {
        // call the customer handler
        afterDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    /**
     * This method is executed once per trigger event, after the processing of all the
     * individual lifecycle methods
     */
    global override void andFinally() {
        // call the customer handler
        andFinallyCustomerExtended();

        // ... Sitetracker logic down here
        relatedSites.saveChangesToDB();
        if (Trigger.isAfter && Trigger.isInsert && Trigger.New.size() > 0 && !Test.isRunningTest() && !System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(new STcreatePPMIntegration(Trigger.New, Trigger.New.get(0)));
        }
        if (Trigger.isAfter && Trigger.isUpdate && Trigger.oldMap != null && !Test.isRunningTest() && !System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(new STcreatePPMIntegration(Trigger.New, Trigger.oldMap, Trigger.New.get(0)));
        }
        if (Trigger.isAfter && !Trigger.isDelete && !Test.isRunningTest()) {
            notificationEngine.call('andFinally', new Map<String, Object>());
        }
    }

    public void syncCustomerReady(strk__Project__c oldProject, strk__Project__c newProject) {
        if (newProject.strk__Project_Template__c != null && newProject.strk__Project_Template__c.contains('US Development')) {
            if (oldProject.NTP_to_Customer_A__c != newProject.NTP_to_customer_A__C) {
                relatedSites.updateObjects(
                    newProject,
                    Schema.strk__Project__c.NTP_to_Customer_A__c,
                    Schema.strk__Site__c.Customer_Ready__c
                );
            }
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