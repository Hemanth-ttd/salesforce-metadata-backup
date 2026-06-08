@isTest
private class efs_Project_EgnyteTest
{
    static testMethod void mytestmethod()
    {
       strk__Project_Template__c projectTemplate = new strk__Project_Template__c();
        projectTemplate.strk__Active__c = true;
       insert projectTemplate;
        
        strk__Site__c site = new strk__Site__c();
       insert site;
        
        test.startTest();
        strk__Project__c project = new strk__Project__c();
       project.strk__ProjectTemplate__c = projectTemplate.Id;
        project.strk__Site__c = site.Id;
       project.strk__Project_Type__c = 'Build to Suit (BTS)';
        insert project;
       test.stopTest();
    }
   
}