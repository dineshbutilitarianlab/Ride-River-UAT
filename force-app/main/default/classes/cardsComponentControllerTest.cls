@isTest
    public class cardsComponentControllerTest {
        @isTest
        public static void cardsComponentControllerTest(){
            Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Email__c = 'test@gmail.com',
            Type = 'Customer'
        );
        insert testAccount;
            
                Contact testContact = new Contact(AccountId=testAccount.Id,LastName='Test Contact',Phone='9876543210');
         insert testContact;
            
           User testUser = new User(ContactId=testContact.Id);
            insert testUser;
            
            Test.startTest();
            cardsComponentController.fetchOnLoadData(testUser.Id);
            Test.stopTest();
            
            
        }

}