/**
 * ReminderQueryBatch
 * Batch Apex for a single Reminder_Configuration__mdt record + offset combination.
 *
 * Responsibilities:
 *  - Dynamically queries the configured SObject for records whose due date
 *    matches today ± offsetDays.
 *  - Publishes a Reminder_Event__e platform event per matching record.
 *  - Safe for high-volume objects: query is cursor-based via Database.QueryLocator.
 *
 * One instance is launched per (config × reminderType × offsetDays) combination
 * by ReminderScheduler, so each batch is single-purpose and fully independent.
 */
public class HT_ReminderQueryBatch implements Database.Batchable<SObject>, Database.Stateful {

    private final HT_ReminderConfigLoader.ReminderConfig config;
    private final String  reminderType;   // 'Pre' or 'Post'
    private final Integer offsetDays;

    // Stateful counters for monitoring
    private Integer totalProcessed = 0;
    private Integer totalPublished  = 0;
    private Integer totalErrors     = 0;

    // ── Constructor ──────────────────────────────────────────────────────────

    public HT_ReminderQueryBatch(
        HT_ReminderConfigLoader.ReminderConfig config,
        String reminderType,
        Integer offsetDays
    ) {
        this.config       = config;
        this.reminderType = reminderType;
        this.offsetDays   = offsetDays;
    }

    // ── Database.Batchable ───────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(buildQuery());
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Reminder_Event__e> events = new List<Reminder_Event__e>();

        for (SObject record : scope) {
            totalProcessed++;
            try {
                Reminder_Event__e evt = new Reminder_Event__e();
                evt.Config_Developer_Name__c = config.developerName;
                evt.Record_Id__c             = (String) record.get('Id');
                evt.Reminder_Type__c         = reminderType;
                evt.Offset_Days__c           = offsetDays;

                // Carry the due date as a string for reference in the email service
                Object dueDateValue = record.get(config.dueDateFieldApiName);
                evt.Due_Date__c = dueDateValue != null
                    ? String.valueOf(dueDateValue).left(20)
                    : '';

                events.add(evt);
            } catch (Exception e) {
                totalErrors++;
                System.debug(LoggingLevel.ERROR,
                    'ReminderQueryBatch.execute error for record ' +
                    record.get('Id') + ': ' + e.getMessage());
            }
        }

        if (!events.isEmpty()) {
            // Publish platform events — fire-and-forget
            // EventBus.publish returns SaveResult list; log any failures
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    totalPublished++;
                } else {
                    totalErrors++;
                    System.debug(LoggingLevel.ERROR,
                        'Platform event publish failed for record ' +
                        events[i].Record_Id__c + ': ' +
                        results[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'ReminderQueryBatch finished | Config: ' + config.developerName +
            ' | Type: ' + reminderType +
            ' | Offset: ' + offsetDays + ' days' +
            ' | Processed: ' + totalProcessed +
            ' | Published: ' + totalPublished +
            ' | Errors: ' + totalErrors);
    }

    // ── Query Builder ────────────────────────────────────────────────────────

    /**
     * Builds the dynamic SOQL query:
     *   SELECT Id, <dueDateField>, [recipientFields...]
     *   FROM   <Object>
     *   WHERE  <dueDateField> = <targetDate>
     *     [AND <additionalFilter>]
     *   WITH SECURITY_ENFORCED
     */
    @TestVisible
    private String buildQuery() {
        // Determine the target date based on reminder type and offset
        Date targetDate;
        if (reminderType == HT_ReminderConstants.REMINDER_TYPE_PRE) {
            targetDate = Date.today().addDays(offsetDays);   // today + N days in the future
        } else {
            targetDate = Date.today().addDays(-offsetDays);  // today - N days in the past
        }

        // Build SELECT clause — always include Id and due date field
        List<String> selectFields = config.buildSelectFields();
        String selectClause = String.join(selectFields, ', ');

        // Build WHERE clause
        // Bind-safe: use date literal string because dynamic SOQL doesn't support bind vars
        // Date.format() returns yyyy-MM-dd which SOQL accepts
        String dateStr =  DateTime.newInstance(
                     targetDate.year(),
                     targetDate.month(),
                     targetDate.day()
                 ).format('yyyy-MM-dd'); //targetDate.format();
        String whereClause = config.dueDateFieldApiName + ' = ' + dateStr;

        if (!String.isBlank(config.additionalFilterCriteria)) {
            whereClause += ' AND (' + config.additionalFilterCriteria + ')';
        }

        String query = 'SELECT '  + selectClause
                     + ' FROM '   + config.objectApiName
                     + ' WHERE '  + whereClause
                     + ' WITH SECURITY_ENFORCED';

       // System.assertequals('ReminderQueryBatch SOQL: ' ,query);
        return query;
    }
}