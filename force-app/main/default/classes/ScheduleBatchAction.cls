global with sharing class ScheduleBatchAction {

    public final static String BATCH_DELETE_ACCOUNT_DEVNAME = 'DeleteAccount';
    public final static String BATCH_DELETE_ACCOUNT_LABEL = 'Action Label Test';

    @InvocableMethod(label = 'Schedule Batch Action')
    global static List<actionOutput> ScheduleBatchAction(List<actionInput> input) {
        return new List<actionOutput>{createdScheduledJob(input[0])};
    }
    private static actionOutput createdScheduledJob(actionInput input){
        Boolean success = true;
        String errorMessage = '';
         try{
            GenericBatchAction m = new GenericBatchAction();
            if(Test.isRunningTest()) {
                m.genericBatchActions.put(BATCH_DELETE_ACCOUNT_DEVNAME, genericBatchActionAccountBuilder(BATCH_DELETE_ACCOUNT_DEVNAME, 'Delete', null, 10));
            }
            String cron = input.cron;
            datetime currentDateTime = datetime.now();
            System.schedule(input.actionLabel + ' - ' + input.actionDevName  , cron , m );            
            }catch(Exception e){
                success = false;
                errorMessage =  e.getMessage();
                // EP_Log__c log = (EP_Log__c) LogHandler.getLog('', '', '', '', UserInfo.getUserId(), 0, e.getMessage() ,'', 'ScheduleBatchAction',false,null);                                                     
                // insert log;
        }
        return new actionOutput(success, errorMessage);       
    }
    global class actionInput
    {
        @InvocableVariable(label = 'Cron') global String cron;
        @InvocableVariable(label = 'Batch Action DeveloperName') global String actionDevName;
        @InvocableVariable(label = 'Batch Action Label') global String actionLabel;
        public actionInput(String cron, String actionDevName, String actionLabel){
            this.cron = cron;
            this.actionDevName = actionDevName;
            this.actionLabel = actionLabel;
        }
        public actionInput(){}
    }
    global class actionOutput
    {
        @InvocableVariable(label = 'Success') global Boolean success;
        @InvocableVariable(label = 'Error Message') global String errorMessage;
        public actionOutput(Boolean success, String errorMessage){
            this.success = success;
            this.errorMessage = errorMessage;
        }
        public actionOutput(){}
    }

    public static GenericBatchAction__mdt genericBatchActionAccountBuilder(String actionName, String operation, String paramsJson, Integer recordsQuantity) {
        return new GenericBatchAction__mdt(
                DeveloperName = actionName,
                Query__c = 'SELECT Id FROM Account ALL ROWS',
                Params__c = paramsJson,
                Operation__c = operation,
                Chunk_Size__c = recordsQuantity
        );
    }
}