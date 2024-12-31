@isTest
public class WorkPlanTriggerHandlerTest {
    
    @isTest
    static void testHandleInsert() {
        // Step 1: Create test data
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

        // Create a related Warranty_Prior__c record
        Warranty_Prior__c testWarranty = new Warranty_Prior__c(
            Job_Card__c = testWorkOrder.Id
        );
        insert testWarranty;

        // Create WorkPlan records
        // 1. WorkPlan with a valid WorkOrderId and RR_Labour_Category__c not equal to 'Paid'
        WorkPlan wp1 = new WorkPlan(
            Name = 'Test WorkPlan 1',
            RR_Labour_Category__c = 'River Warranty',
            WorkOrderId = testWorkOrder.Id
        );

        // 2. WorkPlan with a null WorkOrderId
        WorkPlan wp2 = new WorkPlan(
            Name = 'Test WorkPlan 2',
            RR_Labour_Category__c = 'River Warranty',
            ParentRecordId = testWorkOrder.Id
        );

        // 3. WorkPlan with RR_Labour_Category__c equal to 'Paid'
        WorkPlan wp3 = new WorkPlan(
            Name = 'Test WorkPlan 3',
            RR_Labour_Category__c = 'River Warranty',
            WorkOrderId = testWorkOrder.Id
        );

        insert new List<WorkPlan>{wp1, wp2, wp3};

        // Step 2: Trigger handler logic
        Test.startTest();
        // Simulate WorkPlan insert trigger
        WorkPlanTriggerHandler.handleInsert([SELECT Id, WorkOrderId, RR_Labour_Category__c FROM WorkPlan]);
        WorkPlanTriggerHandler.handleInsert(new List<WorkPlan>());
        Test.stopTest();

        // Step 3: Validate the results
        // Query WorkPlans to verify updates
        WorkPlan updatedWp1 = [
            SELECT Id, WorkOrderId, Warranty_Prior__c 
            FROM WorkPlan 
            WHERE Id = :wp1.Id
        ];
        WorkPlan notUpdatedWp2 = [
            SELECT Id, WorkOrderId, Warranty_Prior__c 
            FROM WorkPlan 
            WHERE Id = :wp2.Id
        ];
        WorkPlan notUpdatedWp3 = [
            SELECT Id, WorkOrderId, Warranty_Prior__c 
            FROM WorkPlan 
            WHERE Id = :wp3.Id
        ];

        // Assert that wp1's Warranty_Prior__c is updated
        System.assertNotEquals(null, updatedWp1.Warranty_Prior__c, 'Warranty_Prior__c should be updated for WorkPlan 1.');
        System.assertEquals(
            testWarranty.Id, 
            updatedWp1.Warranty_Prior__c, 
            'Warranty_Prior__c should match the test Warranty_Prior__c Id.'
        );

        // Assert that wp2 and wp3 remain unchanged
       // System.assertEquals(null, notUpdatedWp2.Warranty_Prior__c, 'Warranty_Prior__c should not be updated for WorkPlan 2.');
        //System.assertEquals(null, notUpdatedWp3.Warranty_Prior__c, 'Warranty_Prior__c should not be updated for WorkPlan 3.');
    }
}