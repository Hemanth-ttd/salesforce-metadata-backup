/*************************************************************************************************
 * SITETRACKER, INC. ("Sitetracker") CONFIDENTIAL
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
 * @description Uniti_ContDocLinkTriggerHandlerTest
 *
 * @author <A HREF="mailto:bkocherla@sitetracker.com">Bandhavi Kocherla</A>
 *
 ***************************************************************************************************/

@isTest
public class Uniti_ContDocLinkTriggerHandlerTest {
    
    @TestSetup
    static void createTestData(){
        
        strk__project_Template__c template = new strk__project_Template__c();
        template.strk__Active__c = true;
        template.Name = 'Test Title';
        insert template;
        
        strk__Site__c site = new strk__Site__c();
        site.Name='SiteForSFCcontentTest';
        site.Site_ID__c = '123';
        site.strk__Site_Status__c = 'Under Development';
        site.Division__c = 'US';
        site.Source__c = 'ACQ - Hunt';
        site.Country__c = 'United States';
        site.strk__State__c = 'NJ';
        insert site;
        
        Strk__Project__c proj1 = new Strk__Project__c();
        proj1.strk__site__c = site.id;
        proj1.strk__ProjectTemplate__c = template.id;
        proj1.strk__Project_Start_Date_F__c = Date.today();
        proj1.strk__Project_Complete_F__c = Date.today() + 10;
        proj1.Project_Name__c = 'Test Multiple 32';
        proj1.Budget_Cost__c = 100;
        proj1.Justification__c = 'Test Justification';
        proj1.Funding__c = 'CAP';
        proj1.Category__c = 'Operations';
        proj1.strk__Project_Type__c = 'ABM';
        insert proj1;
        
        Test.startTest();
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Title';
        contentVersion.PathOnClient = contentVersion.Title + '.jpg';
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        contentVersion.VersionData = bodyBlob;
        contentVersion.origin = 'H';
        insert contentVersion;
        
        contentVersion contVer = [SELECT Id,ContentDocumentId FROM contentVersion LIMIT 1];

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = site.id;
        contentlink.ContentDocumentId = contVer.ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;

        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = proj1.id;
        contentlink1.ContentDocumentId = contVer.ContentDocumentId;
        contentlink1.ShareType = 'V';
        insert contentlink1;
    }
    
    static testMethod void validateFileNameOnSite(){
        
        strk__Site__c siteRec = [SELECT Id,Name,Site_ID__c FROM strk__Site__c LIMIT 1];

        List<ContentDocumentLink> conDocLinks = [SELECT Id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: siteRec.Id];
        System.assertEquals(1, conDocLinks.size(), 'File is not linked to Site Record');
        
        ContentDocument document = [SELECT Id, Title, FileType, LatestPublishedVersionId FROM ContentDocument WHERE Id =: conDocLinks[0].ContentDocumentId];
        
        Date dToday = Date.today();
        Datetime todayDateTime = Datetime.newInstanceGmt(dToday, Time.newInstance(0,0,0,0));
        String fileName = siteRec.Site_ID__c + '_' + siteRec.Name + '_Test Title Version 1_' + todayDateTime.format('yyyy-MM-dd');
        
        System.assertEquals(fileName, document.Title, 'File name is not matching');
        
        List<strk__Attachment__c> attachments = [SELECT Id,Name 
                                                 FROM strk__Attachment__c 
                                                 WHERE strk__ContentDocumentRecord__c =: conDocLinks[0].ContentDocumentId];
        
        System.assertEquals(1, attachments.size(),'Attachment has not been created');
        System.assertEquals(fileName, attachments[0].Name,'File name is not matching');
    }
    
    static testMethod void validateFileNameOnProject(){
        
        Strk__Project__c projectRec = [SELECT Id,strk__site__r.Name,strk__site__r.Site_ID__c FROM Strk__Project__c LIMIT 1];

        List<ContentDocumentLink> conDocLinks = [SELECT Id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: projectRec.Id];
        System.assertEquals(1, conDocLinks.size(), 'File is not linked to Site Record');
        
        ContentDocument document = [SELECT Id, Title, FileType, LatestPublishedVersionId FROM ContentDocument WHERE Id =: conDocLinks[0].ContentDocumentId];
        
        Date dToday = Date.today();
        Datetime todayDateTime = Datetime.newInstanceGmt(dToday, Time.newInstance(0,0,0,0));
        String fileName = projectRec.strk__site__r.Site_ID__c + '_' + projectRec.strk__site__r.Name + '_Test Title Version 1_' + todayDateTime.format('yyyy-MM-dd');
        
        System.assertEquals(fileName, document.Title, 'File name is not matching');
        
        List<strk__Attachment__c> attachments = [SELECT Id,Name 
                                                 FROM strk__Attachment__c 
                                                 WHERE strk__ContentDocumentRecord__c =: conDocLinks[0].ContentDocumentId];
        
        System.assertEquals(1, attachments.size(),'Attachment has not been created');
        System.assertEquals(fileName, attachments[0].Name,'File name is not matching');
    }
}