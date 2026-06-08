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
* @description Uniti_Util
*
*
* @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
*
***************************************************************************************************/
global without sharing class Uniti_Util{

    /**
     * Query SITE_DEVELOPMENT_ABM_HNS_WITH_ATT_PROJECT_TEMPLATE project templates
     */
    private static strk__Project_Template__c hnsTemplate {
        get {
            if (hnsTemplate == null) {
                hnsTemplate = [SELECT Id
                        FROM strk__Project_Template__c
                        WHERE Name =: Label.SITE_DEVELOPMENT_ABM_HNS_WITH_ATT_PROJECT_TEMPLATE
                        LIMIT 1];
            }

            return hnsTemplate;
        }
        set;
    }

    /**
     * Method to create an ABM HNS project extension
     * @param proj - main project like AT&T from which a secondary HNS extension is to be created
     *
     * @return strk__Project__c - the ABM HNS project extension to insert with some prefilled fields
     */
    Public static strk__Project__c createAbmNhsProject(SObject proj){
        strk__Project__c newHNSProj = new strk__Project__c(
            strk__ProjectTemplate__c = hnsTemplate.Id,
            strk__Project_Start_Date_A__c = System.today(),
            strk__Project_Start_Date_F__c = System.today(),
            strk__Customer__c = 'Harmoni Towers',
            Justification__c = 'RAN Construction',
            Funding__c = 'CAP',
            Category__c = 'Development',
            strk__Project_Type__c = 'ABM',
            Project_Name__c = (String)proj.get('Name') + '_ABM',
            Agreement__c = 'ABM',
            Site_Development_AT_T__c = (Id)proj.get('Id'),
            strk__Site__c = (Id)proj.get('Site__c')
        );

        return newHNSProj;
    }
}