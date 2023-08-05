public class D2CBuyerMemberQueueable implements Queueable {
    // This queueable process is necessary to add the buyers
    // in the buyer group, and that needs to be done in a different transaction...
    // I mean, not in the same one, where you have activated as buyer
    List<String> memberId = new List<String>();
    public D2CBuyerMemberQueueable(List<String> memberId) {
        this.memberId = memberId;

    }

    public void execute(QueueableContext context) {
        D2CSelfRegistrationHelper.insertBuyerMember(this.memberId);
    }
}