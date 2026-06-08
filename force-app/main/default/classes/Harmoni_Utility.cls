/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2023 SITETRACKER, INC., All Rights Reserved.
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
 * @description Utility class for the org
 * @author <A HREF="mailto:vsaran@sitetracker.com">Vartika Saran</A>
 *
***************************************************************************************************/
global class Harmoni_Utility {
    /**
    * Create the Error Report Record
    *
    * @param createdById Id of the User
    * @param Message Message
    * @param trace Trace String
    * @param Name Name of the class
    * @param severity Severity
    */
    public static strk__Error_Report__c insertErrorReport(
        Id createdById,
        String Message,
        String trace,
        String Name,
        String severity,
        Boolean isInsert
    ) {
        strk__Error_Report__c report = new strk__Error_Report__c(
            strk__User__c = createdById,
            strk__Message__c = Message,
            strk__Stack_Trace__c = trace,
            Name = Name,
            strk__Severity__c = severity
        );

        if (isInsert) {
            insert report;
        }

        return report;
    }

    /**
     * @description Utility method to create Email Message instance
     * @param emailTemplateId The Email template Id
     * @param saveAsActivity True if we need to save email as an activity on record
     * @param targetObjectId The Target Object Id
     * @param whatId The What Id
     * @param recipientEmails Set of Recipient Email Addresses
     *
     * @return email
     */
    public static Messaging.SingleEmailMessage createEmailMessage(
            Id emailTemplateId,
            Boolean saveAsActivity,
            Id targetObjectId,
            Id whatId,
            Set<String> recipientEmails){

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setTemplateId(emailTemplateId);
        email.saveAsActivity = saveAsActivity;
        email.targetObjectId = targetObjectId;
        email.whatId = whatId;
        email.setToAddresses(new List<String>(recipientEmails));

        return email;
    }
}