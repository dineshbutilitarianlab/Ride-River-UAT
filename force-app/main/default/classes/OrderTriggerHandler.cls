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

    public static void createProductTransfer(List<Order> newOrder,Map<Id,Order> oldMapOrder){
        system.debug('code in');
        try{
            Set<Id> OrderIdSet = new Map<Id, Order>(newOrder).keySet();
            
            Map<Id,Shipment> shipmentMap = new Map<Id,Shipment>();//new code today
            
            Map<String,String> mapOrderIdPOId  = new Map<String,String>();
            List<ProductTransfer> productTransfersToInsert = new List<ProductTransfer>();
            List<Order> newOrderQueryList = [SELECT Id,Purchase_Order__c,Purchase_Order__r.Destination_Location__c,Status FROM Order WHERE Id IN:OrderIdSet];
            if(newOrderQueryList.size()>0){
                for(Order ord : newOrderQueryList){
                    if(ord.status !=null && ord.Status == 'Activated' && oldMapOrder.get(ord.Id).Status !='Activated'){
                    if(ord.Purchase_Order__r.Destination_Location__c != null){
                        mapOrderIdPOId.put(ord.id,ord.Purchase_Order__r.Destination_Location__c);
                        
                    }else{
                        System.debug('Location Not Found & Order == >'+ord);
                    }
                }
                }
            }
            system.debug('mapOrderIdPOId == >'+mapOrderIdPOId);
            List<OrderItem> listOfOrderProducts = [Select id,OrderId from OrderItem where OrderId IN:OrderIdSet];
            List<Shipment> shipmentList = [Select id,LR_Number__c,Driver_Phone__c,TotalItemsQuantity,Order__c from Shipment where Order__c IN:OrderIdSet];//today
            for(Shipment s : shipmentList){
                shipmentMap.put(s.Order__c,s);
            }
             system.debug('listOfOrderProducts == >'+listOfOrderProducts);
            for(OrderItem oi : listOfOrderProducts){
                ProductTransfer pt = new ProductTransfer();
                pt.Order_Product__c = oi.Id;
                pt.SourceLocationId=System.Label.Default_River_Warehouse;
                pt.DestinationLocationId=mapOrderIdPOId.get(oi.OrderId);
                pt.RecordTypeId= SObjectType.ProductTransfer.getRecordTypeInfosByDeveloperName().get('Transfer').getRecordTypeId();
                pt.QuantitySent=90;//Harcoded for now
                pt.Driver_Phone__c= shipmentMap.get(oi.OrderId).Driver_Phone__c != null ? shipmentMap.get(oi.OrderId).Driver_Phone__c : '';
                pt.LR_Number__c= shipmentMap.get(oi.OrderId).LR_Number__c != null ? shipmentMap.get(oi.OrderId).LR_Number__c : 'NA';
                pt.Order__c=shipmentMap.get(oi.OrderId).Order__c;
                productTransfersToInsert.add(pt);
            }
            if(!productTransfersToInsert.isEmpty()){
                insert productTransfersToInsert;
                system.debug('productTransfersToInsert == >'+productTransfersToInsert);
            }
        }
        catch(Exception e){
            System.debug('error occured ====>'+e.getMessage()+'Error occured in Line Numbers ====>'+e.getLineNumber());
        }
    }
}