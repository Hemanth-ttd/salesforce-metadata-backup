public with sharing class LATAM_FormController {

    public strk__Project__c project {get; set;}
    public strk__Activity__c activity {get; set;}
    public strk__Site__c site {get; set;}
    public LATAM__c latam {get; set;}
    public ApexPages.StandardController stdController {get; set;}
    public Boolean hasFiles {get;set;}

    public LATAM_FormController (ApexPages.StandardController stdController ) {

        this.stdController = stdController;
        project = (strk__Project__c)stdController.getRecord();
        string siteId = project.strk__Site__c;
        site = [SELECT id,
                    name,
                    Latitude_Hemisphere__c,
                    Longitude_Hemisphere__c,
                    GPS_System__c,
                    Country__c,
                    Region__c,
                    strk__Site_Status__c,
                    Anchor_Tenant__c,
                    Anchor_Tower_Name__c,
                    Anchor_Tower_Number__c,
                    Portfolio_MLA_Type__c,
                    Directions_to_site__c,
                    strk__City__c,
                    strk__State__c,
                    strk__County__c,
                    strk__Zip_Code__c,
                    strk__Site_Type__c,
                    Structure_Type__c,
                    Structure_Height__c,
                    Building_Height__c,
                    Overall_Structure_Height__c,
                    Measurement_Unit__c,
                    Coordinates_Verified__c,
                    Coordinates_Verified_By_Contact__c,
                    Foundation_Type__c,
                    Terrain_Type__c,
                    Topographic_Factor__c,
                    Tower_Wind_Load__c,
                    Structure_Manufacturer__c,
                    Land_Use_License__c,
                    Construction_License__c,
                    DGAC_License__c,
                    Access_Comments__c,
                    Access_Type__c,
                    Fence_Lock_Code_ENC__c,
                    Key_Location__c,
                    Combination_Date__c,
                    Special_Access_Instructions__c

                    FROM strk__Site__c
                    WHERE id =: siteId LIMIT 1];

        latam = [SELECT id,
                name,
                Project__c,
                Alineamiento_y_No_Oficial__c

                FROM LATAM__c
                WHERE Project__c =: project.id LIMIT 1];

        String activityId = ApexPages.currentPage().getParameters().get('actId');
        activity = [SELECT id, name, strk__Activity_Template__r.strk__Project_Milestone__c
                        FROM strk__Activity__c
                        WHERE id=: activityId LIMIT 1];

        List<ContentDocumentLink> cdl2 = [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId =: activity.Id];
        List<strk__Activity__c> parent_activity = [SELECT Id FROM strk__Activity__c WHERE strk__Activity_Template__r.strk__Project_Milestone__c =: activity.strk__Activity_Template__r.strk__Project_Milestone__c AND strk__Activity_Template__r.strk__Document_Uploads__c = 'Require Document Upload to Actualize'];

        System.debug('parent_activity: '+parent_activity);
        System.debug('cdl2: '+cdl2);

        if(cdl2 != null && cdl2.size() > 0) {

            hasFiles = false;

        } else {
            if(parent_activity != null && parent_activity.size() > 0) {
                    hasFiles = true;
            } else {
                hasFiles = false;
            }
        }
    }

    public PageReference saveAndCloseForm() {
        try {
            //Save parent objects, if found
            PageReference pr = stdController.save();
            update activity;
            update site;
            update latam;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference saveAndCompleteForm() {
        try {
            PageReference pr = stdController.save();
            activity.strk__Form_Complete__c = true;
            activity.strk__ActualDate__c = System.Today();
            update activity;
            update site;
            update latam;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;

    }


}