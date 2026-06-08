/**
 * Created by RPayn on 4/24/2018.
 */

@IsTest
private class UpdateCommentField_Test {

    @TestSetup
    static void setupTestData(){
        strk__Project_Template__c template = new strk__Project_Template__c(
            Name = 'Test class template',
            strk__SiteTraker_Object__c = 'strk__Project__c'
        );

        try{
            Database.insert( template );
        }
        catch( Exception ex ){
            System.debug( 'Error inserting test template: ' + ex.getMessage() );
        }

        strk__Site__c site = new strk__Site__c(
            Name = 'Test class site 1',
            Site_ID__c = '123456',
            Transformer_Comments__c = 'Original'
        );

        try{
            Database.insert( site );
        }
        catch( Exception ex ){
            System.debug( 'Error inserting test site: ' + ex.getMessage() );
        }

        /* strk__Project__c project = new strk__Project__c(
             strk__Site__c = site.Id,
             strk__Site__r = site,
             strk__ProjectTemplate__c = template.Id,
             Closeouts_complete_A__c = Date.newInstance(1900, 1, 1)
         );*/

        /*try{
            Database.insert( project );
        }
        catch( Exception ex ){
            System.debug( 'Error inserting test project: ' + ex.getMessage() );
        }*/
    }

    static testMethod void TestCommentsUpdateToHistory(){
        //List<strk__Project__c> projects = [ SELECT Id, Name, strk__Project_Comments__c, strk__Project_Comments_History__c FROM strk__Project__c ];
        List<strk__Site__c> sites = [ SELECT Id, Name, Transformer_Comments__c, Transformer_Comments_history__c FROM strk__Site__c ];
        System.assertEquals( 1, sites.size() );
        strk__Site__c oldProject = sites[ 0 ];
        strk__Site__c newProject = sites[ 0 ];

        newProject.Transformer_Comments__c = 'Test project comments 1234';

        Database.update( newProject );

        strk__Site__c site = new strk__Site__c(
            Name = 'Test class site 1',
            Site_ID__c = '123456',
            Transformer_Comments__c = 'totally new comment'
        );
        
        UpdateCommentField.updateCommentField( oldProject, site, 'strk__Site__c' );

    }
}