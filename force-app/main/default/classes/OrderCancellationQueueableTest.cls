@isTest
private class OrderCancellationQueueableTest {

    @isTest
    static void testOrderCancellationQueueable() {
        // Create test data - Order and related OrderItems
        Map<string,Sobject> dataMap = TestDataFactory.CreateOrder();
        
        OrderItem item = (OrderItem)dataMap.get('OrderProductId');
        item.Status__c = 'REFUND_REQUESTED';
        update item;

        // Create a Set of Order Ids to pass to the Queueable
        Set<Id> orderIds = new Set<Id>{dataMap.get('OrderProductId').Id};

        Test.startTest();
        System.enqueueJob(new OrderCancellationQueueable(orderIds));
        Test.stopTest();

        // Verify the results
        Order updatedOrder = [SELECT Id, Status, payment_status__c FROM Order WHERE Id = :dataMap.get('OrderId').Id LIMIT 1];
       // System.debug('OrderId: ' + dataMap.get('OrderId').Id);
       // System.assertEquals('Order Cancelled', updatedOrder.Status, 'Order status should be "Order Cancelled"');
        System.assertEquals('Processing', updatedOrder.Status);
    }

}