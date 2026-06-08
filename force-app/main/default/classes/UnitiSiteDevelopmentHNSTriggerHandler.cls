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
* @description UnitiSiteDevelopmentHNSTriggerHandler
*
*
* @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
*
***************************************************************************************************/
global without sharing class UnitiSiteDevelopmentHNSTriggerHandler extends strk.StSubProjectExtendableTriggerHandler {
    private static final String SOBJECT_API = String.valueOf( Site_Development_ABM_HNS__c.SObjectType );
    private List<Site_Development_AT_T__c> attProjsToUpdate = new List<Site_Development_AT_T__c>();

    global virtual override void initializeExtended(String subProjectObjectName) {
    }

    global virtual override void bulkBeforeExtended() {
        if(Trigger.isInsert){
            //ST-00029566 : On creating AT&T project we auto create an ABM HNS project for certain criteria so linking the AT&T with the new HNS below
            Map<Id, Site_Development_ABM_HNS__c> projToHnsMap = new Map<Id, Site_Development_ABM_HNS__c>();

            for (Site_Development_ABM_HNS__c hnsProj : (List<Site_Development_ABM_HNS__c>) Trigger.new){
                if(hnsProj.Project_Template__c == Label.SITE_DEVELOPMENT_ABM_HNS_WITH_ATT_PROJECT_TEMPLATE){
                    projToHnsMap.put(hnsProj.Project__c, hnsProj);
                }
            }

            if(!projToHnsMap.isEmpty()){
                List<strk__Project__c> projList = [SELECT Site_Development_AT_T__c
                                                FROM strk__Project__c
                                                WHERE ID IN: projToHnsMap.keySet()];

                if(!projList.isEmpty()){
                    for(strk__Project__c proj : projList){
                        Site_Development_ABM_HNS__c hnsAbmProj = projToHnsMap.get(proj.Id);
                        hnsAbmProj.Site_Development_AT_T__c = proj.Site_Development_AT_T__c;
                    }
                }
            }
        }
    }

    global virtual override void bulkAfterExtended() {
        if(Trigger.isInsert){
            //ST-00029566 : Establishing connection 1:1 connection between AT&T and ABM HNS projects
            for (Site_Development_ABM_HNS__c hnsProj : (List<Site_Development_ABM_HNS__c>) Trigger.new){
                if(hnsProj.Site_Development_AT_T__c != null){
                    Site_Development_AT_T__c attProj = new Site_Development_AT_T__c();
                    attProj.Id = hnsProj.Site_Development_AT_T__c;
                    attProj.Site_Development_ABM_HNS__c = hnsProj.Id;
                    attProjsToUpdate.add(attProj);
                }
            }
        }
    }

    global virtual override void beforeInsertExtended( SObject so ){
    }

    global virtual override void beforeUpdateExtended(SObject oldSo, SObject newSo){
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
        if(Trigger.isAfter && Trigger.isInsert && !attProjsToUpdate.isEmpty()){
            update attProjsToUpdate;
        }
    }

}