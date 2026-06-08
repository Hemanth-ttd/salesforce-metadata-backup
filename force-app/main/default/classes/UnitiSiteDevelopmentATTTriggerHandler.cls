/*************************************************************************************************
* SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
* Unpublished Copyright (c) 2013-2022 SITETRACKER, INC., All Rights Reserved.
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
* @description UnitiSiteDevelopmentATTTriggerHandler
*
*
* @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
*
***************************************************************************************************/
global without sharing class UnitiSiteDevelopmentATTTriggerHandler extends strk.StSubProjectExtendableTriggerHandler {
    private static final String SOBJECT_API = String.valueOf( Site_Development_AT_T__c.SObjectType );
    private List<strk__Project__c> hnsProjsToInsert = new List<strk__Project__c>();

    global virtual override void initializeExtended(String subProjectObjectName) {
    }

    global virtual override void bulkBeforeExtended() {
    }

    global virtual override void bulkAfterExtended() {
        if(Trigger.isInsert){
            Set<Id> projIds = new Set<Id>();

            // Logic for auto genertaing a secondary project extension object ABM HNS along with ATT for below criteria:
            // Project Category as 'Development', Project Agreement as 'ABM'
            // And Project template category as 'Towers'
            for (Site_Development_AT_T__c attProj : (List<Site_Development_AT_T__c>) Trigger.new){
                if(attProj.Project_Template_Category__c == Uniti_Constants.PROJECT_TEMP_CATEGORY_TOWERS
                    && attProj.ABM_Project_Type__c != '' && attProj.ABM_Project_Type__c != 'No ABM' && attProj.Category__c == Uniti_Constants.PROJECT_CATEGORY_DEVELOPMENT){
                    hnsProjsToInsert.add(Uniti_Util.createAbmNhsProject(attProj));
                }
            }
        }
    }

    global virtual override void beforeInsertExtended(SObject newObject) {
    }

    global virtual override void beforeUpdateExtended(SObject oldSo, SObject newSo) {
    }

    global virtual override void beforeDeleteExtended(SObject so) {
    }

    global virtual override void afterInsertExtended(SObject newSo) {
    }

    global virtual override void afterUpdateExtended(SObject oldSo, SObject newSo) {
    }

    global virtual override void afterDeleteExtended(SObject so) {
    }

    global virtual override void andFinallyExtended() {
        if(Trigger.isInsert && Trigger.isAfter && !hnsProjsToInsert.isEmpty()){
            CreateProject__e evt = new CreateProject__e(
                Json_String__c = JSON.serialize(hnsProjsToInsert)
            );

            // Publish event as platform caching doesnt allow 2 extensions to be generated in the same transaction
            EventBus.publish(evt);
        }
    }

}