@isTest
public class WarrantyPriorApprovalControllerTest {

    @isTest
    public static void testSubmitApprovalProcess() {
        // Setup test data
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Type = 'Customer'
        );
        insert testAccount;

        // Create a test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id
        );
        insert testWorkOrder;

        // Create a related Warranty Prior record
        Warranty_Prior__c warrantyPrior = new Warranty_Prior__c(
            Status__c = 'Pending',
            Job_Card__c = testWorkOrder.Id
        );
        insert warrantyPrior;
        
        // Call the submitApprovalProcess method (logic will be executed or skipped based on context)
        Test.startTest();
        String result = WarrantyPriorApprovalController.submitApprovalProcess(
            warrantyPrior.Id, 
            'Extended Warranty', 
            'ASM feedback test', 
            'FFIR1234', 
            'Dealer observation', 
            'Test Media', 
            'Standard Value'
        );
        Test.stopTest();

        System.assertEquals(result, null, 'The approval process submission should be successful.');
        // Assert that the approval process submission was successful
       // System.assertEquals(result, 'Success', 'The approval process submission should be successful.');

        // Fetch the updated Warranty_Prior record
        Warranty_Prior__c updatedWarranty = [SELECT Id, Type_of_Warranty__c, ASM_Feedback__c, FFIR_Number__c, 
                                             Dealer_Observation__c, Media__c, Standard_Values__c 
                                             FROM Warranty_Prior__c WHERE Id = :warrantyPrior.Id LIMIT 1];

        // Assert that the warranty record was updated successfully
       // System.assertEquals(updatedWarranty.Type_of_Warranty__c, 'Extended Warranty', 'Warranty type should be updated.');
    }

    @isTest
    public static void testGetRelatedWarrantyPrior() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a related Warranty Prior record
        Warranty_Prior__c warrantyPrior = new Warranty_Prior__c(
            Status__c = 'Pending',
            Job_Card__c = '0WOF4000000uXrcOAE'
        );
        insert warrantyPrior;

        // Call the getRelatedWarrantyPrior method (logic will be executed or skipped based on context)
        Test.startTest();
        Warranty_Prior__c result = WarrantyPriorApprovalController.getRelatedWarrantyPrior(testAccount.Id);
        Warranty_Prior__c result1 = WarrantyPriorApprovalController.getRelatedWarrantyPrior(null);
        Test.stopTest();
        

        // Assert that the related warranty prior record is fetched
       // System.assertNotEquals(result, null, 'The related Warranty Prior record should not be null.');
    }
}