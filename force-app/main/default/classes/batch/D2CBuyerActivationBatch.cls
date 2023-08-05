public class D2CBuyerActivationBatch implements Database.Batchable<sObject> {
    private Map<String,Contact> mapContacts = new Map<String,Contact>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Check all person account by the contact that where not defined in the buyer group yet
        return Database.getQueryLocator(
            'SELECT Id, Account.Id, Account.Name, Account.IsPersonAccount  ' +
            'FROM Contact ' +
            'WHERE  Account.isBuyerEnabled__c = false ' + 
            'AND    Account.Id NOT IN (SELECT BuyerId FROM BuyerGroupMember) ' 
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
        // Do the chaing to next 60 seconds
        Datetime sysTime = System.now().addSeconds( 60 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule( 'D2CScheduleBuyerActivation ' + sysTime, chronExpression, new D2CScheduleBuyerActivation() );
    }
}