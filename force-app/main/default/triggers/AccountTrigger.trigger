trigger AccountTrigger on Account (before insert, after insert) {
system.debug('Account trigger::: ' + Trigger.operationType);
system.debug(Trigger.new);

if (Trigger.isBefore) {
    if (Trigger.isInsert){
        for (Account acct : Trigger.new){
            if (acct.Type == null) {
            acct.Type = 'Prospect';
            }
            if (acct.ShippingAddress != null) {
                acct.ShippingStreet = acct.BillingStreet;
                acct.ShippingCity = acct.BillingCity;
                acct.ShippingState = acct.BillingState;
                acct.ShippingPostalCode = acct.BillingPostalCode;
                acct.ShippingCountry = acct.BillingCountry; 
            }
            if (acct.Phone != null && acct.Website != null && acct.Fax != null) {
                acct.Rating = 'Hot';
            }
        }
    }
}
List<Contact> newContacts = new List<Contact>();
if (Trigger.isAfter) {
    if (Trigger.isInsert){
        for (Account acct : Trigger.new){
            newContacts.add(new Contact(
                AccountId = acct.Id,
                LastName = 'DefaultContact',
                Email = 'default@email.com'));
        }
        insert newContacts;
    }
}
}