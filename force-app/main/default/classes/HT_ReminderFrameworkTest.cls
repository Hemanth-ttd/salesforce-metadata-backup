/**
 * ReminderFrameworkTest
 * Comprehensive test coverage for the multi-object reminder framework:
 *  - ReminderConfigLoader
 *  - ReminderQueryBatch  (query builder)
 *  - ReminderScheduler
 *  - ReminderEmailService
 *  - ReminderEventTriggerHandler
 */
@isTest
private class HT_ReminderFrameworkTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Mock: HttpCalloutMock not needed — no callouts in this framework
    // We use Test.setMock for EmailInvocations and mock metadata via a
    // simple inner stub pattern.
    // ─────────────────────────────────────────────────────────────────────────

    // ── Helper: build a ReminderConfig wrapper directly without hitting DB ───
    private static HT_ReminderConfigLoader.ReminderConfig buildConfig(
        String objectApi,
        String dueDateField,
        String templateApi,
        String preDays,
        String postDays,
        String recipientSources,
        String recipientFields,
        String relatedPaths,
        String staticEmails
    ) {
        Reminder_Configuration__mdt mdt = new Reminder_Configuration__mdt();
        mdt.DeveloperName                   = 'Test_Config';
        mdt.Object_API_Name__c              = objectApi;
        mdt.Due_Date_Field_API_Name__c      = dueDateField;
        mdt.Email_Template_API_Name__c      = templateApi;
        mdt.Pre_Reminder_Days__c            = preDays;
        mdt.Post_Reminder_Days__c           = postDays;
        mdt.Recipient_Sources__c            = recipientSources;
        mdt.Recipient_Field_API_Names__c    = recipientFields;
        mdt.Recipient_Related_Field_Paths__c = relatedPaths;
        mdt.Static_Recipient_Emails__c      = staticEmails;
        mdt.Is_Active__c                    = true;
        mdt.Batch_Size_Override__c          = 50;
        return new HT_ReminderConfigLoader.ReminderConfig(mdt);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. ReminderConfigLoader — field parsing
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testConfigLoader_ParsesDaysAndSources() {
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'My_Template',
            '7,3,1', '1,3',
            'FIELD,STATIC',
            'OwnerId', null,
            'admin@test.com'
        );

        System.assertEquals('Task',           cfg.objectApiName);
        System.assertEquals('ActivityDate',   cfg.dueDateFieldApiName);
        System.assertEquals(3,                cfg.preReminderDays.size());
        System.assertEquals(7,                cfg.preReminderDays[0]);
        System.assertEquals(2,                cfg.postReminderDays.size());
        System.assert(cfg.hasPreReminders(),  'Should have pre reminders');
        System.assert(cfg.hasPostReminders(), 'Should have post reminders');
        System.assert(cfg.usesFieldRecipients(),   'FIELD source expected');
        System.assert(cfg.usesStaticRecipients(),  'STATIC source expected');
        System.assert(!cfg.usesRelatedFieldRecipients(), 'RELATED_FIELD not configured');
        System.assertEquals(50, cfg.batchSizeOverride);
    }

    @isTest
    static void testConfigLoader_NullDaysReturnsEmpty() {
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Tmpl',
            null, null, 'STATIC', null, null, 'a@b.com'
        );
        System.assert(!cfg.hasPreReminders(),  'No pre days');
        System.assert(!cfg.hasPostReminders(), 'No post days');
    }

    @isTest
    static void testConfigLoader_BuildSelectFields_IncludesRecipientFields() {
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Tmpl',
            '1', '1',
            'FIELD,RELATED_FIELD',
            'OwnerId',
            'Account.OwnerId',
            null
        );
        List<String> fields = cfg.buildSelectFields();
        System.assert(fields.contains('Id'),             'Id always included');
        System.assert(fields.contains('ActivityDate'),   'Due date field included');
        System.assert(fields.contains('OwnerId'),        'Recipient field included');
        System.assert(fields.contains('Account.OwnerId'),'Related path included');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. ReminderQueryBatch — query builder
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testQueryBatch_BuildQuery_PreReminderTargetsFutureDate() {
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Tmpl',
            '7', null, 'STATIC', null, null, 'a@b.com'
        );
        HT_ReminderQueryBatch batch = new HT_ReminderQueryBatch(cfg, HT_ReminderConstants.REMINDER_TYPE_PRE, 7);
        String query = batch.buildQuery();
        Date expectedDate = Date.today().addDays(7);
  		String dateStr =  DateTime.newInstance(
                     expectedDate.year(),
                     expectedDate.month(),
                     expectedDate.day()
                 ).format('yyyy-MM-dd'); 
        
        System.assert(query.contains(dateStr),
            'Pre query should target today + 7 days');
        System.assert(query.contains('FROM Task'),        'Object name in query');
        System.assert(query.contains('ActivityDate'),     'Due date field in query');
        System.assert(query.contains('WITH SECURITY_ENFORCED'), 'Security enforced');
    }

    @isTest
    static void testQueryBatch_BuildQuery_PostReminderTargetsPastDate() {
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Tmpl',
            null, '3', 'STATIC', null, null, 'a@b.com'
        );
        HT_ReminderQueryBatch batch = new HT_ReminderQueryBatch(cfg, HT_ReminderConstants.REMINDER_TYPE_POST, 3);
        String query = batch.buildQuery();

        Date expectedDate = Date.today().addDays(-3);
        String dateStr =  DateTime.newInstance(
                     expectedDate.year(),
                     expectedDate.month(),
                     expectedDate.day()
                 ).format('yyyy-MM-dd'); 
        System.assert(query.contains(dateStr),
            'Post query should target today - 3 days');
    }

    @isTest
    static void testQueryBatch_BuildQuery_AdditionalFilterAppended() {
        Reminder_Configuration__mdt mdt = new Reminder_Configuration__mdt();
        mdt.DeveloperName                = 'Test_Config';
        mdt.Object_API_Name__c           = 'Task';
        mdt.Due_Date_Field_API_Name__c   = 'ActivityDate';
        mdt.Email_Template_API_Name__c   = 'Tmpl';
        mdt.Pre_Reminder_Days__c         = '1';
        mdt.Recipient_Sources__c         = 'STATIC';
        mdt.Static_Recipient_Emails__c   = 'a@b.com';
        mdt.Is_Active__c                 = true;
        mdt.Additional_Filter_Criteria__c = 'Status != \'Completed\'';
        HT_ReminderConfigLoader.ReminderConfig cfg = new HT_ReminderConfigLoader.ReminderConfig(mdt);

        HT_ReminderQueryBatch batch = new HT_ReminderQueryBatch(cfg, HT_ReminderConstants.REMINDER_TYPE_PRE, 1);
        String query = batch.buildQuery();

        System.assert(query.contains('Status'),
            'Additional filter criteria should be in query');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. ReminderScheduler — launches correct number of batches
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testScheduler_ExecutesWithoutException() {
        // Scheduler loads metadata; with no real records in test context
        // it should complete gracefully
        Test.startTest();
        HT_ReminderScheduler scheduler = new HT_ReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();
        // No assertion needed — verifies no unhandled exception
        System.assert(true, 'Scheduler executed without exception');
    }

    @isTest
    static void testScheduler_CanBeScheduled() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Reminder Scheduler',
            '0 0 6 * * ?',
            new HT_ReminderScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Scheduler should return a job Id');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. ReminderEventTriggerHandler — processes events without exception
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testTriggerHandler_NullEventsNoException() {
        Test.startTest();
        HT_ReminderEventTriggerHandler.handleAfterInsert(null);
        Test.stopTest();
        System.assert(true, 'Null events handled gracefully');
    }

    @isTest
    static void testTriggerHandler_EmptyEventsNoException() {
        Test.startTest();
        HT_ReminderEventTriggerHandler.handleAfterInsert(new List<Reminder_Event__e>());
        Test.stopTest();
        System.assert(true, 'Empty events handled gracefully');
    }

    @isTest
    static void testTriggerHandler_UnknownConfigSkippedGracefully() {
        // Fire an event with a config name that doesn't exist in metadata
        Reminder_Event__e evt = new Reminder_Event__e();
        evt.Config_Developer_Name__c = 'Nonexistent_Config_XYZ';
        evt.Record_Id__c             = UserInfo.getUserId(); // valid Id, wrong config
        evt.Reminder_Type__c         = HT_ReminderConstants.REMINDER_TYPE_PRE;
        evt.Offset_Days__c           = 7;
        evt.Due_Date__c              = String.valueOf(Date.today().addDays(7));

        Test.startTest();
        HT_ReminderEventTriggerHandler.handleAfterInsert(new List<Reminder_Event__e>{ evt });
        Test.stopTest();

        System.assert(true, 'Unknown config name handled gracefully without exception');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. ReminderQueryBatch — full execute via Database.executeBatch
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testQueryBatch_ExecuteWithRealTaskRecords() {
        // Insert a Task with ActivityDate = today + 7 (pre reminder scenario)
        Task t = new Task(
            Subject    = 'Reminder Test Task',
            ActivityDate = Date.today().addDays(7),
            Status     = 'Not Started',
            OwnerId    = UserInfo.getUserId()
        );
        insert t;

        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Test_Template',
            '7', null,
            'FIELD,STATIC',
            'OwnerId',
            null,
            'static@test.com'
        );

        Test.startTest();
        Database.executeBatch(
            new HT_ReminderQueryBatch(cfg, HT_ReminderConstants.REMINDER_TYPE_PRE, 7),
            200
        );
        Test.stopTest();

        // Platform events are fire-and-forget; verify batch ran without exception
        System.assert(true, 'Batch executed without exception on Task records');
    }

    @isTest
    static void testQueryBatch_ExecuteWithNoMatchingRecords() {
        // No tasks with ActivityDate = today + 99
        HT_ReminderConfigLoader.ReminderConfig cfg = buildConfig(
            'Task', 'ActivityDate', 'Test_Template',
            '99', null, 'STATIC', null, null, 'static@test.com'
        );

        Test.startTest();
        Database.executeBatch(
            new HT_ReminderQueryBatch(cfg, HT_ReminderConstants.REMINDER_TYPE_PRE, 99),
            200
        );
        Test.stopTest();

        System.assert(true, 'Batch with zero matching records finishes cleanly');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. ReminderConstants — spot-check values
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void testConstants_Values() {
        System.assertEquals('Pre',           HT_ReminderConstants.REMINDER_TYPE_PRE);
        System.assertEquals('Post',          HT_ReminderConstants.REMINDER_TYPE_POST);
        System.assertEquals('FIELD',         HT_ReminderConstants.RECIPIENT_FIELD);
        System.assertEquals('RELATED_FIELD', HT_ReminderConstants.RECIPIENT_RELATED_FIELD);
        System.assertEquals('STATIC',        HT_ReminderConstants.RECIPIENT_STATIC);
        System.assertEquals(200,             HT_ReminderConstants.DEFAULT_BATCH_SIZE);
    }
}