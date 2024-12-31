public class OrderTriggerHandler {
    
    public static void handleOrderUpdate(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        // Collect Orders where Status changed to 'Vehicle Delivered'
        try{       
            Set<Id> orderIdsToProcess = new Set<Id>();
            System.debug('oldOrderMap>>'+oldOrderMap);
            System.debug('newOrders>>'+newOrders);
            for (Order newOrder : newOrders) {
                Order oldOrder = oldOrderMap.get(newOrder.Id);
                if (newOrder.Status == 'Vehicle Delivered' && oldOrder.Status != 'Vehicle Delivered') {
                    orderIdsToProcess.add(newOrder.Id);
                    System.debug('oldOrder.Status>>'+oldOrder.Status);
                    System.debug('newOrder.Status>>'+newOrder.Status);
                }
            }
            if (orderIdsToProcess.isEmpty()) {
                return;
            }
            
            createAssetsForOrders(orderIdsToProcess);
        } catch (Exception ex) {
            System.debug('Error in handleOrderUpdate: ' + ex.getMessage());
        }
    }
    
    private static void createAssetsForOrders(Set<Id> orderIds) {
        try {
            List<OrderItem> orderItems = [
                SELECT Id, Product2Id, Product2.Name, OrderId, Order.AccountId, 
                Quantity, Total_Price__c, Order.Assigned_Vehicle__c, 
                Order.Assigned_Vehicle__r.VehicleIdentificationNumber, Order.Assigned_Vehicle__r.RR_Battery_Number__c, Order.Assigned_Vehicle__r.EngineNumber,
                Order.Assigned_Vehicle__r.Purchased_Date__c
                FROM OrderItem
                WHERE OrderId IN :orderIds
            ];
            
            
            
            List<Asset> assetsToInsert = new List<Asset>();
            for (OrderItem oI : orderItems) {
                Asset asset = new Asset();
                asset.Name = oI.Product2.Name; 
                asset.Product2Id = oI.Product2Id; 
                asset.AccountId = oI.Order.AccountId;
                asset.Vehicle__c = oI.Order.Assigned_Vehicle__c; 
                //asset.SerialNumber = oI.OrderItemNumber; 
                asset.Status = 'Purchased'; 
                asset.Price = oI.Total_Price__c; 
                asset.Quantity = oI.Quantity; 
                asset.PurchaseDate = oI.Order.Assigned_Vehicle__r.Purchased_Date__c;
                asset.InstallDate = Date.today(); // need to ask what is the value here
                asset.Battery_Number__c = oI.Order.Assigned_Vehicle__r.RR_Battery_Number__c;
                asset.Vehicle_Identification_Number__c = oI.Order.Assigned_Vehicle__r.VehicleIdentificationNumber;
                asset.Motor_Number__c = oI.Order.Assigned_Vehicle__r.EngineNumber;
                
                assetsToInsert.add(asset);
            }
            
            if (!assetsToInsert.isEmpty()) {
                try {
                    insert assetsToInsert;
                } catch (DmlException ex) {
                    System.debug('Error while inserting Assets: ' + ex.getMessage());
                }
            }
            else {
                System.debug('No Assets to insert.');
            }
        } catch (Exception ex) {
            System.debug('Error in createAssetsForOrders: ' + ex.getMessage());
        }
    }
    
   /* public static void createProductTransfer(List<Order> newOrderlist,Map<Id,Order> oldOrderMap){        
        try{
            Set<Id> orderIdsToProcess = new Set<Id>();
            Map<Id,OrderItem> productNameMap = new Map<Id,OrderItem>();
            Map<Id,Id> contactLocationMap = new Map<Id,Id>();
            List<ProductTransfer> ptToInsert = new List<ProductTransfer>();
            Set<Id> OrderIdSet = new Map<Id, Order>(newOrderlist).keySet();

            if(!newOrderlist.isEmpty()){
                for(Order o : [SELECT Id,status,Contact__c,Contact__r.Location__c From Order wHERE Id IN:OrderIdSet]){
                    if(o.status !=null && o.Status == 'Activated' && oldOrderMap.get(o.Id).Status !='Activated'){
                        orderIdsToProcess.add(o.Id);
                    } if(o.Contact__c != null && !contactLocationMap.containsKey(o.Id)){
                        contactLocationMap.put(o.Id,o.Contact__r.Location__c);
                    }
                }
            }
            System.debug('contactLocationMap # 1 === >'+contactLocationMap);
              System.debug('orderIdsToProcess # 1 === >'+orderIdsToProcess);
            List<OrderItem> orderItemList = [Select id,OrderId,Product2Id from OrderItem where OrderId IN:orderIdsToProcess];
            System.debug('orderItemList # 1 === >'+orderItemList);
            for(OrderItem oItem : orderItemList){
                if(!productNameMap.containsKey(oItem.Id)){
                    productNameMap.put(oItem.id,oItem);
                }
            }
            System.debug('productNameMap === >'+productNameMap);
            for(OrderItem oi : orderItemList){
                ProductTransfer pt = new ProductTransfer();
                pt.LR_Number__c='NA';
                pt.Order__c=oi.OrderId;
                pt.Order_Product__c=oi.Id;
                pt.Driver_Phone__c='NA';
                pt.RecordTypeId= SObjectType.ProductTransfer.getRecordTypeInfosByDeveloperName().get('Transfer').getRecordTypeId();
                pt.SourceLocationId=System.label.Default_River_Warehouse;
                pt.DestinationLocationId=contactLocationMap.get(oi.OrderId);
                pt.QuantitySent=0.0;
                pt.Product2Id=productNameMap.get(oi.Id).Product2Id;
                ptToInsert.add(pt);
            }
            if(!ptToInsert.isEmpty()){
                insert ptToInsert;
                System.debug('ptToInsert ===>'+ptToInsert);
            }
        }
        catch(Exception e){
            System.debug('Exception occured ===>'+e.getMessage());
            System.debug('Exception Occured in Line ====>'+e.getLineNumber());   
        }    
    }
*/    

        public static void createProductTransferForBackOrder(Map<Id, Order> oldOrderMap, Map<Id, Order> newOrderMap) {
            // 1. product is taggerd, qs 
            
            Id transferRecordTypeId = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Transfer').getRecordTypeId();
            List<ProductTransfer> transfersToCreate = new List<ProductTransfer>();

            Set<Id> orderIdsToProcess = new Set<Id>();
            Set<Id> purchaseOrderIds = new Set<Id>();
            Set<Id> product2Ids = new Set<Id>();
            Map<Id, Order> ordersToProcess = new Map<Id, Order>();

            // Collect necessary data
            for (Id orderId : newOrderMap.keySet()) {
                Order oldOrder = oldOrderMap.get(orderId);
                Order newOrder = newOrderMap.get(orderId);

                if (oldOrder.Status == 'Back Order' && newOrder.Status == 'Activated' && newOrder.Purchase_Order__c != null) {
                    orderIdsToProcess.add(orderId);
                    purchaseOrderIds.add(newOrder.Purchase_Order__c);
                    ordersToProcess.put(orderId, newOrder);
                }
            }

            if (orderIdsToProcess.isEmpty()) {
                return; // Nothing to process
            }

            // Query Purchase Orders and their Line Items
            Map<Id, ProductRequest> purchaseOrderMap = new Map<Id, ProductRequest>(
                [SELECT Id, DestinationLocationId,
                    (SELECT Id, QuantityRequested, Product2Id FROM ProductRequestLineItems)
                FROM ProductRequest WHERE Id IN :purchaseOrderIds]
            );

            // Query Order Items
            Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
            for (OrderItem oi : [
                SELECT Id, Product2Id, Quantity, OrderId
                FROM OrderItem
                WHERE OrderId IN :orderIdsToProcess
            ]) {
                if (!orderItemsMap.containsKey(oi.OrderId)) {
                    orderItemsMap.put(oi.OrderId, new List<OrderItem>());
                }
                orderItemsMap.get(oi.OrderId).add(oi);
                product2Ids.add(oi.Product2Id);
            }

            Set<Id> destinationLocationIds = new Set<Id>();
            for (ProductRequest pr : purchaseOrderMap.values()) {
                if (pr.DestinationLocationId != null) {
                    destinationLocationIds.add(pr.DestinationLocationId);
                }
            }

            Map<Id, ProductItem> productItemMap = new Map<Id, ProductItem>();
            for (ProductItem pi : [
                SELECT Id, Product2Id, LocationId
                FROM ProductItem
                WHERE Product2Id IN :product2Ids AND LocationId IN :destinationLocationIds
            ]) {
                productItemMap.put(pi.Product2Id, pi);
            }

            System.debug('orderItemsMap====>'+orderItemsMap);
            System.debug('purchaseOrderMap====>'+purchaseOrderMap);
            System.debug('productItemMap====>'+productItemMap);

            // Query Product Items (Product Inventory)
            //purchase ord=er is product request
            

            // Create Product Transfers
            for (Id orderId : ordersToProcess.keySet()) {
                Order newOrder = ordersToProcess.get(orderId);
                ProductRequest purchaseOrder = purchaseOrderMap.get(newOrder.Purchase_Order__c);
                List<OrderItem> orderItems = orderItemsMap.get(orderId);
                System.debug('orderItems::::'+orderItems);

                if (purchaseOrder != null && orderItems != null) {
                    for (OrderItem oi : orderItems) {
                        if (productItemMap.containsKey(oi.Product2Id)) {
                            ProductItem matchingProductItem = productItemMap.get(oi.Product2Id);
                            System.debug('matchingProductItem::::'+ matchingProductItem);

                            ProductTransfer pt = new ProductTransfer();
                            pt.Product2Id = oi.Product2Id;
                            pt.Order__c = orderId;
                            pt.RecordTypeId = transferRecordTypeId;
                            pt.Order_Product__c = oi.Id;
                            pt.QuantitySent = oi.Quantity;
                            pt.QuantityReceived = 0;
                            pt.Driver_Phone__c = '0';
                            pt.LR_Number__c = '0';
                            pt.DestinationLocationId = purchaseOrder.DestinationLocationId;
                            pt.Product_Inventory__c = matchingProductItem.Id;

                            // need to tag 2 things daily ledger and Shipment Item
                            transfersToCreate.add(pt);
                        }
                    }
                }
            }

            // Insert Product Transfers
            if (!transfersToCreate.isEmpty()) {
                try {
                    insert transfersToCreate;
                } catch (DmlException e) {
                    System.debug('Error inserting Product Transfers: ' + e.getMessage());
                }
            }
        }


}