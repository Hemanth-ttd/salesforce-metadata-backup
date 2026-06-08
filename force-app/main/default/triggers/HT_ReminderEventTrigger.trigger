/**
 * ReminderEventTrigger
 * Trigger on Reminder_Event__e platform event.
 * Thin dispatcher — all logic lives in ReminderEventTriggerHandler.
 */
trigger HT_ReminderEventTrigger on Reminder_Event__e (after insert) {
    HT_ReminderEventTriggerHandler.handleAfterInsert(Trigger.new);
}