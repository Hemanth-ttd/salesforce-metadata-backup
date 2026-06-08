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
 * @description UnitiSiteTriggerHandler
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
global without sharing virtual class UnitiSiteTriggerHandler implements strk.StITrigger {
    private Map<Id, strk__Project__c> m_relatedProjects {
        get {
            if (m_relatedProjects == null) {
                set<id> SiteIds = new Set<id>();
                for (sobject anObject : Trigger.New) {
                    strk__Site__c site = (strk__Site__c) anObject;
                    SiteIds.add(site.id);
                }
                this.m_relatedProjects = new Map<ID, strk__Project__c>(
                    [
                        SELECT
                            name,
                            ID,
                            NTP_to_Customer_A__c,
                            strk__Site__c,
                            strk__Project_Template__c,
                            Site_Update_Flag__c
                        FROM strk__project__c
                        WHERE strk__site__c IN :SiteIds
                    ]
                );
            }
            return this.m_relatedProjects;
        }
        set;
    }
    private Set<String> updatedSites = new Set<String>();
    private Map<Id, strk__Project__c> m_projectsToUpdate {
        get {
            if (m_projectsToUpdate == null) {
                return new Map<ID, strk__Project__c>();
            }

            return m_projectsToUpdate;
        }
        set;
    }
    private List<Oracle_PPM_Mapping__mdt> vals;
    private strk.StNotificationEngine notificationEngine { get; set; }
    private static final String SOBJECT_API = 'strk__Site__c';

    global void initialize(String sObjectTypeName) {
        // call the customer handler
            initializeCustomerExtended(sObjectTypeName);

        // ... Sitetracker logic down here
        vals = [SELECT id, Field_API_Name__c FROM Oracle_PPM_Mapping__mdt WHERE Active__c = true AND Is_Update__c = true];
    }

    global void bulkBefore() {
        // call the customer handler
        bulkBeforeCustomerExtended();

        // ... Sitetracker logic down here
        if (!Test.isRunningTest() && !Trigger.isDelete && notificationEngine == null) {
            notificationEngine = new strk.StNotificationEngine();
            notificationEngine.call('initialize',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecords' => Trigger.new});
        }
    }

    global void bulkAfter() {
        // call the customer handler
        bulkAfterCustomerExtended();

        // ... Sitetracker logic down here
        if (Trigger.isUpdate) {
            getVals();
        }
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
    global void beforeUpdate(SObject oldSo, SObject newSO) {
        // call the customer handler
        beforeUpdateCustomerExtended(oldSo, newSO);

        // ... Sitetracker logic down here
        strk__Site__c newSite = (strk__Site__c) newso;
        strk__Site__c oldSite = (strk__Site__c) oldso;
        if (newSite.customer_Ready__c > date.today()) {
            newSite.addError('This date cannot be set to be in the future');
        }
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogicBefore',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newSo, 'oldRecord' => oldSo});
        }
    }

    global void beforeInsert(SObject newSO) {
        // call the customer handler
        beforeInsertCustomerExtended(newSO);

        // ... Sitetracker logic down here
    }

    global void beforeDelete(SObject so) {
        // call the customer handler
        beforeDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    global void afterUpdate(SObject oldso, SObject newso) {
        // call the customer handler
        afterUpdateCustomerExtended(oldso, newso);

        // ... Sitetracker logic down here
        strk__Site__c newSite = (strk__Site__c) newso;
        strk__Site__c oldSite = (strk__Site__c) oldso;
        try {
            m_projectsToUpdate = getProjectsToSync(
                oldSite,
                newSite,
                getSpecificUSDevelopmentSites(newSite, m_relatedProjects),
                Schema.strk__Site__c.Customer_Ready__c,
                Schema.strk__Project__c.NTP_to_Customer_A__c
            );
        } catch (Exception e) {
            system.debug(LoggingLevel.ERROR, e.getMessage());
            system.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogic',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newso, 'oldRecord' => oldso});
        }
    }

    global void afterInsert(SObject newso) {
        // call the customer handler
        afterInsertCustomerExtended(newso);

        // ... Sitetracker logic down here
        strk__Site__c newSite = (strk__Site__c) newso;
        if (!Test.isRunningTest()) {
            notificationEngine.call('evaluateLogic',
                new Map<String, Object>{'objectType' => SOBJECT_API, 'newRecord' => newso});
        }
    }

    global void afterDelete(SObject so) {
        // call the customer handler
        afterDeleteCustomerExtended(so);

        // ... Sitetracker logic down here
    }

    /**
     * This method is executed once per trigger event, after the processing of all the
     * individual lifecycle methods
     */
    global void andFinally() {
        // call the customer handler
        andFinallyCustomerExtended();

        // ... Sitetracker logic down here
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

    private List<strk__Project__c> filterProjectsbySite(strk__Site__c site, Map<id, strk__Project__c> projectMap) {
        List<strk__Project__c> projectList = new List<strk__Project__c>();
        for (strk__Project__c project : projectMap.values()) {
            if (project.strk__site__c == site.id) {
                projectList.add(project);
            }
        }

        return projectList;
    }

    private List<strk__Project__C> getSpecificUSDevelopmentSites(strk__Site__c site, Map<id, strk__Project__c> projectMap) {
        List<strk__Project__c> projectList = new List<strk__Project__c>();
        for (strk__Project__c project : projectMap.values()) {
            if (project.strk__site__c == site.id && project.strk__Project_Template__c.contains('US Development')) {
                projectList.add(project);
            }
        }

        return projectList;
    }

    private map<id, strk__Project__c> getProjectsToSync(
        strk__site__c oldSite,
        strk__site__c newSite,
        List<strk__Project__c> relatedProjects,
        Schema.sobjectField SiteField,
        Schema.sobjectField ProjectField
    ) {
        map<id, strk__Project__c> m_projectsToReturn = new Map<id, strk__Project__c>();
        for (strk__Project__c project : relatedProjects) {
            ///does not sync blank values
            if (project.get(ProjectField) == null) {
                if (
                    ((oldSite == null && newSite.get(SiteField) != null) ||
                    (oldSite != null &&
                    oldSite.get(SiteField) != newSite.get(SiteField))) && project.get(ProjectField) != newSite.get(SiteField)
                ) {
                    project.put(ProjectField, newSite.get(SiteField));
                    m_projectsToReturn.put(project.id, project);
                }
            }
        }

        return m_projectsToReturn;
    }

    private void getVals() {
        List<String> fields = new List<String>();
        for (Oracle_PPM_Mapping__mdt oppm : vals) {
            if (oppm.Field_API_Name__c.contains('strk__Site__r.')) {
                fields.add(oppm.Field_API_Name__c.remove('strk__Site__r.'));
            }
        }

        for (SObject newS : Trigger.new) {
            strk__Site__c newSite = (strk__Site__c) newS;
            strk__Site__c oldSite = (strk__Site__c) Trigger.oldMap.get((String) newS.get('Id'));
            for (String field : fields) {
                if (newSite.get(field) != oldSite.get(field)) {
                    updatedSites.add((String) newSite.Id);
                    break;
                }
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