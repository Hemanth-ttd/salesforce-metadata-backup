/**
 * Created by RPayn on 3/1/2018.
 *
 */

@IsTest
private class EmailToProjectService_Test {

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


        EmailToProjectService service = new EmailToProjectService();
        service.handleInboundEmail( inbEmail, env );

        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        service = new EmailToProjectService();
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
        inbEmail.subject = 'Test This record';
        inbEmail.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{ testAttachments };

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        EmailToProjectService service = new EmailToProjectService();
        service.handleInboundEmail( inbEmail, env );


        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        service = new EmailToProjectService();
        service.handleInboundEmail( inbEmail, env );

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


        EmailToProjectService service = new EmailToProjectService();
        service.handleInboundEmail( inbEmail, env );

        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'RE: Test This record';


        env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';

        service = new EmailToProjectService();
        service.handleInboundEmail( inbEmail, env );

        inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'FW: Test This record';
    }

    static testMethod void Test_ProjectEmailService_HandlerMethods(){
        List<strk__Site__c> sites = [ SELECT Id, Name, Site_Id__c, strk__Site_Status__c FROM strk__Site__c ];
        System.assertEquals( 1, sites.size() );

        List<strk__Project__c> projects = [ SELECT Id, Name FROM strk__Project__c ];
        System.assertEquals( 1, projects.size() );

        Email_To_Object_Setting__mdt mConfig1 = EmailToProjectService_Test.getMockMetaRecord(
                            'MetaOne',  // Dev Name
                            true,   // Active
                            'strk__Project__c', //Object Type
                            'strk__Project__c', // Project Object
                            'strk__Project_Status__c', // Project Status Field
                            '',  // Project Status
                            'subject', // Alt Search Field
                            'subject',  // Search Field
                            'strk__Site__c',    // Site Object
                            'strk__Site_Status__c',     // Site Status Field
                            'Complete',     // Ignore statuses
                            false );    // use Site Status

        Email_To_Object_Setting__mdt mConfig2 = EmailToProjectService_Test.getMockMetaRecord(
                            'MetaTwo',  // Dev Name
                            true,   // Active
                            'strk__Site__c', //Object Type
                            'strk__Project__c', // Project Object
                            'strk__Project_Status__c', // Project Status Field
                            '',  // Project Status
                            'toaddresses', // Alt Search Field
                            'toaddresses',  // Search Field
                            'strk__Site__c',    // Site Object
                            'strk__Site__r.strk__Site_Status__c',     // Site Status Field
                            'Complete',     // Ignore statuses
                            true );    // use Site Status

        Email_To_Object_Setting__mdt mConfig3 = EmailToProjectService_Test.getMockMetaRecord(
                            'MetaThree',  // Dev Name
                            true,   // Active
                            'strk__Project__c', //Object Type
                            'strk__Project__c', // Project Object
                            'strk__Project_Status__c', // Project Status Field
                            '',  // Project Status
                            'toaddresses', // Alt Search Field
                            'toaddresses',  // Search Field
                            'strk__Site__c',    // Site Object
                            'strk__Site_Status__c',     // Site Status Field
                            'Complete',     // Ignore statuses
                            false );    // use Site Status

        Email_To_Object_Setting__mdt mConfig4 = EmailToProjectService_Test.getMockMetaRecord(
                            'MetaFour',  // Dev Name
                            true,   // Active
                            'strk__Project__c', //Object Type
                            'strk__Project__c', // Project Object
                            'strk__Project_Status__c', // Project Status Field
                            '',  // Project Status
                            'subject', // Alt Search Field
                            'subject',  // Search Field
                            'strk__Site__c',    // Site Object
                            'strk__Site__r.strk__Site_Status__c',     // Site Status Field
                            'Complete;Cancelled',     // Ignore statuses
                            true );    // use Site Status

        System.debug( 'config 1: ' + mConfig1 );
        System.debug( 'config 2: ' + mConfig2 );
        System.debug( 'config 3: ' + mConfig3 );
        System.debug( 'config 4: ' + mConfig4 );

        Messaging.InboundEmail inbEmail = new Messaging.InboundEmail();
        inbEmail.fromAddress = 'test1@testemail.com';
        inbEmail.toAddresses = new List<String>{ projects[ 0 ].Name };
        inbEmail.subject = 'Test This record';


        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = projects[ 0 ].Name;
        env.fromAddress = 'testEmail@testemail.com';


        EmailToProjectService service = new EmailToProjectService();

        SObject mResult1 = service.getRecordValue( mConfig1, projects[ 0 ].Name );
        //System.assertNotEquals( null, mResult1 );
        //System.assertEquals( projects[ 0 ].Id, mResult1.Id );

        SObject mResult2 = service.getRecordValue( mConfig2, projects[ 0 ].Name );
        //System.assertNotEquals( null, mResult2 );
        //System.assertEquals( projects[ 0 ].Id, mResult2.Id );


        String mResult3 = service.getObjectId( mConfig3, inbEmail );
        System.assertEquals( projects[ 0 ].Name, mResult3 );


        inbEmail = new Messaging.InboundEmail();
        inbEmail.Subject = projects[ 0 ].Name + ' project email';
        inbEmail.ccAddresses = new List<String>{ 'stTestemail@email.com' };


        String mResult4 = service.getObjectId( mConfig4, inbEmail );
        System.assertEquals( projects[ 0 ].Name, mResult4 );

    }

    static Email_To_Object_Setting__mdt getMockMetaRecord( String devName,
                                    Boolean active,
                                    String objectType,
                                    String projObject,
                                    String projStatusField,
                                    String projStats,
                                    String altSrchField,
                                    String srchField,
                                    String siteObject,
                                    String siteStatField,
                                    String ignoreStats,
                                    Boolean useSiteStatus ){

        String mock ='{ "DeveloperName" : "' +  devName + '",'
                + '"Active__c" : ' +  active + ', '
                + '"Object_Type__c" : "' +  objectType + '",'
                + '"Project_Object__c" : "' +  projObject + '", '
                + '"Project_Status_Field__c" : "' +  projStatusField + '", '
                + '"Alt_Search_Field__c" : "' +  altSrchField + '", '
                + '"Search_Field__c" : "' +  srchField + '", '
                + '"Site_Object__c" : "' + siteObject + '", '
                + '"Site_Status_Field__c" : "' + siteStatField + '", '
            	+ '"Statuses_To_Ignore__c" : "' + ignoreStats + '", '
                + '"Use_Site_Status_Field__c" : ' +  useSiteStatus
                + '}';
        System.debug( 'Mock: ' + mock );

        return ( Email_To_Object_Setting__mdt )JSON.deserialize( mock, Email_To_Object_Setting__mdt.class );
    }
}