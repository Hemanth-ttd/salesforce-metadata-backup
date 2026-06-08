@IsTest
private class ProjectExtensionTest {

    @IsTest
    static void testmethod1() {
        Sobject newTemplate = Schema.getGlobalDescribe().get('strk__Project_Template__c').newSObject();
        newTemplate.put('Name', 'Test Template');
        newTemplate.put('strk__Active__c', True);
        newTemplate.put('strk__SiteTraker_Object__c', 'strk__Project__c');
        insert newTemplate;
        Sobject site = Schema.getGlobalDescribe().get('strk__Site__c').newSObject();
        site.put('Name', 'Test Site');
        site.put('Site_ID__c','test side id');
        insert site;
        Sobject project = Schema.getGlobalDescribe().get('strk__Project__c').newSObject();
        project.put('strk__Site__c', site.id);
        project.put('strk__ProjectTemplate__c', newTemplate.get('Id'));
        project.put('strk__Project_Template__c', newTemplate.get('Name'));
        project.put('strk__Project_Type__c', 'Test Template');
        insert project;
        SObject sObj = Schema.getGlobalDescribe().get('Project_Extension__c').newSObject();
        Sobj.put('Project__c', project.get('Id'));
        insert sObj;
        system.assert(sObj.id != null);
        sObj.put('Name', 'hello');
        update sObj;
        SObject sObj1 = Schema.getGlobalDescribe().get('Project_Extension__c').newSObject();
        Sobj1.put('Project__c', project.get('Id'));
        Boolean errorFound = false;
        errorFound = false;
        try {
            Sobj1.put('Name', 'ADfadbfakndbfaldkfbadkfnbakdfbakfjbakDFJBadkfjbadADfadbfakndbfaldkfbadkfnbakdfbakfjbakDFJBadkfjbadADfadbfakndbfaldkfbadkfnbakdfbakfjbakDFJBadkfjbadADfadbfakndbfaldkfbadkfnbakdfbakfjbakDFJBadkfjbadADfadbfakndbfaldkfbadkfnbakdfbakfjbakDFJBadkfjbad');
            insert Sobj1;
        }catch (Exception ex) {
            errorFound = true;
        }
        System.assertEquals(true, errorFound, 'No Error in inserting project extension');
        delete sObj;
    }
}