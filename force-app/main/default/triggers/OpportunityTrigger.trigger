trigger OpportunityTrigger on Opportunity (before update, after update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate){
            for (Opportunity opp : Trigger.new) {
                if (opp.Amount <= 5000) {
                    opp.addError('Opportunity amount must be greater than 5000');
                }
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
    if (Trigger.isAfter) {
        if (Trigger.IsUpdate) {
            Set<Id> acctIds = new Set<Id> ();
            for (Opportunity opp : Trigger.new) {
                acctIds.add(opp.accountId);
            }
            Map<Id, Contact> ceoContacts = new Map<Id, Contact> ();
            for (Contact cont : [SELECT Id, AccountId 
                                FROM Contact 
                                WHERE Title = 'CEO' AND AccountId IN :acctIds ]) {
                ceoContacts.put(cont.AccountId, cont);
            }
            List<Opportunity> oppsToUpdate = new List<Opportunity> ();
            for (Opportunity opp : Trigger.new) {
                Contact contCEO = ceoContacts.get(opp.AccountId);
                Opportunity updatedOpp = new Opportunity();
                updatedOpp.Id = opp.Id;
                updatedOpp.Primary_Contact__c = contCEO.Id;
                oppsToUpdate.add(updatedOpp);
            }
            update oppsToUpdate;
        }
    }
}