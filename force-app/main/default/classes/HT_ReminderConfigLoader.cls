/**
 * ReminderConfigLoader
 * Loads all active Reminder_Configuration__mdt records and exposes
 * helper methods to resolve offsets and recipient source types.
 */
public class HT_ReminderConfigLoader {

    // ── Inner wrapper so callers don't directly couple to __mdt field names ──
    public class ReminderConfig {
        public String  developerName            { get; private set; }
        public String  objectApiName            { get; private set; }
        public String  dueDateFieldApiName      { get; private set; }
        public String  emailTemplateApiName     { get; private set; }
        public List<Integer> preReminderDays    { get; private set; }
        public List<Integer> postReminderDays   { get; private set; }
        public Set<String>   recipientSources   { get; private set; }
        public List<String>  recipientFieldApiNames        { get; private set; }
        public List<String>  recipientRelatedFieldPaths    { get; private set; }
        public List<String>  staticRecipientEmails         { get; private set; }
        public String  additionalFilterCriteria { get; private set; }
        public Integer batchSizeOverride        { get; private set; }

        public ReminderConfig(Reminder_Configuration__mdt mdt) {
            developerName           = mdt.DeveloperName;
            objectApiName           = mdt.Object_API_Name__c;
            dueDateFieldApiName     = mdt.Due_Date_Field_API_Name__c;
            emailTemplateApiName    = mdt.Email_Template_API_Name__c;
            additionalFilterCriteria = mdt.Additional_Filter_Criteria__c;
            batchSizeOverride       = (mdt.Batch_Size_Override__c != null)
                                        ? Integer.valueOf(mdt.Batch_Size_Override__c)
                                        : HT_ReminderConstants.DEFAULT_BATCH_SIZE;

            preReminderDays  = parseDaysList(mdt.Pre_Reminder_Days__c);
            postReminderDays = parseDaysList(mdt.Post_Reminder_Days__c);

            recipientSources = parseSet(mdt.Recipient_Sources__c);
            recipientFieldApiNames     = parseList(mdt.Recipient_Field_API_Names__c);
            recipientRelatedFieldPaths = parseList(mdt.Recipient_Related_Field_Paths__c);
            staticRecipientEmails      = parseList(mdt.Static_Recipient_Emails__c);
        }

        // ── Helpers ──────────────────────────────────────────────────────────

        /** Returns true if this config has any pre offsets defined. */
        public Boolean hasPreReminders() {
            return !preReminderDays.isEmpty();
        }

        /** Returns true if this config has any post offsets defined. */
        public Boolean hasPostReminders() {
            return !postReminderDays.isEmpty();
        }

        /** Returns true if FIELD recipient source is enabled. */
        public Boolean usesFieldRecipients() {
            return recipientSources.contains(HT_ReminderConstants.RECIPIENT_FIELD);
        }

        /** Returns true if RELATED_FIELD recipient source is enabled. */
        public Boolean usesRelatedFieldRecipients() {
            return recipientSources.contains(HT_ReminderConstants.RECIPIENT_RELATED_FIELD);
        }

        /** Returns true if STATIC recipient source is enabled. */
        public Boolean usesStaticRecipients() {
            return recipientSources.contains(HT_ReminderConstants.RECIPIENT_STATIC);
        }

        /**
         * Builds the list of SObject fields to include in the dynamic SOQL SELECT.
         * Includes: Id, due date field, all direct recipient lookup fields,
         * and first-level related field paths (e.g. Account.OwnerId).
         */
        public List<String> buildSelectFields() {
            Set<String> fields = new Set<String>{ 'Id', dueDateFieldApiName };

            if (usesFieldRecipients()) {
                fields.addAll(recipientFieldApiNames);
            }

            if (usesRelatedFieldRecipients()) {
                // Include the full path — SOQL supports one level of traversal
                fields.addAll(recipientRelatedFieldPaths);
            }

            return new List<String>(fields);
        }

        // ── Private parsers ──────────────────────────────────────────────────

        private List<Integer> parseDaysList(String raw) {
            List<Integer> result = new List<Integer>();
            if (String.isBlank(raw)) return result;
            for (String s : raw.split(HT_ReminderConstants.COMMA)) {
                String trimmed = s.trim();
                if (trimmed.isNumeric()) {
                    result.add(Integer.valueOf(trimmed));
                }
            }
            return result;
        }

        private List<String> parseList(String raw) {
            List<String> result = new List<String>();
            if (String.isBlank(raw)) return result;
            for (String s : raw.split(HT_ReminderConstants.COMMA)) {
                String trimmed = s.trim();
                if (!String.isBlank(trimmed)) result.add(trimmed);
            }
            return result;
        }

        private Set<String> parseSet(String raw) {
            return new Set<String>(parseList(raw));
        }
    }

    // ── Loader ───────────────────────────────────────────────────────────────

    /**
     * Returns all active ReminderConfig wrappers.
     * Results are NOT cached at class level because Schedulers and Batch
     * run in separate transactions.
     */
    public static List<ReminderConfig> loadActiveConfigs() {
        List<ReminderConfig> configs = new List<ReminderConfig>();
        for (Reminder_Configuration__mdt mdt : [
            SELECT DeveloperName,
                   Object_API_Name__c,
                   Due_Date_Field_API_Name__c,
                   Email_Template_API_Name__c,
                   Pre_Reminder_Days__c,
                   Post_Reminder_Days__c,
                   Recipient_Sources__c,
                   Recipient_Field_API_Names__c,
                   Recipient_Related_Field_Paths__c,
                   Static_Recipient_Emails__c,
                   Additional_Filter_Criteria__c,
                   Batch_Size_Override__c,
                   Is_Active__c
            FROM Reminder_Configuration__mdt
            WHERE Is_Active__c = true
            ORDER BY DeveloperName
        ]) {
            configs.add(new ReminderConfig(mdt));
        }
        return configs;
    }
}