public class D2CBuyerActivationBatch implements Database.Batchable<sObject> {
    private Map<String,Contact> mapContacts = new Map<String,Contact>();
    // I have this batch process to run with the system context (not as guest)
    // and activate the buyer and add into the buyer group member
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Check all person account by the contact that where not defined in the buyer group yet
        return Database.getQueryLocator(
            'SELECT Id, Account.Id, Account.Name, Account.IsPersonAccount  ' +
            'FROM Contact ' +
            'WHERE  Account.isBuyerEnabled__c = false ' 
        );
    }
    public void execute(Database.BatchableContext bc,  List<Contact> scope){
        // Check the possible data
        for (Contact rowContact : scope) {
            this.mapContacts.put(rowContact.Id, rowContact);
        }

        createBuyerInformation();
    }

    private void createBuyerInformation(){
        if (this.mapContacts.size() > 0) {D2CSelfRegistrationHelper.createBuyerInformation(mapContacts);}
    }

    public void finish(Database.BatchableContext bc){
        // Do the chaing to next 30 seconds
        // Tha is necessary just if you are working with D2C, to enable the
        // b2c guys automatically...
        // To work just with B2B, you can have more time to have the support team working on it
        Datetime sysTime = System.now().addSeconds( 30 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule( 'D2CScheduleBuyerActivation ' + sysTime, chronExpression, new D2CScheduleBuyerActivation() );
    }
}