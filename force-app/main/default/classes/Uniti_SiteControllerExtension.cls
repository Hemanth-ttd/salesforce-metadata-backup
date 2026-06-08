/***********************************************************************************************
 *  Copyright (c) 2016 SiteTraker
 *   This code is the sole property of SiteTraker and may not be distributed
 *   or modified without prior written consent from an authorized representative
 *   from SiteTraker.
 *   All rights reserved.
 *
 *   This class is the site controller extension
 *
 *  @author <A HREF="mailto:tmay@sitetraker.com">Tim May</A>
 *  @version $Revision: 1.0 $ $Date: 2014-09-19 $
 *  Revision History
 *  Version 1.0 - Initial Version
 *
 ************************************************************************************************/

global with sharing class Uniti_SiteControllerExtension {

    global Boolean createProject {get; set;}
    global List<SelectOption> projectTypes {get; set;}
    global List<SelectOption> siteTypes {get; set;}
    global String selectedType {get; set;}
    global strk__Site__c newSite {get; set;}
    global strk__Project__c newProject {get; set;}
    global String siteName {get; set;}
    global String siteType {get; set;}
    ApexPages.StandardController stdController;

    global Uniti_SiteControllerExtension () {}

    global Uniti_SiteControllerExtension (ApexPages.StandardController stdController) {
        newSite = new strk__Site__c();
        newProject = new strk__Project__c();
        //projectTypes = getProjectTypes();
        //siteTypes = getSiteTypes ();
        this.stdController = stdController;
    }

    global PageReference setProjectType() {
        //selectedType = siteType;
        return null;
    }

    global PageReference createSite() {

        try {
            if (String.isBlank(siteName)) {
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter a site name.');
                ApexPages.addMessage(errMsg);
                return null;
            } 
            else {
                if (strk__Site__c.sObjectType.getDescribe().isCreateable()) {
                    newSite.Name = siteName;
                    //newSite.Site_Type__c = siteType;
                    insert newSite;
                } else {
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'You do not have permission to create new Sites.');
                    ApexPages.addMessage(errMsg);
                    return null;
                }
            }

            if (createProject) {
                if (strk__Project__c.sObjectType.getDescribe().isCreateable()) {
                    //newProject.Project_Type__c = selectedType;
                    newProject.strk__Site__c = newSite.ID;
                    insert newProject;
                } 
                else {
                    ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'You do not have permission to create new Projects.');
                    ApexPages.addMessage(errMsg);
                    return null;
                }
            }

            return new PageReference('/' + newSite.ID);

        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;

    }    

    global PageReference saveExtended() {
        return stdController.save();
    }


/*    global List<SelectOption> getSiteTypes() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = strk__Site__c.Site_Type__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for ( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    global List<SelectOption> getProjectTypes() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = strk__Project__c.Project_Type__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for ( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }*/

}