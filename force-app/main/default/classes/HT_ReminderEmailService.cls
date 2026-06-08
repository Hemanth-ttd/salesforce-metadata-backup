/**
 * ReminderEmailService
 * Resolves recipients from all configured sources (FIELD, RELATED_FIELD, STATIC)
 * and sends reminder emails using the configured EmailTemplate.
 *
 * Called by ReminderEventTriggerHandler with a batch of platform event payloads.
 *
 * Design:
 *  - One SOQL per SObject type to re-query records with all recipient fields
 *  - One SOQL to load the EmailTemplate (cached across calls in the same transaction)
 *  - Messaging.sendEmail called once per batch (up to 10 messages per governor limit chunk)
 *  - User/Contact email addresses resolved via a single User query
 */
public class HT_ReminderEmailService {

    // EmailTemplate cache: templateApiName → Id (valid within one transaction)
    private static Map<String, Id> templateIdCache = new Map<String, Id>();

    // User/Contact email cache: userId/contactId → email address
    private static Map<Id, String> userEmailCache = new Map<Id, String>();

    // ── Entry point ──────────────────────────────────────────────────────────

    /**
     * Processes a batch of platform event payloads.
     * Groups by config developer name to minimise SOQL queries.
     *
     * @param events  List of Reminder_Event__e records from the trigger
     */
    public static void processEvents(List<Reminder_Event__e> events) {
        if (events == null || events.isEmpty()) return;

        // Load all active configs into a map for quick lookup
        Map<String, HT_ReminderConfigLoader.ReminderConfig> configsByName =
            new Map<String, HT_ReminderConfigLoader.ReminderConfig>();
        for (HT_ReminderConfigLoader.ReminderConfig c : HT_ReminderConfigLoader.loadActiveConfigs()) {
            configsByName.put(c.developerName, c);
        }

        // Group events by config name
        Map<String, List<Reminder_Event__e>> eventsByConfig =
            new Map<String, List<Reminder_Event__e>>();
        for (Reminder_Event__e evt : events) {
            if (!eventsByConfig.containsKey(evt.Config_Developer_Name__c)) {
                eventsByConfig.put(evt.Config_Developer_Name__c, new List<Reminder_Event__e>());
            }
            eventsByConfig.get(evt.Config_Developer_Name__c).add(evt);
        }

        // Process each config group
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        for (String configName : eventsByConfig.keySet()) {
            HT_ReminderConfigLoader.ReminderConfig config = configsByName.get(configName);
            if (config == null) {
                System.debug(LoggingLevel.WARN,
                    'ReminderEmailService: No active config found for: ' + configName);
                continue;
            }

            List<Reminder_Event__e> configEvents = eventsByConfig.get(configName);
            List<Messaging.SingleEmailMessage> emails =
                buildEmailsForConfig(config, configEvents);
            allEmails.addAll(emails);
        }

        sendEmails(allEmails);
    }

    // ── Per-config email builder ─────────────────────────────────────────────

    private static List<Messaging.SingleEmailMessage> buildEmailsForConfig(
       HT_ReminderConfigLoader.ReminderConfig config,
        List<Reminder_Event__e> events
    ) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Collect record Ids from events
        Set<Id> recordIds = new Set<Id>();
        Map<String, Reminder_Event__e> eventByRecordId = new Map<String, Reminder_Event__e>();
        for (Reminder_Event__e evt : events) {
            if (!String.isBlank(evt.Record_Id__c)) {
                recordIds.add((Id) evt.Record_Id__c);
                eventByRecordId.put(evt.Record_Id__c, evt);
            }
        }

        if (recordIds.isEmpty()) return emails;

        // Re-query records with all recipient fields
        Map<Id, SObject> recordsById = queryRecords(config, recordIds);

        // Resolve template Id
        Id templateId = resolveTemplateId(config.emailTemplateApiName);
        if (templateId == null) {
            System.debug(LoggingLevel.ERROR,
                'ReminderEmailService: EmailTemplate not found: ' + config.emailTemplateApiName);
            return emails;
        }

        // Collect all user/contact Ids to batch-resolve emails
        Set<Id> userIdsToResolve = new Set<Id>();
        for (Id recordId : recordsById.keySet()) {
            SObject record = recordsById.get(recordId);
            userIdsToResolve.addAll(extractUserIds(config, record));
        }
        cacheUserEmails(userIdsToResolve);

