/**
 * ReminderEventTriggerHandler
 * Handles Reminder_Event__e platform event trigger.
 * Delegates to ReminderEmailService for all email resolution and delivery.
 *
 * Platform event triggers:
 *  - Run in their own transaction (separate from the publisher)
 *  - Have their own governor limits
 *  - Can receive up to 2,000 events per trigger invocation (configurable)
 *  - Support Database.setSavepoint() for partial rollback patterns
 *
 * Error handling:
 *  - Uses EventBus.TriggerContext.currentContext().setResumeCheckpoint()
 *    so failed batches are retried from the correct event offset.
 */
public class HT_ReminderEventTriggerHandler {

    public static void handleAfterInsert(List<Reminder_Event__e> events) {
        if (events == null || events.isEmpty()) return;

        try {
            HT_ReminderEmailService.processEvents(events);

            // Advance the resume checkpoint to the last successfully processed event
            // so the platform doesn't re-deliver already-processed events on retry
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(
                events[events.size() - 1].ReplayId
            );

        } catch (Exception e) {
            // Log the error; platform will retry from last checkpoint
            System.debug(LoggingLevel.ERROR,
                'ReminderEventTriggerHandler error: ' + e.getMessage() +
                '\nStack: ' + e.getStackTraceString());
        }
    }
}