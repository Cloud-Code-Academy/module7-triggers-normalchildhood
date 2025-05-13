/*
* Complete the following exercises based on the tests.
* Create triggers on account and on opportunity.
*
* Account trigger should do the following:
* 1. Set the account type to prospect.
* 2. Copy the shipping address to the billing address.
* 3. Set the account rating to hot.
* 4. Create a contact for each account inserted.
*
* Opportunity trigger should do the following:
* 1. Validate that the amount is greater than 5000.
* 2. Prevent the deletion of a closed won opportunity for a banking account.
* 3. Set the primary contact on the opportunity to the contact with the title of CEO.
*
* RESOURCES: 
* - Trigger Context Variables: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_context_variables.htm
* - Context Variable Considerations: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_context_variables_considerations.htm
* - Get Started with Apex Triggers: https://trailhead.salesforce.com/content/learn/modules/apex_triggers/apex_triggers_intro
* NOTE: Disable all duplicate rules in the org. This will help prevent errors in the test classes or triggers. https://help.salesforce.com/s/articleView?id=sfdo.EDA_Disable_Matching_Rules.htm&type=5
* Click Setup, then click Setup.> From Setup, enter Matching Rules in the Quick Find box, then click Matching Rules. > Click Deactivate next all to the rule that needs to be disabled.
*/

