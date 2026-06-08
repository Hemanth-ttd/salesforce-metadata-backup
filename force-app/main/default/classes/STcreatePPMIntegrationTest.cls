@istest
public class STcreatePPMIntegrationTest {
    @TestSetup
    static void setup(){
        // insert Project Template
        strk__project_Template__c template = new strk__project_Template__c(
            strk__Active__c = true,
            Name = 'US Development - AT&T'
        );
        insert template;

        // insert Site
        strk__site__c site = new strk__site__c(
            Name = 'Test Site',
            Site_ID__c = (String.valueOf(Math.random())).substring(0, 17),
            strk__County__c = 'test county',
            Source__c = 'Uniti - AT&T Anchor',
            Country__c = 'United States',
            strk__Street_Address__c = '1016 South Garland Road',
            strk__City__c = 'Enid'
        );
        insert site;
    }

    @isTest
    static void testProject(){
        // create fake body
        string body = '[ "Project", {"Construction_complete_A__c" : "","SubType_2__c" : "", "strk__County__c" : "","Budget_Cost__c" : "100.00","strk__Project_Status__c" : "",';
                body += '"Project_Name__c" : "Test Multiple 9","strk__Project_Type__c" : "","Reason_Code__c" : "","SubType_1_Alt__c" : "","Funding__c" : "CAP","Source__c" : "Uniti - AT&T Anchor",';
                body += '"strk__Customer__c" : "","Id" : "a0K0U000002LQGkUAO","Integration_State__c" : "OK","strk__Project_Template__c" : "","Country__c" : "United States","Site_ID_Formula__c" : "OKL01474",';
                body += '"SubType_1__c" : "","Justification__c" : "Test Justification","strk__Project_Start_Date_F__c" : "2018-11-06 00:00:00","SBO_received__c" : "","Integration_Project_Name__c" : "OKL01474_Garland Enid_Test Multiple 9",';
                body += '"Site_Name" : "Garland Enid","strk__Street_Address__c" : "1016 South Garland Road","strk__City__c" : "Enid","Category__c" : "Operations","Name" : "P-001992"}]';

        // instantiate HttpMock with fake response
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',body,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);

        strk__project_Template__c template = [SELECT Id FROM strk__project_Template__c LIMIT 1];
        strk__site__c site = [SELECT Id FROM strk__site__c LIMIT 1];

        // insert projects
        List<Strk__Project__c> lst = new List<strk__Project__c>();

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
        lst.add(proj1);

        Strk__Project__c proj2 = new Strk__Project__c();
        proj2.strk__site__c = site.id;
        proj2.strk__ProjectTemplate__c = template.id;
        proj2.strk__Project_Start_Date_F__c = Date.today();
        proj2.strk__Project_Complete_F__c = Date.today() + 10;
        proj2.Project_Name__c = 'Test Multiple 33';
        proj2.Budget_Cost__c = 100;
        proj2.Justification__c = 'Test Justification';
        proj2.Funding__c = 'CAP';
        proj2.Category__c = 'Operations';
        proj2.strk__Project_Type__c = 'ABM';
        lst.add(proj2);
        insert lst;

        //Need to dynamically query fields so that adding/removing metadata won't break it
        String query = 'SELECT Id';
        for(Oracle_PPM_Mapping__mdt cmt:
           [SELECT id,DeveloperName,Active__c,Is_Update__c,Field_API_Name__c,Object_API_Name__c FROM Oracle_PPM_Mapping__mdt
             WHERE Active__c = true AND Field_API_Name__c != NULL]){
            if (!cmt.Field_API_Name__c.equalsIgnoreCase('id')){
                query += ',' + cmt.Field_API_Name__c;
            }
        }
        query += ' FROM strk__Project__c';
        SYstem.debug('query = ' + query);
        List<Strk__Project__c> oldLst = Database.query(query);
        System.debug('oldLst = ' + oldLst);

        Map<Id,Strk__project__c> oldMap = new Map<Id,strk__project__c>();

        for(Strk__project__c rec: oldLst){
            oldMap.put(rec.Id,rec);
            rec.Budget_Cost__c = 180;
        }
        update oldLst;

        Test.startTest();
        STcreatePPMIntegration t1 = new STcreatePPMIntegration(oldLst, oldLst.get(0));
        STcreatePPMIntegration t2 = new STcreatePPMIntegration(oldLst, oldMap, oldLst.get(0));
        String json1 = t1.json2Send;
        String json2 = t2.json2Send;
        Test.stopTest();

        System.enqueueJob(t1);
        System.enqueueJob(t2);

        System.assertNotEquals(STcreatePPMIntegration.EMPTY, json1);
        System.assert(json1.containsIgnoreCase('projectnumber'));
        //Should be empty if no changes were made.
        System.assertEquals(STcreatePPMIntegration.EMPTY, json2);
    }

