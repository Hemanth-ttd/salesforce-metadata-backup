/**
 * Created by RPayn on 3/1/2018.
 */
@isTest
public with sharing class Uniti_SiteControllerExtension_Test {

    @testSetup
    public static void setupTestData(){

        strk__Project_Template__c testTemplate = new strk__Project_Template__c(strk__Active__c = true);

        Database.insert( testTemplate );

        strk__Site__c testSite = new strk__Site__c(
                Name = 'Test Site 1234',
                Site_ID__c = '12345'
        );

        Database.insert( testSite );

    }

    public static testMethod void Test_UnitiSitecontrollerExtensionView(){
        List<strk__Site__c> testSites = [ SELECT Id, Name, Site_ID__c FROM strk__Site__c ];
        System.assertEquals( 1, testSites.size() );

        ApexPages.standardController ctrl = new ApexPages.standardController( testSites[ 0 ] );
        PageReference pg = Page.Uniti_Site_ViewAll;

        test.setCurrentPageReference( pg );

        Uniti_SiteControllerExtension ext = new Uniti_SiteControllerExtension( ctrl );
        ext.saveExtended();
        ext.setProjectType();
    }


    public static testMethod void Test_UnitiSitecontrollerExtensionCreate(){

        ApexPages.standardController ctrl = new ApexPages.standardController( new strk__Site__c() );
        PageReference pg = Page.Uniti_Site_Create_New;

        test.setCurrentPageReference( pg );

        Uniti_SiteControllerExtension ext = new Uniti_SiteControllerExtension( ctrl );
        ext.siteName = '';
        ext.createSite();

        PageReference result1 = ext.createSite();

        System.assertEquals( null, ext.newSite.Id );

        ext.siteName = 'test Site Name';
        ext.newSite.Site_Id__c = '123455';
        ext.createSite();
        System.assertEquals( 1, [ SELECT Count() FROM strk__Site__c WHERE Name =: 'test Site Name' ]);

        ext.saveExtended();
        ext.setProjectType();
    }

    public static testMethod void Test_UnitiSitecontrollerExtensionCreateProject(){

        List<strk__Project_Template__c> testTemplates = [ SELECT Id FROM strk__Project_Template__c ];
        System.assertEquals( 1, testTemplates.size() );

        ApexPages.standardController ctrl = new ApexPages.standardController( new strk__Site__c() );
        PageReference pg = Page.Uniti_Site_Create_New;

        test.setCurrentPageReference( pg );

        Uniti_SiteControllerExtension ext = new Uniti_SiteControllerExtension( ctrl );
        ext.siteName = '';
        ext.createSite();

        PageReference result1 = ext.createSite();

        System.assertEquals( null, ext.newSite.Id );

        ext.siteName = 'test Site Name';
        ext.newSite.Site_Id__c = '123455';
        ext.createProject = true;
        ext.newProject.strk__Project_Start_Date_F__c = System.today();
        ext.newProject.strk__ProjectTemplate__c = testTemplates[ 0 ].Id;
        ext.newProject.strk__Project_Type__c = 'ABM';

        ext.createSite();
        System.assertEquals( 1, [ SELECT Count() FROM strk__Site__c WHERE Name =: 'test Site Name' ]);
        System.assertEquals( 1, [ SELECT Count() FROM strk__Project__c WHERE strk__ProjectTemplate__c =: testTemplates[ 0 ].Id ]);

        ext.saveExtended();
        ext.setProjectType();

        ext.projectTypes = new List<SelectOption>();
        ext.siteTypes = new List<SelectOption>();
        ext.siteType = 'empty';
        ext.selectedType = 'empty';

        ext = new Uniti_SiteControllerExtension();


        // Run as user who can't create site to hit condition
        Profile p = [SELECT Id FROM Profile WHERE Name='Read Only'];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User testUser = new User(Alias = 'standt', Email='standarduser@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles',UserName=uniqueUserName);

        System.runAs(testUser) {
            ext = new Uniti_SiteControllerExtension( ctrl );
            ext.siteName = '';
            ext.createSite();

            PageReference result2 = ext.createSite();

            ext.siteName = 'test Site Name';
            ext.newSite.Site_Id__c = '123455';
            ext.createProject = true;
            ext.newProject.strk__Project_Start_Date_F__c = System.today();
            ext.newProject.strk__ProjectTemplate__c = testTemplates[ 0 ].Id;

            ext.createSite();
        }
    }
}