/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2021 SITETRACKER, INC., All Rights Reserved.
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
 * @description UnitiCreateProjectEventTriggerHandler
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
 *
 ***************************************************************************************************/
public class UnitiCreateProjectEventTriggerHandler implements strk.StITrigger {
    public void initialize(String sObjectName) {
    }

    public void bulkBefore() {
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
    }

    public void afterInsert(SObject so) {
        CreateProject__e evt = (CreateProject__e) so;

        try {
            List<strk__Project__c> projectList = evt.Json_String__c == null
                ? null
                : (List<strk__Project__c>) JSON.deserialize(evt.Json_String__c, List<strk__Project__c>.class);

            insert projectList;
        } catch (Exception e) {
            strk.StLog.debug( UnitiCreateProjectEventTriggerHandler.class, 'Error occured during CreateProject event trigger execution :' + e.getMessage() );
        }

        // store the current replay Id so we can continue to next record if we hit any limit issues.
        EventBus.TriggerContext.currentContext().setResumeCheckpoint(evt.ReplayId);
    }

    public void beforeUpdate(SObject oldSo, SObject newSo) {
    }

    public void afterUpdate(SObject oldSo, SObject newSo) {
    }

    public void beforeDelete(SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void andFinally() {
    }
}