    @isTest
    static void testFailedProject(){
        strk__project_Template__c template = [SELECT Id FROM strk__project_Template__c LIMIT 1];
        strk__site__c site = [SELECT Id FROM strk__site__c LIMIT 1];

        // insert projects
        List<Strk__Project__c> lst = new List<strk__Project__c>();

        Strk__Project__c proj1 = new Strk__Project__c();
        proj1.strk__site__c = site.id;
        proj1.strk__ProjectTemplate__c = template.id;
        proj1.strk__Project_Start_Date_F__c = Date.today();
        proj1.strk__Project_Complete_F__c = Date.today() + 10;
        proj1.Project_Name__c = 'Test Multiple 32';
        proj1.Budget_Cost__c = 100;
        proj1.Justification__c = 'Test Justification';
        proj1.Funding__c = 'CAP';
        proj1.strk__Project_Type__c = 'ABM';
        lst.add(proj1);

        Strk__Project__c proj2 = new Strk__Project__c();
        proj2.strk__site__c = site.id;
        proj2.strk__ProjectTemplate__c = template.id;
        proj2.strk__Project_Start_Date_F__c = Date.today();
        proj2.strk__Project_Complete_F__c = Date.today() + 10;
        proj2.Project_Name__c = 'Test Multiple 33';
        proj2.Budget_Cost__c = 100;
        proj2.Justification__c = 'Test Justification';
        proj2.Funding__c = 'CAP';
        proj2.Category__c = 'Operations';
        proj2.strk__Project_Type__c = 'ABM';
        lst.add(proj2);

        insert lst;

        //Need to dynamically query fields so that adding/removing metadata won't break it
        String query = 'SELECT Id';
        for(Oracle_PPM_Mapping__mdt cmt: [SELECT id,DeveloperName,Active__c,Is_Update__c,Field_API_Name__c,Object_API_Name__c FROM Oracle_PPM_Mapping__mdt WHERE Active__c = TRUE AND Field_API_Name__c != NULL]){
            if (!cmt.Field_API_Name__c.equalsIgnoreCase('id')){
                query += ',' + cmt.Field_API_Name__c;
            }
        }
        query += ' FROM strk__Project__c';
        List<Strk__Project__c> oldLst = Database.query(query);

        list<Strk__Project__c> updLst = new List<Strk__Project__c>();
        Map<Id,Strk__project__c> oldMap = new Map<Id,strk__project__c>();

        for(Strk__project__c rec: oldLst){
            oldMap.put(rec.Id,rec);
        }
        for(strk__project__c proj: oldLst){
            proj.Budget_Cost__c = 180;
            updLst.add(proj);
        }
        update updLst;

        Test.startTest();
        try{
            STcreatePPMIntegration t1 = new STcreatePPMIntegration(lst, lst.get(0));
            System.assert(false, 'Should have errored out because of missing required field.');
        } catch (Exception e){
            //We are expected to error here because of missing required fields.
        }
        Test.stopTest();
    }

