trigger OpportunityTrigger on Opportunity (before insert) {
if (Trigger.isBefore) {
        if (Trigger.isUpdate){
            for (Opportunity opp : Trigger.new) {
                if (opp.Amount <= 5000) {
                   opp.addError('Opportunity amount must be greater than 5000');
                }
            }
        }
    }
    //List<Contact> newContacts = new List<Contact>();
    if (Trigger.isAfter) {
        if (Trigger.IsUpdate) {
            for (Opportunity opp : Trigger.new) {

            }
        }
        if (Trigger.isDelete) {
            for (Opportunity opp : Trigger.old) {
                if (opp.IsWon == true && opp.Account.Industry == 'Banking') {
                    opp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
    }
}
/*When an opportunity is updated set the primary contact on the opportunity to the contact on the same account with the title of 'CEO'.
    * Trigger should only fire on update.*/