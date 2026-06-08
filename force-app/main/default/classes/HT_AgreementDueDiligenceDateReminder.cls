/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2024 SITETRACKER, INC., All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of Sitetracker.
 * The intellectual and technical concepts contained herein are proprietary to Sitetracker and
 * may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Sitetracker. Access to the source code contained
 * herein is hereby forbidden to anyone except current Sitetracker employees, managers or
 * contractors who have executed Confidentiality and Non-disclosure agreements explicitly
 * covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure
 * of this source code, which includes information that is confidential and/or proprietary, and
 * is a trade secret, of Sitetracker.
 *
 * @description HT_AgreementDueDiligenceDateReminder
 *
 * @author <A HREF="mailto:sjain@sitetracker.com">Shubham Jain</A>
 *
 ***************************************************************************************************/

global class HT_AgreementDueDiligenceDateReminder implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    @TestVisible
    public List<Email_Alert_Settings__mdt> alertSettings { get; set; }
    Map<Date, Email_Alert_Settings__mdt> emailAlertSettingsByDates = new Map<Date, Email_Alert_Settings__mdt>();

    /**
     * HT_AgreementDueDiligenceDateReminder Constructor
     */
    global HT_AgreementDueDiligenceDateReminder() {

        alertSettings = new List<Email_Alert_Settings__mdt>();

        if (alertSettings.isEmpty()) {
            // Fetch the active email alert settings from the CMT
            List<Email_Alert_Settings__mdt> alertSettingsGet = Email_Alert_Settings__mdt.getAll().values();

            for (Email_Alert_Settings__mdt emailAlertSettings : alertSettingsGet) {
                if (emailAlertSettings.Is_Active__c) {
                    alertSettings.add(emailAlertSettings);
                }
            }
        }

        //Populate a map of the target date and the email alert setting cmt record
        if (!alertSettings.isEmpty()) {
            for (Email_Alert_Settings__mdt setting : alertSettings) {
                Date targetDate = Date.today().addDays((Integer.valueOf(setting.Reminder_Alert_Days__c)));
                emailAlertSettingsByDates.put(targetDate, setting);
            }
        }

    }

    global Database.QueryLocator start(Database.BatchableContext context) {

        // Prepare a set to collect all required Project fields
        Set<String> projectFields = new Set<String>{
                'Id'
        };

        // Collect all unique project recipient fields from alert settings
        for (Email_Alert_Settings__mdt setting : alertSettings) {
            if (setting.Project_Recipient_Fields__c != null) {
                List<String> fields = setting.Project_Recipient_Fields__c.split(',');
                //Email alert setting Project_Recipient_Fields__c will contain User lookup field on the project record
                for (String field : fields) {
                    projectFields.add(field.trim().removeEnd('__c') + '__r.Email');
                }
            }
        }

        // Build the SOQL query dynamically with a filter for Due Diligence Date
        String query = 'SELECT Id, DD_Option_Current_Expiration_Date__c , Project__c';
        if (!projectFields.isEmpty()) {
            query += ', Project__r.' + String.join(new List<String>(projectFields), ', Project__r.');
        }

        //Add condition to filter records which are eligible for reminders
        query += ' FROM Agreement__c WHERE Eligible_for_Reminder__c = TRUE';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<Agreement__c> agreementList) {

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        //Fetch Re Admin email address
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE LastName = 'Admin Notification Contact' LIMIT 1];

        if (!contacts.isEmpty()) {
            for (Agreement__c agreement : agreementList) {

                if (emailAlertSettingsByDates.containsKey(agreement.DD_Option_Current_Expiration_Date__c)) {

                    //Get email alert setting from the map
                    Email_Alert_Settings__mdt setting = emailAlertSettingsByDates.get(agreement.DD_Option_Current_Expiration_Date__c);

                    // Retrieve email template
                    EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :setting.Email_Template_API_Name__c LIMIT 1];

                    // Collect recipient emails
                    Set<String> recipientEmails = new Set<String>();

                    // Add additional recipient emails
                    if (setting.Additional_Recipient_Email_Addresses__c != null) {
                        List<String> additionalEmails = setting.Additional_Recipient_Email_Addresses__c.split(',');
                        for (String emailAddr : additionalEmails) {
                            recipientEmails.add(emailAddr.trim());
                        }
                    }

                    // Add project recipient emails based on lookup fields
                    if (setting.Project_Recipient_Fields__c != null && agreement.Project__r != null) {

                        List<String> recipientFields = setting.Project_Recipient_Fields__c.split(',');

                        for (String field : recipientFields) {
                            String relationshipName = (field.removeEnd('__c') + '__r').trim();
                            if (agreement.Project__r.getSObject(relationshipName) != null) {
                                SObject user = agreement.Project__r.getSObject(relationshipName);
                                if (user != null) {  // Check if the lookup field actually has a record
                                    String userEmail = (String) user.get('Email');
                                    if (userEmail != null) {  // Ensure the email field is not null and not empty
                                        recipientEmails.add(userEmail);
                                    }
                                }
                            }

                        }
                    }

                    // Set recipients if any exist
                    if (!recipientEmails.isEmpty() && template != null) {
                        Messaging.SingleEmailMessage emailMessage =
                                Harmoni_Utility.createEmailMessage(template.Id,
                                        false,
                                        contacts[0].Id,
                                        agreement.Id,
                                        recipientEmails);
                        emailsToSend.add(emailMessage);
                    }
                }
            }
        }

        if (!emailsToSend.isEmpty()) {
            //Send email notification
            Messaging.sendEmail(emailsToSend);
        }
    }

    global void finish(Database.BatchableContext context) {
    }

    global void execute(SchedulableContext context) {
        Database.executeBatch(new HT_AgreementDueDiligenceDateReminder(), 100);
    }
}