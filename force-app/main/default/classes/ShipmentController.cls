public with sharing class ShipmentController {
    @AuraEnabled(cacheable=true)
    public static List<Shipment> getShipments() {
        try {
            return [
                SELECT Id, ShipmentNumber, Order__r.OrderNumber, 
                       DestinationLocation.Name, SourceLocation.Name, ActualDeliveryDate, 
                       Invoice_Amount__c, Invoice_Date__c, Invoice_No__c, Invoice_URL__c, 
                       Driver_Phone__c, E_Way_bill__c, LR_Date__c, LR_Number__c
                FROM Shipment
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Shipments: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getDealerInfoOnOrder(Id orderId) {
        try {
            return [
                SELECT Id, Contact__r.Name, Contact__r.Email, Contact__r.Phone from Order where Id =:orderId
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Shipments: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderProducts(Id orderId) {
        System.debug('Order ID received in Apex: ' + orderId);
        try {
            List<OrderItem> orderItems = [
                SELECT Id, Product2Id, Product2.Name, Quantity, Shipped_Quantity__c , Outstanding_Quantity__c, UnitPrice,  Order.Id
                FROM OrderItem
                WHERE OrderId = :orderId
            ];
            System.debug('Order Items fetched: ' + orderItems);
            for (OrderItem item : orderItems) {
            System.debug('OrderItem: ' + item);
            System.debug('Shipped Quantity: ' + item.Shipped_Quantity__c);
            System.debug('Available Quantity: ' + item.Outstanding_Quantity__c);
        }
            return orderItems;
        } catch (Exception e) {
            System.debug('Error fetching Order Products: ' + e.getMessage());
            throw new AuraHandledException('Error fetching Order Products: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOrderItems(List<OrderItem> updates) {
        try {
            update updates;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Order Items: ' + e.getMessage());
        }
    }

    

    @AuraEnabled
    public static void updateExistingOrderStatus(Id orderId){
        try {

            Order orderToUpdate = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        orderToUpdate.Status = 'Invoice Generation'; 
        update orderToUpdate;
        //Invoice Generation
            
        } catch (Exception e) {
             System.debug('Error updating Order Status: ' + e.getMessage());
            throw new AuraHandledException('Error updating Order Status: ' + e.getMessage());
        }
    }



@AuraEnabled
public static Id createShipment(Id orderId, Shipment shipment) {
    System.debug('Order ID received in Apex: ' + shipment.Order__c);
    shipment.Order__c = orderId;

    // Hardcoded Source Location ID
    Id hardcodedSourceLocationId = '131F4000000Cv5UIAS';

    try {
        // Fetch the Purchase Order ID from the Order
        Order orderRecord = [
            SELECT Purchase_Order__c
            FROM Order 
            WHERE Id = :orderId 
            LIMIT 1
        ];

        // Ensure the Purchase Order ID is not null
        Id purchaseOrderId = orderRecord.Purchase_Order__c;
        if (purchaseOrderId == null) {
            throw new AuraHandledException('The Order does not have an associated Purchase Order.');
        }
        

        // Fetch the Destination Location from the Purchase Order
        ProductRequest purchaseOrder = [
            SELECT Destination_Location__c 
            FROM ProductRequest 
            WHERE Id = :purchaseOrderId
            LIMIT 1
        ];

        // Ensure the Destination Location is not null
        Id destinationLocationId = purchaseOrder.Destination_Location__c;
        if (destinationLocationId == null) {
            throw new AuraHandledException('The Purchase Order does not have a Destination Location.');
        }

        // Set the hardcoded Source Location and dynamic Destination Location
        shipment.SourceLocationId = hardcodedSourceLocationId;
        shipment.DestinationLocationId = destinationLocationId;

        insert shipment;
        updateExistingOrderStatus(orderId);

        System.debug('Inserted Shipment: ' + shipment);
        System.debug('Shipment Id::::' + shipment.Id);
        return shipment.Id;
    } catch (Exception e) {
        System.debug('Error creating Shipment: ' + e.getMessage());
        throw new AuraHandledException('Error creating Shipment: ' + e.getMessage());
    }
}


    @AuraEnabled
    public static void createShipmentItems(Id shipmentId, List<Id> orderProductIds, List<Decimal> quantities) {
        System.debug('in createShipmentItems method...');
        System.debug('shipmentId: ' + shipmentId);
        System.debug('orderProductIds: ' + orderProductIds);
        System.debug('quantities: ' + quantities);

    try {
        List<ShipmentItem> shipmentItems = new List<ShipmentItem>();
        for (Integer i = 0; i < orderProductIds.size(); i++) {
            OrderItem oi = [
                SELECT Id, Product2Id
                FROM OrderItem
                WHERE Id = :orderProductIds[i]
                LIMIT 1
            ];
            shipmentItems.add(new ShipmentItem(
                ShipmentId = shipmentId,
                Product2Id = oi.Product2Id,
                Quantity = quantities[i]
            ));
        }
        insert shipmentItems;
    } catch (Exception e) {
        throw new AuraHandledException('Error creating Shipment Items: ' + e.getMessage());
    }
}


}