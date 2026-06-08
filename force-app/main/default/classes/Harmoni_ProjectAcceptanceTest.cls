/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2020 SITETRACKER, INC., All Rights Reserved.
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
 * @description Harmoni_ProjectAcceptanceTest
 *
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
 ***************************************************************************************************/
@IsTest
private class Harmoni_ProjectAcceptanceTest {
    @TestSetup
    static void setupTestData() {
        strk__Site__c site = new strk__Site__c(
            Name = 'Test site',
            Site_ID__c = 'TestSiteId'
        );
        insert site;

        strk__Project_Template__c testTemplate = new strk__Project_Template__c(
            Name = 'Test Template',
            strk__Active__c = true
        );
        insert testTemplate;

        strk__Project__c project = new strk__Project__c(
            strk__Site__c = site.Id,
            strk__ProjectTemplate__c = testTemplate.Id,
            strk__Project_Type__c = 'Development'
        );
        insert project;
    }

    @IsTest
    static void TestBasicTriggerFunctions() {
        List<strk__Site__c> sites = [
            SELECT Id
            FROM strk__Site__c
        ];
        System.assertEquals( 1, sites.size(), 'Site should be available to proceed further' );

        List<strk__Project__c> projects = [
            SELECT Id
            FROM strk__Project__c
        ];
        System.assertEquals( 1, projects.size() );

        strk__Approval_Process_Template__c approvalTemp = new strk__Approval_Process_Template__c(
            strk__Active__c = true,
            strk__Object_API__c = 'Project_Acceptance__c',
            strk__Approval_Process_Template_Name__c = 'Test PA Approval'
        );
        insert approvalTemp;

        Reviewer_Matrix__c revMatrix = new Reviewer_Matrix__c(
            Approval_Process_Template__c = approvalTemp.Id,
            Object_API__c = 'Project_Acceptance__c',
            Name = 'Test PA RM'
        );
        insert revMatrix;

        Test.startTest();
            Project_Acceptance__c projAcceptance = new Project_Acceptance__c(
                Site__c = sites[0].Id,
                Project__c = projects[0].Id
            );
            insert projAcceptance;

            projAcceptance = [
                SELECT Id, Approval_Process__c
                FROM Project_Acceptance__c
                WHERE Id =: projAcceptance.Id
            ];

            Assert.isNotNull(projAcceptance.Approval_Process__c, 'Approval Process should be assigned to this Project Acceptance');
        Test.stopTest();
    }
}