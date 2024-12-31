@IsTest(SeeAllData=true)
public class WarrantyPriorTriggerHandlerTest {
    @isTest
    public static void testHandleWarrantyApproval() {
        // Fetch an existing Warranty Prior record with a related Job Card
        Warranty_Prior__c existingWarranty = [SELECT Id, Status__c, Job_Card__c 
                                              FROM Warranty_Prior__c 
                                              WHERE Status__c != 'Approved' 
                                              LIMIT 1];

        if (existingWarranty == null) {
            System.debug('No existing Warranty Prior records found for testing.');
            return;
        }

        // Fetch the related WorkOrder
        WorkOrder relatedWorkOrder = [SELECT Id, AccountId, Vehicle__c 
                                      FROM WorkOrder 
                                      WHERE Id = :existingWarranty.Job_Card__c 
                                      LIMIT 1];

        if (relatedWorkOrder == null) {
            System.debug('No related WorkOrder found for testing.');
            return;
        }

        // Simulate status update to 'Approved'
        Test.startTest();
        existingWarranty.Status__c = 'Approved';
        update existingWarranty;
        Test.stopTest();

        // Validate the claim was created
        List<Claim> claims = [SELECT Id, Name, Status, Warranty_Prior__c, AccountId, Vehicle__c, Job_Card__c
                              FROM Claim 
                              WHERE Warranty_Prior__c = :existingWarranty.Id];

        System.assert(!claims.isEmpty(), 'Claim should be created when Warranty is approved.');
        System.assertEquals('Submitted', claims[0].Status, 'Claim status should be set to Submitted.');
        System.assertEquals(relatedWorkOrder.AccountId, claims[0].AccountId, 'Claim should be linked to the correct Account.');
        System.assertEquals(relatedWorkOrder.Vehicle__c, claims[0].Vehicle__c, 'Claim should be linked to the correct Vehicle.');
    }
}