@IsTest
public with sharing class TriggerTest {

    /*
    * Question 1
    * Account Trigger
    * When an account is inserted change the account type to 'Prospect' if there is no value in the type field.
    * Trigger should only fire on insert.
    */
    @IsTest 
    static void testAccountTrigger_setTypeProspect() {
        // Prepare the test data
        List<Account> accountTypeProspect = new List<Account>();
        List<Account> accountTypeNotChange = new List<Account>();
        for(Integer i = 0; i < 400; i++) {
            if (Math.mod(i, 2) == 0){
                accountTypeProspect.add(new Account(Name = 'Test Account ' + i));
            } else {
                accountTypeNotChange.add(new Account(Name = 'Test Account ' + i, Type = 'Customer'));
            }
            
        }
        
        // Perform the test
        Test.startTest();
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(accountTypeProspect, dml);
        Database.insert(accountTypeNotChange, dml);
        Test.stopTest();
        
        // Retrieve the accounts again
        List<Account> prospectAccounts = [SELECT Id, Type FROM Account WHERE Type = 'Prospect'];

        // Assert that the number of accounts inserted is correct
        System.assertEquals(200, prospectAccounts.size(), 'Number of accounts inserted is incorrect.');
        
        // Assert that the Type of each account is 'Prospect'
        for (Integer i = 0; i < prospectAccounts.size(); i++) {
            Account acc = prospectAccounts[i];
            System.assertEquals('Prospect', acc.Type, 'Account Type is incorrect.');
            if (Math.mod(i, 2) == 0){
                acc.Type = 'Customer';
            } else {
                acc.Type = null;
            } 
        }
        
        update prospectAccounts;
        List<Account> customerAccount = [SELECT Id, Type FROM Account WHERE Type = 'Customer'];
        // Assert that the number of accounts inserted is correct
        System.assertEquals(300, customerAccount.size(), 'Number of accounts updated is incorrect.');

    }

    /*
    * Question 2
    * Account Trigger
    * When an account is inserted copy the shipping address to the billing address.
    * BONUS: Check if the shipping fields are empty before copying.
    * Trigger should only fire on insert.
    */
    @IsTest 
    static void testAccountTrigger_addressCopy() {
        // Prepare the test data
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                ShippingStreet = '123 Test St ' + i,
                ShippingCity = 'Test City ' + i,
                ShippingState = 'TS',
                ShippingPostalCode = '12345',
                ShippingCountry = 'Test Country ' + i,
                AnnualRevenue = i
            );
            accountsToInsert.add(acc);
        }

        // Perform the test
        Test.startTest();
        insert accountsToInsert;
        Test.stopTest();

        // Retrieve the accounts again
        List<Account> insertedAccounts = [SELECT Id, 
                                          BillingStreet, 
                                          BillingCity, 
                                          BillingState, 
                                          BillingPostalCode, 
                                          BillingCountry 
                                          FROM Account 
                                          WHERE Id IN :accountsToInsert
                                          ORDER BY AnnualRevenue ASC];

        // Assert that the Billing Address fields have been correctly copied from the Shipping Address for each account
        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            System.assertEquals('123 Test St ' + i, insertedAccounts[i].BillingStreet, 'BillingStreet not correctly copied for account ' + i + '.');
            System.assertEquals('Test City ' + i, insertedAccounts[i].BillingCity, 'BillingCity not correctly copied for account ' + i + '.');
            System.assertEquals('TS', insertedAccounts[i].BillingState, 'BillingState not correctly copied for account ' + i + '.');
            System.assertEquals('12345', insertedAccounts[i].BillingPostalCode, 'BillingPostalCode not correctly copied for account ' + i + '.');
            System.assertEquals('Test Country ' + i, insertedAccounts[i].BillingCountry, 'BillingCountry not correctly copied for account ' + i + '.');
            insertedAccounts[i].ShippingStreet = '321 Test St';
        }

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true; 
        Database.update(insertedAccounts, dml); 

        List<Account> updatedAccounts = [SELECT Id, BillingStreet, AnnualRevenue FROM Account WHERE Id IN :insertedAccounts ORDER BY AnnualRevenue ASC];
        // Assert that billing address has not been changed
        for (Account acc : updatedAccounts) {
            System.assertEquals('123 Test St ' + String.valueOf(acc.AnnualRevenue), acc.BillingStreet, 'Billing Street should not change on update.');
        }
    }

    /*
    * Question 3
    * Account Trigger
	* When an account is inserted set the rating to 'Hot' if the Phone, Website, and Fax ALL have a value.
    * Trigger should only fire on insert.
    */
    @IsTest 
    static void testAccountTrigger_setRating() {
        // Prepare the test data
        List<Account> accountsToInsert = new List<Account>();
        List<Account> accountsNotHot = new List<Account>();
        for (Integer i = 0; i < 400; i++) {
            if (Math.mod(0,2) == 0) {
                Account acc = new Account(
                    Name = 'Test Account ' + i,
                    Phone = '1234567890',
                    Website = 'www.testwebsite' + i + '.com',
                    Fax = '0987654321'
                );
                accountsToInsert.add(acc);
            } else {
                Account acc = new Account(
                    Name = 'Test Account ' + i,
                    Rating = 'Warm'
                );
                accountsNotHot.add(acc);
            }            
        }

        // Perform the test
        Test.startTest();
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(accountsToInsert, dml);
        Database.insert(accountsNotHot, dml);
        Test.stopTest();

        // Retrieve the accounts again
        List<Account> insertedAccounts = [SELECT Id, Rating FROM Account WHERE Id IN :accountsToInsert];

        // Assert that the Rating field has been correctly set to 'Hot' for each account
        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            System.assertEquals('Hot', insertedAccounts[i].Rating, 'Rating not correctly set to Hot for account ' + i + '.');
            insertedAccounts[i].Rating = null;
        }

        update insertedAccounts;
        List<Account> updatedAccounts = [SELECT Id, Rating FROM Account WHERE Id IN :insertedAccounts];
        for (Account acc : updatedAccounts) {
            System.assertEquals(null, acc.Rating, 'Rating should not change on update.');
        }

        // Retrieve the accounts again
        List<Account> insertedAccountsNotHot = [SELECT Id, Rating FROM Account WHERE Id IN :accountsNotHot];

        // Assert that the Rating field has not been changed for each account
        for (Integer i = 0; i < insertedAccountsNotHot.size(); i++) {
            System.assertEquals('Warm', insertedAccountsNotHot[i].Rating, 'Rating incorrectly changed for account ' + i + '.');
        }
    }

    /*
    * Question 4
    * Account Trigger
    * When an account is inserted create a contact related to the account with the following default values:
    * LastName = 'DefaultContact'
    * Email = 'default@email.com'
    * Trigger should only fire on insert.
    */
    @IsTest
    static void testAccountTrigger_defaultContact() {
        // Prepare the test data
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < 400; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            accountsToInsert.add(acc);
        }

        // Perform the test
        Test.startTest();
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(accountsToInsert, dml);
        Test.stopTest();

        // Retrieve the newly created Contacts
        List<Contact> contacts = [SELECT Id, LastName, Email, AccountId FROM Contact WHERE AccountId IN :accountsToInsert];

        // Assert that the correct number of Contacts has been created
        System.assertEquals(400, contacts.size(), 'Incorrect number of Contacts created.');

        // Assert that each Contact has the expected field values
        for (Contact con : contacts) {
            System.assertEquals('DefaultContact', con.LastName, 'Contact LastName is incorrect.');
            System.assertEquals('default@email.com', con.Email, 'Contact Email is incorrect.');
            System.assertNotEquals(null, con.AccountId, 'Contact AccountId is null.');
        }

        delete contacts;
        for (Account acc : accountsToInsert) {
            acc.Name = 'Test Account Updated';
        }

        update accountsToInsert;

        List<Contact> updatedContacts = [SELECT Id, LastName, Email, AccountId FROM Contact];
        // Assert that the Contacts no contacts exists
        System.assertEquals(0, updatedContacts.size(), 'Contacts should not exist.');
    }

    /*
    * Question 5
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Error Message: 'Opportunity amount must be greater than 5000'
    * Trigger should only fire on update.
    */
    @IsTest
    static void testOpportunityTrigger_amountValidation() {
        // Prepare the test data
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for (Integer i = 0; i < 400; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                CloseDate = Date.today().addDays(i),
                StageName = 'Prospecting',
                Amount = 6000 // The initial Amount is greater than 5000
            );
            opportunitiesToInsert.add(opp);
        }
        insert opportunitiesToInsert;

        List<Opportunity> oppsTriggerValidation = new List<Opportunity>();
        List<Opportunity> oppsNotTriggerValidation = new List<Opportunity>();
        // Try to update the opportunities to have an Amount less than 5000
        for (Integer i = 0; i < 400; i++) {
            if (Math.mod(i,2) == 0) {
                opportunitiesToInsert[i].Amount = 4000;
                oppsTriggerValidation.add(opportunitiesToInsert[i]);
            } else {
                opportunitiesToInsert[i].Amount = 8000;
                oppsNotTriggerValidation.add(opportunitiesToInsert[i]);
            }
        }

        // Perform the test and assert that an error is thrown
        Test.startTest();
        try {
            update opportunitiesToInsert;
            System.assert(false, 'Expected an exception but did not get one.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Opportunity amount must be greater than 5000'), 'The error message is not as expected. Message: ' + e.getMessage());
        }

        // Assert that the opportunities that should not trigger the validation rule have been updated
        update oppsNotTriggerValidation;
        List<Opportunity> oppsNotTriggerValidationUpdated = [SELECT Id, Amount FROM Opportunity WHERE Id IN :oppsNotTriggerValidation];
        for (Opportunity opp : oppsNotTriggerValidationUpdated) {
            System.assertEquals(8000, opp.Amount, 'Opportunity Amount is incorrect.');
        }
        Test.stopTest();
    }

	/*
     * Question 6
	 * Opportunity Trigger
	 * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
	 * Error Message: 'Cannot delete closed opportunity for a banking account that is won'
	 * Trigger should only fire on delete.
	 */
    @IsTest
    static void testOpportunityTrigger_deleteCloseWonOpportunity() {
        // Prepare the test data
        Account testAccount = new Account(Name = 'Test Account', Industry = 'Banking');
        insert testAccount;

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for (Integer i = 0; i < 400; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                CloseDate = Date.today().addDays(i),
                StageName = 'Closed Won',
                Amount = 6000,
                AccountId = testAccount.Id
            );
            opportunitiesToInsert.add(opp);
        }
        insert opportunitiesToInsert;

        // Try to delete the opportunities
        Test.startTest();
        try {
            delete opportunitiesToInsert;
            System.assert(false, 'Expected an exception but did not get one.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete closed opportunity for a banking account that is won'), 'The error message is not as expected.');
        }
        Test.stopTest();
    }

    /*
    * Question 7
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact on the same account with the title of 'CEO'.
    * Trigger should only fire on update.
    */
    @IsTest
    static void testOpportunityTrigger_setPrimaryContact() {
        // Prepare the test data
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account testAccount = new Account(Name = 'Test Account ' + i);
            accountsToInsert.add(testAccount);
        }
        
        insert accountsToInsert;

        List<Contact> contactsToInsert = new List<Contact>();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for (Account acc : accountsToInsert) {            
            for (Integer i = 0; i < 10; i++) {
                Contact con = new Contact(
                    FirstName = String.valueOf(i),
                    LastName = 'Last Name ' + i,
                    AccountId = acc.Id
                );
                if (i == 0) {
                    con.Title = 'CEO';
                    con.FirstName = 'Big Boss';
                }
                contactsToInsert.add(con);
            }  
            
            for (Integer i = 0; i < 10; i++) {
                Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity ' + i,
                    CloseDate = Date.today().addDays(i),
                    StageName = 'Prospecting',
                    Amount = 6000,
                    AccountId = acc.Id,
                    Primary_Contact__c = null
                );
                opportunitiesToInsert.add(opp);
            }
            
        }

        // Update the opportunities
        Test.startTest();

        insert contactsToInsert;
        insert opportunitiesToInsert;

        for (Opportunity opp : opportunitiesToInsert) {
            opp.Primary_Contact__c = null;
        }
        update opportunitiesToInsert;
        Test.stopTest();

        // Check that the primary contact is set correctly
        List<Opportunity> updatedOpportunities = [SELECT Primary_Contact__c, Primary_Contact__r.FirstName, Primary_Contact__r.Title FROM Opportunity WHERE Id IN :opportunitiesToInsert];
        for (Opportunity opp : updatedOpportunities) {
            System.assertNotEquals(null, opp.Primary_Contact__c, 'Primary contact was not set.');
            System.assertEquals(opp.Primary_Contact__r.FirstName, 'Big Boss', 'Primary contact was not set correctly.');
            System.assertEquals(opp.Primary_Contact__r.Title, 'CEO', 'Primary contact was not set correctly.');
        }
    }

}