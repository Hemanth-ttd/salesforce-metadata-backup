/**
 * ReminderScheduler
 * Daily scheduled Apex entry point for the multi-object reminder framework.
 *
 * On each execution it:
 *  1. Loads all active Reminder_Configuration__mdt records.
 *  2. For each config × reminderType × offsetDays combination, launches
 *     one ReminderQueryBatch instance with the configured batch size.
 *
 * Scheduling:
 *   Schedule via Setup > Scheduled Jobs or run the anonymous snippet below:
 *
 *   System.schedule(
 *       'Daily Reminder Scheduler',
 *       '0 0 6 * * ?',          // every day at 06:00
 *       new ReminderScheduler()
 *   );
 *
 * Notes:
 *  - Salesforce allows up to 5 concurrent batch jobs; if you have many configs
 *    consider staggering or using a chain pattern.
 *  - The scheduler itself performs zero SOQL queries on large data; all heavy
 *    lifting is delegated to ReminderQueryBatch.
 */
global class HT_ReminderScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        List<HT_ReminderConfigLoader.ReminderConfig> configs =
            HT_ReminderConfigLoader.loadActiveConfigs();

        if (configs.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'ReminderScheduler: No active configurations found.');
            return;
        }

        Integer batchesLaunched = 0;

        for (HT_ReminderConfigLoader.ReminderConfig config : configs) {

            // ── Pre reminders (due date is N days from today) ─────────────
            if (config.hasPreReminders()) {
                for (Integer offsetDays : config.preReminderDays) {
                    HT_ReminderScheduler.launchBatch(config, HT_ReminderConstants.REMINDER_TYPE_PRE, offsetDays);
                    batchesLaunched++;
                }
            }

            // ── Post reminders (due date was N days ago) ──────────────────
            if (config.hasPostReminders()) {
                for (Integer offsetDays : config.postReminderDays) {
                    HT_ReminderScheduler.launchBatch(config, HT_ReminderConstants.REMINDER_TYPE_POST, offsetDays);
                    batchesLaunched++;
                }
            }
        }

        System.debug(LoggingLevel.INFO,
            'ReminderScheduler: launched ' + batchesLaunched + ' batch job(s).');
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    public static void launchBatch(
        HT_ReminderConfigLoader.ReminderConfig config,
        String reminderType,
        Integer offsetDays
    ) {
        try {
            Integer batchSize = config.batchSizeOverride != null
                ? config.batchSizeOverride
                : HT_ReminderConstants.DEFAULT_BATCH_SIZE;

            Database.executeBatch(
                new HT_ReminderQueryBatch(config, reminderType, offsetDays),
                batchSize
            );

            System.debug(LoggingLevel.INFO,
                'ReminderScheduler: launched batch | Config=' + config.developerName +
                ' | Type=' + reminderType + ' | Offset=' + offsetDays +
                ' | BatchSize=' + batchSize);

        } catch (Exception e) {
            // Log but continue launching remaining configs
            System.debug(LoggingLevel.ERROR,
                'ReminderScheduler: failed to launch batch for config=' +
                config.developerName + ' | ' + e.getMessage());
        }
    }
}