trigger AccountTrigger on Account (before insert, after insert) {
if (Trigger.isBefore) {
        if (Trigger.isInsert){
            for (Account acct : Trigger.new) {
                if (acct.Type == null) {
                    acct.Type = 'Prospect';
                }
                if (acct.ShippingStreet != null &&
                    acct.ShippingCity != null &&
                    acct.ShippingState != null &&
                    acct.ShippingPostalCode != null &&
                    acct.ShippingCountry != null) {
                    acct.BillingStreet = acct.ShippingStreet;
                    acct.BillingCity = acct.ShippingCity;
                    acct.BillingState = acct.ShippingState;
                    acct.BillingPostalCode = acct.ShippingPostalCode;
                    acct.BillingCountry = acct.ShippingCountry;
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
            for (Account acct : Trigger.new) {
                newContacts.add(new Contact(
                    AccountId = acct.Id,
                LastName = 'DefaultContact',
                Email = 'default@email.com'));
            }
            insert newContacts;
        }
    }
}