        // Build one email per record
        for (Id recordId : recordsById.keySet()) {
            SObject record = recordsById.get(recordId);
            Set<String> toAddresses = resolveRecipientEmails(config, record);

            if (toAddresses.isEmpty()) {
                System.debug(LoggingLevel.WARN,
                    'ReminderEmailService: No recipients for record ' + recordId + ', skipping.');
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(templateId);
            email.setWhatId(recordId);  // merge fields resolved against this record
            email.setToAddresses(new List<String>(toAddresses));
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        return emails;
    }

    // ── Recipient resolution ─────────────────────────────────────────────────

    /**
     * Resolves all email addresses for a single record across all configured
     * recipient sources: FIELD, RELATED_FIELD, STATIC.
     */
    private static Set<String> resolveRecipientEmails(
        HT_ReminderConfigLoader.ReminderConfig config,
        SObject record
    ) {
        Set<String> emails = new Set<String>();

        // ── FIELD: direct lookup fields on the record (e.g. OwnerId) ─────────
        if (config.usesFieldRecipients()) {
            for (String fieldName : config.recipientFieldApiNames) {
                Object val = safeGet(record, fieldName);
                if (val != null) {
                    String email = userEmailCache.get((Id) val);
                    if (!String.isBlank(email)) emails.add(email);
                }
            }
        }

        // ── RELATED_FIELD: dot-notation traversal (e.g. Account.OwnerId) ─────
        if (config.usesRelatedFieldRecipients()) {
            for (String path : config.recipientRelatedFieldPaths) {
                Object val = traverseRelationship(record, path);
                if (val instanceof Id) {
                    String email = userEmailCache.get((Id) val);
                    if (!String.isBlank(email)) emails.add(email);
                } else if (val instanceof String && ((String)val).contains('@')) {
                    emails.add((String) val); // direct email string on related object
                }
            }
        }

        // ── STATIC: literal email addresses stored in metadata ────────────────
        if (config.usesStaticRecipients()) {
            for (String staticEmail : config.staticRecipientEmails) {
                if (!String.isBlank(staticEmail)) emails.add(staticEmail.trim());
            }
        }

        return emails;
    }

    /**
     * Extracts all user/contact Ids from a record that need email resolution.
     * Only covers FIELD and RELATED_FIELD sources (STATIC doesn't need a lookup).
     */
    private static Set<Id> extractUserIds(
        HT_ReminderConfigLoader.ReminderConfig config,
        SObject record
    ) {
        Set<Id> ids = new Set<Id>();

        if (config.usesFieldRecipients()) {
            for (String fieldName : config.recipientFieldApiNames) {
                Object val = safeGet(record, fieldName);
                if (val instanceof Id) ids.add((Id) val);
            }
        }

        if (config.usesRelatedFieldRecipients()) {
            for (String path : config.recipientRelatedFieldPaths) {
                Object val = traverseRelationship(record, path);
                if (val instanceof Id) ids.add((Id) val);
            }
        }

        return ids;
    }

    // ── SOQL helpers ─────────────────────────────────────────────────────────

    /**
     * Dynamically re-queries the SObject with all fields needed for recipient resolution.
     */
    private static Map<Id, SObject> queryRecords(
        HT_ReminderConfigLoader.ReminderConfig config,
        Set<Id> recordIds
    ) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        try {
            List<String> fields = config.buildSelectFields();
            String query = 'SELECT ' + String.join(fields, ', ')
                         + ' FROM '  + config.objectApiName
                         + ' WHERE Id IN :recordIds'
                         + ' WITH SECURITY_ENFORCED';
            for (SObject record : Database.query(query)) {
                result.put((Id) record.get('Id'), record);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ReminderEmailService.queryRecords error: ' + e.getMessage());
        }
        return result;
    }

    /**
     * Batch-loads User email addresses into userEmailCache.
     * Skips Ids already cached.
     */
    private static void cacheUserEmails(Set<Id> userIds) {
        Set<Id> toQuery = new Set<Id>();
        for (Id uid : userIds) {
            if (!userEmailCache.containsKey(uid)) toQuery.add(uid);
        }
        if (toQuery.isEmpty()) return;

        // Users
        for (User u : [
            SELECT Id, Email FROM User
            WHERE Id IN :toQuery AND IsActive = true
        ]) {
            userEmailCache.put(u.Id, u.Email);
            toQuery.remove(u.Id);
        }

        // Remaining Ids may be Contacts
        if (!toQuery.isEmpty()) {
            for (Contact c : [
                SELECT Id, Email FROM Contact WHERE Id IN :toQuery
            ]) {
                userEmailCache.put(c.Id, c.Email);
            }
        }
    }

    /**
     * Resolves an EmailTemplate Id by DeveloperName, with per-transaction caching.
     */
    private static Id resolveTemplateId(String templateApiName) {
        if (templateIdCache.containsKey(templateApiName)) {
            return templateIdCache.get(templateApiName);
        }
        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate
            WHERE DeveloperName = :templateApiName
            LIMIT 1
        ];
        Id tid = templates.isEmpty() ? null : templates[0].Id;
        templateIdCache.put(templateApiName, tid);
        return tid;
    }

