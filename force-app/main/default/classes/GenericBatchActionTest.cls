@IsTest
private with sharing class GenericBatchActionTest {
    private static final Integer recordsQuantity = GenericBatchAction.MAX_RECORDS_PER_LOG * 2;
    private static final String ACCOUNT_NAME = 'Account Name';
    private static final String CHANGED_ACCOUNT_NAME = 'Changed Account Name';
    private static final String CHANGED_PHONE = '050000';

    @TestSetup
    private static void makeData() {
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < recordsQuantity; i++) {
            Account account = new Account();
            // need to create dummy accounts with name ACCOUNT_NAME and number
            account.Name = 'Dummy Account ' + i;
            account.AccountNumber = 'AccNum' + i;
            accounts.add(account);
        }
        insert accounts;
    }

    @IsTest
    private static void testDeleteSuccess() {
        List<Account> accounts = [SELECT Id FROM Account];
        System.assertEquals(recordsQuantity, accounts.size());

        Test.startTest();
        executeGenericBatchAction('DeleteSuccess', 'Delete', null);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :new Map<Id, Account>(accounts).keySet()]);
        // System.assertEquals(0, [SELECT COUNT() FROM EP_Log__c]);
    }

    @IsTest
    private static void testUpdateSuccess() {
        List<Account> accounts = [SELECT Id FROM Account];
        System.assertEquals(recordsQuantity, accounts.size());

        Test.startTest();
        executeGenericBatchAction('UpdateSuccess', 'Update', getParamsJson());
        Test.stopTest();

        System.assertEquals(recordsQuantity, [SELECT COUNT() FROM Account WHERE Id IN :new Map<Id, Account>(accounts).keySet()]);
    }

    @IsTest
    private static void testMultipleSuccess() {
        GenericBatchAction__mdt genericActionMultiple = ScheduleBatchAction.genericBatchActionAccountBuilder('Multiple_Acc', 'Multiple', getJSONStringMultiple(),recordsQuantity);
        GenericBatchAction__mdt genericActionDelete = ScheduleBatchAction.genericBatchActionAccountBuilder('Delete_Acc', 'Delete', null, recordsQuantity);
        GenericBatchAction__mdt genericActionUpdate = ScheduleBatchAction.genericBatchActionAccountBuilder('Update_Acc', 'Update', getParamsJson(), recordsQuantity);

        GenericBatchAction genericBatchAction = new GenericBatchAction();
        genericBatchAction.genericBatchActions.put('Delete_Acc', genericActionDelete);
        genericBatchAction.genericBatchActions.put('Update_Acc', genericActionUpdate);

        genericBatchAction.genericBatchAction = genericActionMultiple;

        Test.startTest();
        System.schedule(Datetime.now() + ' ' + 'Multiple_Acc',  '0 0 12 * * ?', genericBatchAction);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM AsyncApexJob] > 0);
    }

    @IsTest
    private static void testDeleteFailure() {
        List<Account> accounts = [SELECT Id FROM Account];
        delete accounts; // delete them so job will retrieve them using ALL ROWS and throw exception because they no longer exist
        testFailure(accounts, 'DeleteFailure', 'Delete', null);
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :new Map<Id, Account>(accounts).keySet()]);
    }

    @IsTest
    private static void testUpdateFailure() {
        List<Account> accounts = [SELECT Id FROM Account];
        String paramsJson = getParamsJsonError();
        testFailure(accounts, 'UpdateFailure', 'Update', paramsJson);
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :new Map<Id, Account>(accounts).keySet() and Phone = :CHANGED_PHONE]);
    }

    @IsTest
    private static void testFlowFailure() {
        Test.startTest();
        executeGenericBatchAction('FlowSuccess', 'Flow', '{"flowApiName":"FakeFlowAPIName"}');
        Test.stopTest();
    }

    private static void testFailure(List<Account> accounts, String actionName, String operation, String paramsJson) {
        System.assertEquals(recordsQuantity, accounts.size());

        Test.startTest();
        executeGenericBatchAction(actionName, operation, paramsJson);
        Test.stopTest();

    }

    private static String getParamsJson() {
        return JSON.serialize(new Map<String, String>{'Name' => CHANGED_ACCOUNT_NAME});
    }

    // This change will throw a validation error on phone number
    private static String getParamsJsonError() {
        return JSON.serialize(new Map<String, String>{'Phone' => CHANGED_PHONE});
    }

    // Params for Multiple Operation
    public static String getJSONStringMultiple() {
        Map<String, List<String>> jobMap = new Map<String, List<String>>();
        jobMap.put('jobs', new List<String>{'Delete_Acc', 'Update_Acc'});
        return JSON.serialize(jobMap);
    }

    public static String getParamsJsonMultipleJobs() {
        Map<String, List<String>> jobMap = new Map<String, List<String>>();
        jobMap.put('jobs', new List<String>{'Delete_Acc_Ayoub', 'Update_Acc_Ayoub'});
        return JSON.serialize(jobMap);
    }

    private static void executeGenericBatchAction(String actionName, String operation, String paramsJson) {
        GenericBatchAction genericBatchActionInstance = new GenericBatchAction();
        genericBatchActionInstance.genericBatchAction = ScheduleBatchAction.genericBatchActionAccountBuilder(actionName, operation, paramsJson, recordsQuantity);
        genericBatchActionInstance.execute();
    }
}