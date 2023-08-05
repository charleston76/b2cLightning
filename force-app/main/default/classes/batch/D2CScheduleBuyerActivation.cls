global class D2CScheduleBuyerActivation implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new D2CBuyerActivationBatch());
     } 
}