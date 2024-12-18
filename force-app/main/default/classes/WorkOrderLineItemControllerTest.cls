@isTest
public class WorkOrderLineItemControllerTest {
    // Common test data setup
    @testSetup
    static void setupTestData() {
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        // Create test data
        WorkOrder testWorkOrder = new WorkOrder(
            Status = 'New',
            Subject = 'Test Work Order',
            Odometer_Reading__c= 120,
            Pricebook2Id = standardPricebook.Id  // Associate the standard pricebook with the WorkOrder
        );
        insert testWorkOrder;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            IsActive = true,
            HSN_Code__c = '001',
            Type__c = 'Parts'
        );
        insert testProduct;

        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100, // Set your desired unit price
            IsActive = true
        );
        insert standardPricebookEntry;

        WorkOrderLineItem testWorkOrderLineItem = new WorkOrderLineItem(
            WorkOrderId = testWorkOrder.Id,
            PricebookEntryId = standardPricebookEntry.Id, // Use the Pricebook Entry ID here
            Quantity = 1,
            Status = 'New'
        );
        insert testWorkOrderLineItem;
    }

    // Test method for getting related work order line items
    @isTest
    static void testGetRelatedWorkOrderLineItems() {
        // Retrieve the test work order
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder LIMIT 1];
        System.debug('Retrieved workOrders: ' + workOrders);

        // Assert that at least one WorkOrder exists
        System.assertNotEquals(0, workOrders.size(), 'No WorkOrders found');

        WorkOrder testWorkOrder = workOrders[0];
        System.debug('Using testWorkOrder: ' + testWorkOrder.Id);

        // Call the method to test
        Test.startTest();
        List<WorkOrderLineItem> result = WorkOrderLineItemController.getRelatedWorkOrderLineItems(testWorkOrder.Id);
        Test.stopTest();
        System.debug('Retrieved WorkOrderLineItems: ' + result);

        // Verify the results
        System.assertEquals(1, result.size(), 'Result size should be 1');
        System.assertEquals(testWorkOrder.Id, result[0].WorkOrderId, 'WorkOrderId should match the test Work Order Id');
        System.assertEquals(1, result[0].Quantity, 'Quantity should be 1');
        System.assertEquals('New', result[0].Status, 'Status should be "New"');
    }
}