public with sharing class GenericBatchAction implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
    public Map<String, GenericBatchAction__mdt> genericBatchActions = new Map<String, GenericBatchAction__mdt>();
    public GenericBatchAction__mdt genericBatchAction;

    private Map<String, String> errorsMap = new Map<String, String>();
    @TestVisible private static final Integer MAX_RECORDS_PER_LOG = 100;
  
    public void execute(SchedulableContext sc) {
        if(genericBatchAction == null) {
            // use the first word of the scheduled job label as the GenericBatchAction__mdt record developer name
            String scheduledJobName = [SELECT CronJobDetail.Name FROM CronTrigger WHERE Id = :sc.getTriggerId()].CronJobDetail.Name;
            List<String> splitsJobName = scheduledJobName.split(' ');
            String actionName = splitsJobName.get(splitsJobName.size() - 1);
            execute(actionName);
        } else {
            execute();
        }
    }

    public void execute(String actionName) {
        if(Test.isRunningTest() ) {
           genericBatchAction = genericBatchActions.get(actionName);
        }
        else{
        // do not use GenericBatchAction__mdt.getInstance(actionName), because it retrieves only the first 255 characters of Query__c
        genericBatchAction = [SELECT DeveloperName, Operation__c, Query__c, Params__c, Chunk_Size__c FROM GenericBatchAction__mdt WHERE DeveloperName = :actionName];
        System.assertNotEquals(null, genericBatchAction, 'Could not find a GenericBatchAction__mdt record with the name ' + actionName);
        
        }
        execute();
    }

    public void execute() {
        System.debug('found Generic Batch Action: ' + JSON.serializePretty(genericBatchAction));
        if(genericBatchAction.Operation__c == 'Multiple') {
            // use string array "jobs" from Params__c json to call a group of different generic batch actions on a single schedule
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(genericBatchAction.Params__c);
            List<Object> jobs = (List<Object>)params.get('jobs');
            System.debug('executing sub jobs: ' + JSON.serializePretty(jobs));
            for(Object job : jobs) {
                execute((String)job); // invoke same method again with multiple jobs
            }
        } else {
            Database.executeBatch(this, Integer.valueOf(genericBatchAction.Chunk_Size__c));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting Generic Batch Action: ' + JSON.serializePretty(genericBatchAction));
        return Database.getQueryLocator(genericBatchAction.Query__c);
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        switch on genericBatchAction.Operation__c {
            when 'Delete' {
                deleteRecords(records);
            }
            when 'Update' {
                updateRecords(records, (Map<String, Object>)JSON.deserializeUntyped(genericBatchAction.Params__c));
            }
            when 'Flow' {
                executeFlow(records);
            }
        }
    }

    private void deleteRecords(List<SObject> records) {
        List<Database.DeleteResult> deleteResults = Database.delete(records, false);
        for(Database.DeleteResult result : deleteResults) {
            if(!result.isSuccess()) {
                Id recordId = result.getId();
                errorsMap.put(recordId, recordId + ': ' + result.getErrors()[0].getMessage());
            }
        }
    }

    private void updateRecords(List<SObject> records, Map<String, Object> params) {
        // update hard coded values from Params__s json, key - field api name, value - hard coded value
        System.debug('updating the following fields: ' + JSON.serializePretty(params));
        Set<String> paramsKeys = params.keySet();
        for(SObject record : records) {
            for(String key : paramsKeys) {
                record.put(key, params.get(key));
            }
        }

        List<Database.SaveResult> updateResults = Database.update(records, false);
        for(Database.SaveResult result : updateResults) {
            if(!result.isSuccess()) {
                Id recordId = result.getId();
                errorsMap.put(recordId, recordId + ': ' + result.getErrors()[0].getMessage());
            }
        }
    }

    private void executeFlow(List<SObject> records) {
        String resultCode, resultMessage;
        try {
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(genericBatchAction.Params__c);
            params.put('records', records);
            String flowApiName = (String)params.remove('flowApiName');
            Flow.Interview interview = Flow.Interview.createInterview(flowApiName, params);
            interview.start();
            resultCode = (String)interview.getVariableValue('resultCode');
            resultMessage = (String)interview.getVariableValue('resultMessage');
        } catch(Exception ex) {
            resultCode = '99';
            resultMessage = ex.getMessage();
        }

        if(resultCode != '0') {
            errorsMap.put('Flow Error #' + (errorsMap.size() + 1) + ' with result code ' + resultCode, resultMessage);
        }
    }

    public void finish(Database.BatchableContext bc) {
        if(errorsMap.isEmpty()) {
        
            return;
        }

        Map<String, String> errorsChunk = new Map<String, String>();        
        String message = 'GenericBatchAction "' + genericBatchAction.DeveloperName + '" failed to manipulate records\nDetails on Request/Response fields\nConfig: ' + JSON.serializePretty(genericBatchAction);

        if(errorsMap.size() < MAX_RECORDS_PER_LOG) {
            buildLogEntryData(errorsMap,message);
        }
        else {
            for(String key : errorsMap.keySet()) {
                errorsChunk.put(key, errorsMap.get(key));
                if(errorsChunk.size() == MAX_RECORDS_PER_LOG) {
                    // limit the size of the log record by separating it to chunks of errors to be added in multiple records
                    buildLogEntryData(errorsChunk, message);
                    errorsChunk.clear();
                }
            }
        }
    }

    private void buildLogEntryData(Map<String, String> errosMap, String message) {
        List<String> keys = new List<String>(errosMap.keySet());
        List<EP_Log__c> logRecords = new List<EP_Log__c>();

        for(String key : errorsMap.keySet()) {
                EP_Log__c logRecord = (EP_Log__c) LogHandler.getLog('', '', '', errorsMap.get(key), UserInfo.getUserId(), 0, message ,genericBatchAction.DeveloperName, 'GenericBatchAction',false,null);
                logRecords.add(logRecord);
            }
        // save error to logs
        insert logRecords;
    }
}