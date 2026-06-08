/**
 * ReminderConstants
 * Central constants for the multi-object reminder framework.
 */
public class HT_ReminderConstants {

    // ── Reminder Type ────────────────────────────────────────────────────────
    public static final String REMINDER_TYPE_PRE  = 'Pre';
    public static final String REMINDER_TYPE_POST = 'Post';

    // ── Recipient Source Types ───────────────────────────────────────────────
    // Stored in Reminder_Configuration__mdt.Recipient_Sources__c as comma-separated values
    public static final String RECIPIENT_FIELD         = 'FIELD';         // e.g. OwnerId, AssignedTo__c
    public static final String RECIPIENT_RELATED_FIELD = 'RELATED_FIELD'; // e.g. Account.OwnerId
    public static final String RECIPIENT_STATIC        = 'STATIC';        // literal emails in metadata

    // ── Batch / Event ────────────────────────────────────────────────────────
    public static final Integer DEFAULT_BATCH_SIZE      = 200;
    public static final Integer MAX_EMAIL_PER_EXECUTION = 10; // platform event trigger processes up to 10 messages per chunk

    // ── Logging ──────────────────────────────────────────────────────────────
    public static final String LOG_SUCCESS = 'Success';
    public static final String LOG_ERROR   = 'Error';
    public static final String LOG_SKIPPED = 'Skipped';

    // ── Field Separator ──────────────────────────────────────────────────────
    public static final String COMMA       = ',';
    public static final String DOT         = '.';
    public static final String PIPE        = '|';
}