public with sharing class FormController {

    public strk__Project__c project {get; set;}
    public strk__Activity__c activity {get; set;}
    public strk__Site__c site {get; set;}
    public ApexPages.StandardController stdController {get; set;}
    public Boolean hasFiles {get;set;}

    public FormController (ApexPages.StandardController stdController ) {

        this.stdController = stdController;
        project = (strk__Project__c)stdController.getRecord();
        string siteId = project.strk__Site__c;
        site = [SELECT id,
                    name,
                    Survey_Lattitude_Dec__c,
                    Survey_Longitude_Dec__c,
                    Survey_Lattitude_NAD_83__c,
                    Survey_Longitude_NAD_83__c,
                    Ground_Elevation__c,
                    strk__Street_Address__c,
                    strk__City__c,
                    strk__State__c,
                    strk__Zip_Code__c,
                    strk__County__c,
                    Country__c,
                    FAA_Study_Number__c,
                    FAA_LAT_DMS__c,
                    FAA_LOG_DMS__c,
                    FAA_Ground_Elevation__c,
                    FAA_Expiration__c,
                    Structure_Height__c,
                    Overall_Structure_Height__c,
                    Lighting_Type__c,
                    FAA_Required_Paint__c,
                    ASR_Number__c,
                    Structure_Manufacturer__c,
                    Account_number__c,
                    Lighting_System_Manufacturer__c,
                    Tower_Type__c,
                    Structure_Type__c,
                    ICCID_ENC__c,
                    Meter_Number__c,
                    Power_Company_Name__c,
                    Power_Company_Contact_Number__c,
                    Controller_Static_IP_ENC__c,
                    Controller_Port_ENC__c,
                    Alarm_User_Name_ENC__c,
                    Alarm_Password_ENC__c,
                    Alarm_Static_IP_ENC__c,
                    Alarm_Port_ENC__c,
                    Modem_Number_ENC__c,
                    Modem_Password_ENC__c,
                    Modem_User_Name_ENC__c,
                    Modem_IP_ENC__c,
                    IMIE_ENC__c,
                    Gateway_ENC__c,
                    Local_Law_Enforcement_Number__c,
                    Local_Law_Enforcement_Address__c,
                    Local_Fire_Number__c,
                    Local_Fire_Address__c,
                    Nearest_Hospital_Number__c,
                    Nearest_Hospital_Address__c,
                    Directions_to_Hospital__c,
                    Primary_Ops_Contact_Name__c,
                    Primary_Ops_Contact_Number__c,
                    Secondary_Ops_Contact_Name__c,
                    Site_Access_Contact_Name__c,
                    Site_Access_Contact_Number__c,
                    Special_Access_Instructions__c,
                    Fence_Lock_Code_ENC__c,
                    Fence_Lock_Code_New__c,
                    Directions_to_site__c

                    FROM strk__Site__c
                    WHERE id =: siteId LIMIT 1];
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
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;

    }


}