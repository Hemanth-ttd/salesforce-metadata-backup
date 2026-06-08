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
 * @description UnitiProjectTriggerHandlerTest
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
@isTest
public with sharing class UnitiProjectTriggerHandlerTest {

	@TestSetup
	static void makeData(){
		strk__Project_Template__c testTemplate = new strk__Project_Template__c(
			strk__Active__c = true,
			Name = 'US Development'
		);

		insert new strk__Project_Template__c(
			strk__Active__c = true,
			Name = 'test template'
		);
		Database.insert( testTemplate );

		strk__Site__c testSite = new strk__Site__c(
			Name = 'Test Site 123',
			Site_ID__c = 'TestSiteId'
		);

		Database.insert( testSite );

		strk__Project__c testProject = new strk__Project__c(
			strk__Site__c = testSite.Id,
			strk__ProjectTemplate__c = testTemplate.Id,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM'
		);

		Database.insert( testProject );

	}

	@isTest
	static void TestSyncProjectToSite(){

		strk__Project__C project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];

		project.NTP_to_Customer_A__c = date.today();
		update project;
		project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];
		strk__Site__c site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];
		system.assertEquals(date.today(), site.Customer_Ready__C);

	}
	@isTest
	static void TestSyncProjectToSitenoSync(){

		strk__Site__c site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];
		site.Customer_Ready__c = date.today().addDays(-2);
		update site;
		site = [SELECT id, Customer_Ready__c FROM strk__Site__c Limit 1];

		strk__Project__C project = [SELECT id, NTP_to_Customer_A__c FROM strk__Project__c Limit 1];
		project.NTP_to_Customer_A__c = date.today();
		update project;

		project.NTP_to_Customer_A__c = date.today();
		system.assertEquals(date.today().addDays(-2), site.Customer_Ready__C);

	}
	@isTest
	static void TestSyncProjectContractorToSite(){
		strk__project__c proj = new strk__project__c(
			strk__Site__c = [select id from strk__Site__c].Id,
			strk__ProjectTemplate__c = [SELECT id FROM strk__project_template__c WHERE name LIKE '%test%'].id,
			strk__Project_Status__c = '',
			strk__Project_Start_Date_F__c = System.today(),
			strk__Project_Type__c = 'ABM'
		);
		insert proj;

	}
}