    @isTest
    static void testSite(){
        // create fake body
        string body = '[ "Project", {"Construction_complete_A__c" : "","SubType_2__c" : "", "strk__County__c" : "","Budget_Cost__c" : "100.00","strk__Project_Status__c" : "",';
                body += '"Project_Name__c" : "Test Multiple 9","strk__Project_Type__c" : "","Reason_Code__c" : "","SubType_1_Alt__c" : "","Funding__c" : "CAP","Source__c" : "Uniti - AT&T Anchor",';
                body += '"strk__Customer__c" : "","Id" : "a0K0U000002LQGkUAO","Integration_State__c" : "OK","strk__Project_Template__c" : "","Country__c" : "United States","Site_ID_Formula__c" : "OKL01474",';
                body += '"SubType_1__c" : "","Justification__c" : "Test Justification","strk__Project_Start_Date_F__c" : "2018-11-06 00:00:00","SBO_received__c" : "","Integration_Project_Name__c" : "OKL01474_Garland Enid_Test Multiple 9",';
                body += '"Site_Name" : "Garland Enid","strk__Street_Address__c" : "1016 South Garland Road","strk__City__c" : "Enid","Category__c" : "Operations","Name" : "P-001992"}]';

        // instantiate HttpMock with fake response
        STcreatePPMIntegrationMockTest fakeresp = new STcreatePPMIntegrationMockTest(200,'Complete',body,null);
        Test.setMock(HttpCalloutMock.class, fakeresp);

        strk__project_Template__c template = [SELECT Id FROM strk__project_Template__c LIMIT 1];
        strk__site__c site = [SELECT Id FROM strk__site__c LIMIT 1];

        // insert projects
        List<Strk__Project__c> lst = new List<strk__Project__c>();

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
        lst.add(proj1);

        Strk__Project__c proj2 = new Strk__Project__c();
        proj2.strk__site__c = site.id;
        proj2.strk__ProjectTemplate__c = template.id;
        proj2.strk__Project_Start_Date_F__c = Date.today();
        proj2.strk__Project_Complete_F__c = Date.today() + 10;
        proj2.Project_Name__c = 'Test Multiple 33';
        proj2.Budget_Cost__c = 100;
        proj2.Justification__c = 'Test Justification';
        proj2.Funding__c = 'CAP';
        proj2.Category__c = 'Operations';
        proj2.strk__Project_Type__c = 'ABM';
        lst.add(proj2);
        insert lst;

        //Need to dynamically query fields so that adding/removing metadata won't break it
        String query = 'SELECT Id';
        for(Oracle_PPM_Mapping__mdt cmt: [SELECT id,DeveloperName,Active__c,Is_Update__c,Field_API_Name__c,Object_API_Name__c FROM Oracle_PPM_Mapping__mdt WHERE Active__c = true AND Field_API_Name__c != null]){
            if (cmt.Field_API_Name__c.contains('__r')){
                if(!cmt.Field_API_Name__c.contains('strk__Project_Manager__r.')){
                    query += ',' + cmt.Field_API_Name__c.split('\\.')[1];
                }
            }
        }
        query += ' FROM strk__Site__c';
        List<strk__site__c> oldLst = Database.query(query);

        list<strk__site__c> updLst = new List<strk__site__c>();
        Map<Id, strk__site__c> oldMap = new Map<Id, strk__site__c>();

        for(strk__site__c rec: oldLst){
            oldMap.put(rec.Id, rec);
            site.strk__City__c = 'NY';
            updLst.add(site);
        }
        update updLst;

        Test.startTest();
        STcreatePPMIntegration t2 = new STcreatePPMIntegration(updLst, oldMap, updLst.get(0));
        String json2 = t2.json2Send;
        Test.stopTest();

        System.enqueueJob(t2);

        //Should be sending info for each related project
        System.assert(json2.containsIgnoreCase('ProjectId'));
    }
}