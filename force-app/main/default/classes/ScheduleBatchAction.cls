global with sharing class ScheduleBatchAction {
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
            }

            String cron = input.runNow ? getCronExpressionOfNow() :  input.cron;
            datetime currentDateTime = datetime.now();
            System.schedule(input.actionLabel + ' - ' + input.actionDevName  , cron , m );            
            }catch(Exception e){
                success = false;
                errorMessage =  e.getMessage();
        }
        return new actionOutput(success, errorMessage);       
    }

    private static String getCronExpressionOfNow() {
        Datetime now = System.now().addMinutes(1);
        // Extract the components of the current date and time
        Integer second = now.second();
        Integer minute = now.minute();
        Integer hour = now.hour();
        Integer day = now.day();
        Integer month = now.month();
        Integer year = now.year();

        // Convert the month number to the three-letter abbreviation
        String monthAbbreviation = now.format('MMM').toUpperCase();

        // Construct the cron expression
        String cronExpression = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + monthAbbreviation + ' ? ' + year;
        return cronExpression;

    }
    global class actionInput
    {   
        @InvocableVariable(label = 'Run Now') global Boolean runNow;
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
}