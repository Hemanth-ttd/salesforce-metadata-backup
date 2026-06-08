/**
 * Created by RPayn on 3/1/2018.
 */

@IsTest
private class ProjectEmailService_Test {

    @testSetup
    static void setupTestData(){
        string body = '[ "Project", {"Construction_complete_A__c" : "","SubType_2__c" : "", "strk__County__c" : "","Budget_Cost__c" : "100.00","strk__Project_Status__c" : "",';
                body += '"Project_Name__c" : "Test Multiple 9","strk__Project_Type__c" : "","Reason_Code__c" : "","SubType_1_Alt__c" : "","Funding__c" : "CAP","Source__c" : "Uniti - AT&T Anchor",';
                body += '"strk__Customer__c" : "","Id" : "a0K0U000002LQGkUAO","Integration_State__c" : "OK","strk__Project_Template__c" : "","Country__c" : "United States","Site_ID_Formula__c" : "OKL01474",';
                body += '"SubType_1__c" : "","Justification__c" : "Test Justification","strk__Project_Start_Date_F__c" : "2018-11-06 00:00:00","SBO_received__c" : "","Integration_Project_Name__c" : "OKL01474_Garland Enid_Test Multiple 9",';
                body += '"Site_Name" : "Garland Enid","strk__Street_Address__c" : "1016 South Garland Road","strk__City__c" : "Enid","Category__c" : "Operations","Name" : "P-001992"}]';

        // instantiate HttpMock with fake response
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',body,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);
        strk__Project_Template__c testTemplate = new strk__Project_Template__c(
                strk__Active__c = true,
                Name = 'Test Template 1'
        );

        Database.insert( testTemplate );

        strk__Site__c testSite = new strk__Site__c(
            Name = 'Test Site',
            Site_ID__c = String.valueOf(Math.random()),
            strk__County__c = 'test county',
            Source__c = 'Uniti - AT&T Anchor',
            Country__c = 'United States',
            strk__Street_Address__c = '1016 South Garland Road',
            strk__City__c = 'Enid'
        );

        Database.insert( testSite );

        strk__Project__c testProject = new strk__Project__c(
                strk__Site__c= testSite.Id,
                strk__ProjectTemplate__c = testTemplate.Id,
                strk__Project_Status__c = '',
                strk__Project_Start_Date_F__c = System.today(),
                strk__Project_Type__c = 'ABM'
        );

        Database.insert( testProject );

    }

    static testMethod void Test_ProjectEmailService_NoAttachments(){
        List<strk__Project__c> projects = [ SELECT Id, Name FROM strk__Project__c ];

        System.assertEquals( 1, projects.size() );

        List<Email_To_Object_Setting__mdt> settings = [ 	SELECT Id, DeveloperName, MasterLabel, Active__c, Object_Type__c, Project_Object__c, Project_Status_Field__c, Alt_Search_Field__c, Search_Field__c, Site_Object__c, Site_Status_Field__c, Statuses_To_Ignore__c, Use_Site_Status_Field__c
        FROM Email_To_Object_Setting__mdt
        WHERE Active__c =: true
        LIMIT 1
        ];

        Messaging.InboundEmail inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'Test This record';


        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        ProjectEmailService service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );

        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );


    }

    static testMethod void Test_ProjectEmailService_TextAttachments(){
        List<strk__Project__c> projects = [ SELECT Id, Name FROM strk__Project__c ];

        System.assertEquals( 1, projects.size() );

        Blob attachments = Blob.valueOf( '1234567' );

        Messaging.InboundEmail.TextAttachment testAttachments = new Messaging.InboundEmail.TextAttachment();
        testAttachments.body = String.valueOf( attachments );
        testAttachments.fileName = 'testFile';

        Messaging.InboundEmail inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'Test This record' + projects[ 0 ].Id;
        inbEmail.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{ testAttachments };

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        ProjectEmailService service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );


        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );

        ProjectEmailService.getProjectIdFromSubject(  projects[ 0 ].Name + ' ' + inbEmail.Subject );
        ProjectEmailService.getProjectIdFromToField(env.toAddress + '@sitetracker.com' );
        ProjectEmailService.getProjectIdFromSubject( projects[ 0 ].Name );

    }

    static testMethod void Test_ProjectEmailService_BinaryAttachments(){

        List<strk__Project__c> projects = [ SELECT Id, Name FROM strk__Project__c ];

        System.assertEquals( 1, projects.size() );

        Blob attachments = Blob.valueOf( '1234567' );
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = attachments;
        attachment.fileName = 'testFileName';

        Messaging.InboundEmail inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'Test This record';
        inbEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment> { attachment };


        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        ProjectEmailService service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );

        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        service = new ProjectEmailService();
        service.handleInboundEmail( inbEmail, env );
    }
}