    // ── Email sender ─────────────────────────────────────────────────────────

    /**
     * Sends emails in chunks of 10 to stay within the
     * Messaging.sendEmail governor limit per invocation.
     */
    private static void sendEmails1(List<Messaging.SingleEmailMessage> emails) {
        if (emails.isEmpty()) return;

        Integer chunkSize = HT_ReminderConstants.MAX_EMAIL_PER_EXECUTION;
        for (Integer i = 0; i < emails.size(); i += chunkSize) {
            Integer endIdx = Math.min(i + chunkSize, emails.size());
            List<Messaging.SingleEmailMessage> chunk =
                new List<Messaging.SingleEmailMessage>();
            for (Integer j = i; j < endIdx; j++) {
                chunk.add(emails[j]);
            }
            try {
                Messaging.sendEmail(chunk, false); // allOrNone = false
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'ReminderEmailService.sendEmails chunk error: ' + e.getMessage());
            }
        }
    }
    
    
    /**
 * Sends emails using template rendering (dummy send + rollback),
 * then sends the actual emails in chunks.
 */
private static void sendEmails(List<Messaging.SingleEmailMessage> emails) {

    if (emails.isEmpty()) return;

    Contact cnt = [
        SELECT Id
        FROM Contact
        WHERE Email != null
        LIMIT 1
    ];

    List<Messaging.SingleEmailMessage> dummyEmails = new List<Messaging.SingleEmailMessage>();

    // Build dummy emails to render template
    for (Messaging.SingleEmailMessage email : emails) {

        Messaging.SingleEmailMessage dummy = new Messaging.SingleEmailMessage();

        dummy.setTemplateId(email.getTemplateId());
        dummy.setWhatId(email.getWhatId());
        dummy.setTargetObjectId(cnt.Id);
        dummy.setToAddresses(email.getToAddresses());
        dummy.setSaveAsActivity(false);

        dummyEmails.add(dummy);
    }

    // Dummy send to generate subject/body
    Savepoint sp = Database.setSavepoint();

    if(!Test.isRunningTest()) {
        Messaging.sendEmail(dummyEmails, false);
        Database.rollback(sp);
    }

    // Build final emails
    List<Messaging.SingleEmailMessage> actualEmails = new List<Messaging.SingleEmailMessage>();

    for (Messaging.SingleEmailMessage email : dummyEmails) {

        Messaging.SingleEmailMessage finalMail = new Messaging.SingleEmailMessage();

        finalMail.setToAddresses(email.getToAddresses());
        finalMail.setSubject(email.getSubject());
        finalMail.setHTMLBody(email.getHTMLBody());
        finalMail.setPlainTextBody(email.getPlainTextBody());
        finalMail.setSaveAsActivity(false);

        actualEmails.add(finalMail);
    }

    // Send actual emails in chunks
    Integer chunkSize = HT_ReminderConstants.MAX_EMAIL_PER_EXECUTION;

    for (Integer i = 0; i < actualEmails.size(); i += chunkSize) {

        Integer endIdx = Math.min(i + chunkSize, actualEmails.size());

        List<Messaging.SingleEmailMessage> chunk = new List<Messaging.SingleEmailMessage>();

        for (Integer j = i; j < endIdx; j++) {
            chunk.add(actualEmails[j]);
        }

        try {
            if(!Test.isRunningTest()) {
                Messaging.sendEmail(chunk, false);
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ReminderEmailService.sendEmails chunk error: ' + e.getMessage());
        }
    }
}
    

    // ── Utility ──────────────────────────────────────────────────────────────

    /**
     * Safe wrapper around SObject.get() — returns null instead of throwing
     * for fields not present on the record.
     */
    private static Object safeGet(SObject record, String fieldName) {
        try {
            return record.get(fieldName);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Traverses a dot-notation relationship path on an SObject.
     * Supports single-level relationships (e.g. Account.OwnerId).
     * Returns null safely if traversal fails.
     */
    private static Object traverseRelationship(SObject record, String path) {
        try {
            List<String> parts = path.split('\\' + HT_ReminderConstants.DOT);
            if (parts.size() == 1) {
                return record.get(parts[0]);
            }
            // Two-part path: RelationshipName.FieldName
            SObject related = record.getSObject(parts[0]);
            if (related == null) return null;
            return related.get(parts[1]);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'ReminderEmailService.traverseRelationship failed for path=' + path +
                ': ' + e.getMessage());
            return null;
        }
    }
}