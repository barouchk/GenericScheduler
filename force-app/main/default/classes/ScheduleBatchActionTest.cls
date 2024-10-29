@isTest
private class ScheduleBatchActionTest {

    @isTest
    static void testScheduleBatchActionSuccess() {
        // Create test data
        ScheduleBatchAction.actionInput input = new ScheduleBatchAction.actionInput(
            '0 0 12 * * ?', // Cron expression for scheduling at noon every day
            ScheduleBatchAction.BATCH_DELETE_ACCOUNT_DEVNAME,
            ScheduleBatchAction.BATCH_DELETE_ACCOUNT_LABEL
        );

        List<ScheduleBatchAction.actionInput> inputs = new List<ScheduleBatchAction.actionInput>{input};

        // Call the method
        Test.startTest();
        List<ScheduleBatchAction.actionOutput> outputs = ScheduleBatchAction.ScheduleBatchAction(inputs);
        Test.stopTest();

        // Verify the results
        System.assertEquals(1, outputs.size(), 'There should be one output');
        System.assert(outputs[0].success, 'The batch job should be scheduled successfully');
        System.assertEquals('', outputs[0].errorMessage, 'There should be no error message');
    }

    @isTest
    static void testScheduleBatchActionFailure() {
        // Create test data with an invalid cron expression to force an exception
        ScheduleBatchAction.actionInput input = new ScheduleBatchAction.actionInput(
        'invalid_cron_expression', // Invalid cron expression
        'TestBatchAction',
        'Test Batch Action'
        );

        List<ScheduleBatchAction.actionInput> inputs = new List<ScheduleBatchAction.actionInput>{input};

        // Call the method
        Test.startTest();
        List<ScheduleBatchAction.actionOutput> outputs = ScheduleBatchAction.ScheduleBatchAction(inputs);
        Test.stopTest();

        // Verify the results
        System.assertEquals(1, outputs.size(), 'There should be one output');
        System.assert(!outputs[0].success, 'The batch job should not be scheduled successfully');
        System.assertNotEquals('', outputs[0].errorMessage, 'There should be an error message');
    }

}