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
            Set<Id> acctIds = new Set<Id>();
            for (Opportunity opp : Trigger.old) {
                acctIds.add(opp.AccountId);
            }
            Map<Id, Account> acctMap = new Map<Id, Account> ([SELECT Id, Industry FROM Account WHERE Id IN :acctIds]);
            for (Opportunity opp : Trigger.old) {
                Account acct = acctMap.get(opp.AccountId);
                if (opp.IsWon == true && acct != null && acct.Industry == 'Banking') {
                    opp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
        if (Trigger.isAfter) {
            if (Trigger.IsUpdate) {
                Set<Id> acctIds = new Set<Id> ();
                for (Opportunity opp : Trigger.new) {
                    acctIds.add(opp.accountId); //this loop adds the acct ids from the opps that were updated into a set
                }
                Map<Id, Contact> ceoContacts = new Map<Id, Contact> ();
                for (Contact cont : [SELECT Id, AccountId 
                                FROM Contact 
                                WHERE Title = 'CEO' AND AccountId IN :acctIds ]) {
                    ceoContacts.put(cont.AccountId, cont); //this loop adds each contact that fits the query into a map with the acct id & contact
                }
                List<Opportunity> oppsToUpdate = new List<Opportunity> ();
                //this loop goes through each opp that was updated and adds the id to the list to update & updates the primary contact with one from the map
                for (Opportunity opp : Trigger.new) {
                    Contact contCEO = ceoContacts.get(opp.AccountId); //this sets the contact to be the one from the map that matches the acct id that's on the opp
                    if (opp.Primary_Contact__c == contCEO.Id) { //checks if contact already matches and stops if it does; otherwise continuous loop of updates
                        continue;
                    }
                    else {
                        Opportunity updatedOpp = new Opportunity();
                        updatedOpp.Id = opp.Id;
                        updatedOpp.Primary_Contact__c = contCEO.Id;
                        oppsToUpdate.add(updatedOpp);
                    }
                    
                }
                update oppsToUpdate;
            }
        }
    }
}