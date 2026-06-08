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
 * @description HT_AgreementDueDiligenceDateReminderTest
 *
 * @author <A HREF="mailto:sjain@sitetracker.com">Shubham Jain</A>
 *
 ***************************************************************************************************/
@IsTest
public with sharing class HT_AgreementDueDiligenceDateReminderTest {
    @TestSetup
    static void setupTestData() {
        //Create test data
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

        Profile[] profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User user = new User(
                LastName = 'one',
                Username = Math.random() + 'one@example.com',
                Email = 'one@example.com',
                Alias = 'one',
                ProfileId = profiles[0].Id,
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );
        insert user;

        strk__Project__c project = new strk__Project__c(
                strk__Site__c = site.Id,
                strk__ProjectTemplate__c = testTemplate.Id,
                strk__Project_Type__c = 'Development',
                strk__Project_Manager__c = user.Id
        );
        insert project;

        // Create a test Contact record
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Admin Notification Contact', Email = 'readmin@harmonitowers.com');
        insert contact;

        List<Agreement__c> agreements = new List<Agreement__c>();

        for (Integer i = 12; i < 17; i++) {
            Agreement__c agreement = new Agreement__c();
            agreement.Agreement_Type__c = 'Ground';
            agreement.DD_Option_Current_Expiration_Date__c = System.today().addDays(i);
            agreement.Status__c = 'Draft';
            agreement.Site__c = site.Id;
            agreement.Contract_Fully_Executed__c = System.today();
            agreement.Project__c = project.Id;
            agreement.Ground_Interest__c = 'Purchase';
            agreements.add(agreement);
        }
        insert agreements;

    }

    @IsTest
    private static void testAgreementDueDiligenceDateReminderBatch() {
        Test.startTest();

        //Create a mock list of Custom Metadata Type (CMT) records
        List<Email_Alert_Settings__mdt> mockCMTData = new List<Email_Alert_Settings__mdt>{
                new Email_Alert_Settings__mdt(
                        Additional_Recipient_Email_Addresses__c = 'additional@example.com',
                        Email_Template_API_Name__c = 'Agreement_Due_Diligence_Reminder',
                        Reminder_Alert_Days__c = '2',
                        Is_Active__c = true,
                        Project_Recipient_Fields__c = 'Project_Manager__c,strk__Project_Manager__c'
                )
        };

        //Mock EmailTemplate
        EmailTemplate testTemplate = new EmailTemplate(
                DeveloperName = 'Agreement_Due_Diligence_Reminder',
                TemplateType = 'Text',
                Name = 'Test Template',
                Subject = 'Test Email Template',
                Body = 'This is a test email body.',
                FolderId = UserInfo.getUserId()
        );
        insert testTemplate;

        // Test.startTest();

        // Inject the mock CMT data into the batch class by using the setter method
        HT_AgreementDueDiligenceDateReminder batchClass = new HT_AgreementDueDiligenceDateReminder();
        batchClass.alertSettings = mockCMTData;

        //Execute the batch class
        Database.executeBatch(batchClass, 100);

        Test.stopTest();

        List<strk__Project__c> projects = [SELECT Id FROM strk__Project__c];
        System.assertEquals(1, projects.size(), 'Project record not exist');

        List<Agreement__c> agreements = [SELECT Id FROM Agreement__c];
        System.assertEquals(5, agreements.size(), 'Agreement records not exist');

    }
}