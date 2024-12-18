/******************************************************************************
* Class Name: OrderPaymentTriggerHandler
* Created by : Sudarshan N B - 1/10/23
* Last Modified By : Sudarshan N B - 10/07/2024
* Description : Handler for order payment trigger
*****************************************************************************/
public class OrderPaymentTriggerHandler {
    
    public static void insertHandler(List<Order_Payment__c> newRecords){
        
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Set<Id> OrderPaymentIds = new set<Id>();
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            if (op.Order__c != null) {
                orderIdsToUpdate.add(op.Payments__c);
                
            }
        } 
        
        If(orderIdsToUpdate != null)
            For(Payment__c p : [SELECT Id,Amount__c, Payment_status__c FROM Payment__c WHERE Id IN : orderIdsToUpdate]){
                If(p.Payment_status__c == 'Success'){
                    mapPaymentIdtoPayment.put(p.Id,p);
                }
            }
        
        For(Order_Payment__c op : newRecords){
            If(mapPaymentIdtoPayment.keyset().contains(op.Payments__c) && op.Type__c != 'Refund'){
                op.Amount1__c = mapPaymentIdtoPayment.get(op.Payments__c).Amount__c;
            }
        }		
        
    }
    
    
    Public static void updateOrderOnInsert(List<Order_Payment__c> newRecords){
        
        system.debug('The update Order is running');  
        
        Set<Id> orderIdsToUpdate = new Set<Id>();
        
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            System.debug('The updating orders in progress');
            if (op.Order__c != null && op.Amount1__c != null) {
               
                System.debug('The updating orders in progress and order present');
                orderIdsToUpdate.add(op.Order__c);
                
                //Create a map of Order Id to Order Payments
                If(mapOrderIdtoOrderPayment.ContainsKey(op.Order__c)){
                    mapOrderIdtoOrderPayment.get(op.Order__c).add(op);
                }else{
                    mapOrderIdtoOrderPayment.put(op.Order__c, new List<Order_Payment__c>{op});
                } 
                
                system.debug('The map is>>'+mapOrderIdtoOrderPayment);
                system.debug('The orderIdsToUpdate is>>'+orderIdsToUpdate);
            }
        }
        
        List<Order> orderToUpate = new List<Order>();
        // Order payment status update      
        For(Order order :[SELECT Id, Total_Amount_paid__c, Grand_Total__c, Payment_Status__c,Assigned_Vehicle__c, (Select Id From Order_Payments__r WHERE Type__c = 'Down Payment' AND Amount1__c <= 0), (SELECT Id, Product2Id, Type__c FROM OrderItems) FROM Order WHERE Id IN :orderIdsToUpdate] ){
            
            system.debug('inside the order loop');
            Set<string> itemTypes = new Set<string>();
            
            For(OrderItem item : order.OrderItems){
                itemTypes.add(item.Type__c);
            }
            
            double totalPaidAmount = 0;
            Order orderObj = new Order();
            If(mapOrderIdtoOrderPayment.containsKey(order.Id)){
                For(Order_Payment__c op: mapOrderIdtoOrderPayment.get(order.Id)){
                    system.debug('The amount is>>'+op.Amount1__c);
                    system.debug('The order.Total_Amount_paid__c is>>'+order.Total_Amount_paid__c);
                    system.debug('The order.Grand_Total__c is>>'+order.Grand_Total__c);
                                        
                    If(order.Grand_Total__c - order.Total_Amount_paid__c - totalPaidAmount <= op.Amount1__c){
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'Completed';
                        If(order.Assigned_Vehicle__c != null || (!itemTypes.contains('Vehicle'))){
                            
                            OrderObj.Status = 'Pre Invoice';
                        	
                        }else{
                            
                            OrderObj.Status = 'Allotment in Process';
                        }
                        
                        
                        orderToUpate.add(orderObj);
                    }else{
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'In Progress';
                        
                        system.debug('order payments are>>'+order.Order_Payments__r);
                        If(op.Type__c == 'Down Payment' && order.Order_Payments__r.isempty() ){
                            system.debug('order confirmed');
                            orderObj.Status = 'Processing';
                        }
                        orderToUpate.add(orderObj);
                    }
                    
                    totalPaidAmount += op.Amount1__c;
                }
            }
        }
        system.debug('updated Orders are>>'+orderToUpate);
               
        Database.update(orderToUpate,false);
        
    }
    
    Public static void updateOrderOnUpdate(List<Order_Payment__c> newRecords, Map<Id, Order_Payment__c> oldMap){
        
        system.debug('The update Order is running');  
        system.debug('newRecords================='+newRecords);
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Set<Id> orderPIdsToUpdate = new Set<Id>();
        
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();
        Map<Id,List<Order_Payment__c>> mapOrderIdtoOrderPayment = new  Map<Id,List<Order_Payment__c>>();
        
        For(Order_Payment__c op : newRecords){
            System.debug('The updating orders in progress');
            if (op.Order__c != null && op.Amount1__c != null && oldMap.get(op.Id).Amount1__c != op.Amount1__c) {
                orderPIdsToUpdate.add(op.Id);
                System.debug('The updating orders in progress and ordewr present');
                orderIdsToUpdate.add(op.Order__c);
                
                //Create a map of Order Id to Order Payments
                If(mapOrderIdtoOrderPayment.ContainsKey(op.Order__c)){
                    mapOrderIdtoOrderPayment.get(op.Order__c).add(op);
                }else{
                    mapOrderIdtoOrderPayment.put(op.Order__c, new List<Order_Payment__c>{op});
                } 
                
                system.debug('The map is>>'+mapOrderIdtoOrderPayment);
                system.debug('The orderIdsToUpdate is>>'+orderIdsToUpdate);
            }
        }
        
        List<Order> orderToUpate = new List<Order>();
        // Order payment status update      
        For(Order order :[SELECT Id, Total_Amount_paid__c, Grand_Total__c, Payment_Status__c,Assigned_Vehicle__c, (Select Id From Order_Payments__r WHERE Type__c = 'Down Payment' AND Amount1__c <= 0 AND Id NOT IN :orderPIdsToUpdate), (SELECT Id, Product2Id, Type__c FROM OrderItems) FROM Order WHERE Id IN :orderIdsToUpdate] ){
            
            system.debug('inside the order loop');
            Set<string> itemTypes = new Set<string>();
            
            For(OrderItem item : order.OrderItems){
                itemTypes.add(item.Type__c);
            }
            
            double totalPaidAmount = 0;
            Order orderObj = new Order();
            If(mapOrderIdtoOrderPayment.containsKey(order.Id)){
                For(Order_Payment__c op: mapOrderIdtoOrderPayment.get(order.Id)){
                    
                    system.debug('The amount is>>'+op.Amount1__c);
                    system.debug('The order.Total_Amount_paid__c is>>'+order.Total_Amount_paid__c);
                    system.debug('The order.Grand_Total__c is>>'+order.Grand_Total__c);
                                        
                    If(order.Grand_Total__c - order.Total_Amount_paid__c - totalPaidAmount <= op.Amount1__c){
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'Completed';
                        If(order.Assigned_Vehicle__c != null || (!itemTypes.contains('Vehicle'))){
                            OrderObj.Status = 'Pre Invoice';
                        }else{
                            OrderObj.Status = 'Allotment in Process';
                        }
                        
                        orderToUpate.add(orderObj);
                    }else{
                        orderObj.Id = order.Id;
                        orderObj.Payment_Status__c = 'In Progress';
                        
                        system.debug('order payments are>>'+order.Order_Payments__r);
                        If((op.Type__c == 'Down Payment' || op.Type__c == 'Full Payment' || op.Type__c == 'Others') && order.Order_Payments__r.isempty() ){
                            system.debug('order confirmed');
                            orderObj.Status = 'Processing';
                        }
                        orderToUpate.add(orderObj);
                    }
                    
                    totalPaidAmount += op.Amount1__c;
                }
            }
        }
        system.debug('updated Orders are>>'+orderToUpate);
                
        Database.update(orderToUpate,false);
        
    }
    
    
    Public static void checkDuplicateOnInsert(List<Order_Payment__c> newRecords, Boolean isUpdate){
        Set<Id> orderIdsToUpdate = new Set<Id>();
        Map<Id,Payment__c> mapPaymentIdtoPayment = new  Map<Id,Payment__c>();        
        Map<Id,Order_Payment__c> mapIdtoOrderPayment = new  Map<Id,Order_Payment__c>();
        
        For(Order_Payment__c op : newRecords){
            if (op.Order__c != null) {
                orderIdsToUpdate.add(op.Payments__c);
                
                mapIdtoOrderPayment.put(op.Id, op);
            }
        }
        
        
        List<Order_Payment__c> dupOpList = [SELECT Id,Payments__c FROM  Order_Payment__c WHERE Payments__c IN :orderIdsToUpdate];
        Map<id, Set<Id>> mapPaymentIdToOPIds = new Map<id, Set<Id>>();
        For(Order_Payment__c op: dupOpList){
            If(op.Payments__c != null){
                If(mapPaymentIdToOPIds.containsKey(op.Payments__c)){
                    mapPaymentIdToOPIds.get(op.Payments__c).add(op.Id);
                }Else{
                    mapPaymentIdToOPIds.put(op.Payments__c, new set<Id>{op.Id});
                }
            }
            
        }
        
        For(Order_Payment__c op : newRecords){
            If(mapPaymentIdToOPIds.containsKey(op.Payments__c)){
                If((!isUpdate && mapPaymentIdToOPIds.get(op.Payments__c).size() != 0) || (isUpdate && mapPaymentIdToOPIds.get(op.Payments__c).size() > 1)){
                    op.Payments__c.addError('Duplicate Order Payment found with the same Payment!');
                }
                
            }
        }
        
    }
    
}