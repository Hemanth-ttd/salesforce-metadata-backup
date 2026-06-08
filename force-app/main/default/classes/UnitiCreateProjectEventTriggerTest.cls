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
 * @description UnitiCreateProjectEventTriggerTest
 *
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
 ***************************************************************************************************/
@IsTest
private class UnitiCreateProjectEventTriggerTest {
    @TestSetup
    static void setupTestData() {
        List<strk__Project_Template__c> templateList = new List<strk__Project_Template__c>();

        strk__Project_Template__c attTemplate = new strk__Project_Template__c(
            Name = Label.SITE_DEVELOPMENT_ATT_WITH_HNS_PROJECT_TEMPLATE,
            strk__Project_Extension_Objects__c = String.valueOf( Site_Development_AT_T__c.SObjectType ),
            strk__Active__c = true,
            strk__Category__c = Uniti_Constants.PROJECT_TEMP_CATEGORY_TOWERS
        );
        templateList.add(attTemplate);

        strk__Project_Template__c hnsTemplate = new strk__Project_Template__c(
            Name = Label.SITE_DEVELOPMENT_ABM_HNS_WITH_ATT_PROJECT_TEMPLATE,
            strk__Project_Extension_Objects__c = String.valueOf( Site_Development_ABM_HNS__c.SObjectType ),
            strk__Active__c = true
        );
        templateList.add(hnsTemplate);

        insert templateList;

        strk__Site__c site = new strk__Site__c(
            Name = 'Test site',
            Site_ID__c = 'TestSiteId'
        );
        insert site;

        strk__Project_Milestone__c subMilestone = new strk__Project_Milestone__c(
            strk__sObjectType__c = String.valueOf( Site_Development_AT_T__c.SObjectType ),
            strk__Forecast_Field_API_Name__c = 'Name',
            strk__Actual_Field_API_Name__c = 'Name',
            Name = 'Subfield milestone'
        );
        insert subMilestone;

        strk__Activity_Template__c activityTemplate = new strk__Activity_Template__c(
            strk__Project_Template__c = attTemplate.Id,
            strk__Project_Milestone__c = subMilestone.Id,
            strk__Activity_Type__c = 'Field',
            strk__Field_Name__c = 'Name',
            Name  = 'Name',
            strk__Schedule_Width__c = 'Small',
            strk__Order__c = 10
        );

        insert activityTemplate;

    }

    @IsTest
    static void TestEventExecution() {
        List<strk__Project_Template__c> attTemplate = [
            SELECT Id, Name, strk__Category__c
            FROM strk__Project_Template__c
            WHERE Name =: Label.SITE_DEVELOPMENT_ATT_WITH_HNS_PROJECT_TEMPLATE
        ];
        System.assertEquals( 1, attTemplate.size(), 'AT&T template not found' );

        List<strk__Project_Template__c> hnsTemplate = [
            SELECT Id, Name
            FROM strk__Project_Template__c
            WHERE Name =: Label.SITE_DEVELOPMENT_ABM_HNS_WITH_ATT_PROJECT_TEMPLATE
        ];
        System.assertEquals( 1, hnsTemplate.size(), 'HNS template not found' );

        List<strk__Site__c> site = [
            SELECT Id, Name
            FROM strk__Site__c
        ];
        System.assertEquals( 1, site.size(), 'Site not found' );

        Test.startTest();

        strk__Project__c project = new strk__Project__c(
            strk__Site__c = site[0].Id,
            strk__ProjectTemplate__c = attTemplate[0].Id,
            strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
            strk__Project_Type__c = 'AT&T',
            Agreement__c = Uniti_Constants.PROJECT_AGREEMENT_ABM,
            Category__c = Uniti_Constants.PROJECT_CATEGORY_DEVELOPMENT
        );
        insert project;

        List<Site_Development_AT_T__c> verifyATT = [
            SELECT Id, Project__c, Project__r.Site_Development_AT_T__c, Project_Template__c
            FROM Site_Development_AT_T__c
            WHERE Project__c =: project.Id
        ];
        System.assertEquals( 1, verifyATT.size(), 'AT&T subproject not created' );
        System.assertNotEquals( null, verifyATT[ 0 ].Project__r.Site_Development_AT_T__c, 'lookup on project not connected' );
        System.assertEquals( verifyATT[ 0 ].Id, verifyATT[ 0 ].Project__r.Site_Development_AT_T__c, 'lookup does not match' );

        Test.stopTest();

        //Event trigger creates ABM HNS project
        List<strk__Project__c> verifyABM = [
            SELECT Id, Site_Development_AT_T__c, Site_Development_ABM_HNS__c, strk__ProjectTemplate__c
            FROM strk__Project__c
            WHERE strk__ProjectTemplate__c =: hnsTemplate[0].Id
        ];
        System.assertEquals( 1, verifyABM.size(), 'ABM HNS Project not created' );
    }
}