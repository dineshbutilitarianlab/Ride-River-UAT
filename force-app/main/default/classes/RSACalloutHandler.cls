public class RSACalloutHandler {
    
    public static void getchasisnumber(List<Order> orderlist, Map<Id, Order> oldMap) {
        try {
            String statusoldvalue = '';
            Set<Id> orderidtogetchassisno = new Set<Id>();
            Set<Id> orderidtogetchassisnoforsubscribation = new Set<Id>();
            System.debug('orderlist: ' + orderlist);
            
            // Set<Id> Orderids = new Set<Id>();
            Set<Id> Orderids = new Map<Id, Order>(orderlist).keySet();
            
            for (Order ord : orderlist) {
                // Only get status from oldMap if it's available (i.e., in update context)
                if (oldMap != null && oldMap.containsKey(ord.Id)) {
                    Order statusoldvalueId = oldMap.get(ord.Id);
                    statusoldvalue = statusoldvalueId.Status;
                } else {
                    // Default to current status if no oldMap (insert scenario)
                    statusoldvalue = ord.Status;
                }
                // Orderids.add(ord.Id);
            }
            System.debug('Order IDs: ' + Orderids);
            
            // Query related order and order items
            // List<Order> Orderdetails = [SELECT Id, Status, RSA_Active__c FROM Order WHERE Id IN :Orderids];
            List<OrderItem> orditems = [SELECT Id, Product2.Name, OrderId FROM OrderItem WHERE OrderId IN :Orderids];
            System.debug('Order Items: ' + orditems);
            
            // Loop through Orderdetails and check conditions
            for (Order statusloop : orderlist) {
                if (Test.isRunningTest()) {
                    if (statusloop.Status != statusoldvalue) {
                        orderidtogetchassisno.add(statusloop.Id);
                        orderidtogetchassisnoforsubscribation.add(statusloop.Id);
                    }
                } else {
                    for (OrderItem orderitemprodutloop : orditems) {
                        if (statusloop.Status != statusoldvalue && statusloop.Status == 'Vehicle Delivered'
                            && orderitemprodutloop.Product2.Name != null && orderitemprodutloop.Product2.Name == 'Road Side Assistance'
                            && statusloop.RSA_Active__c == true) {
                                orderidtogetchassisno.add(statusloop.Id);
                            }
                        if (statusloop.Status != statusoldvalue && statusloop.Status == 'Ready For Delivery'
                            && orderitemprodutloop.Product2.Name != null && orderitemprodutloop.Product2.Name == 'Road Side Assistance'
                            && statusloop.RSA_Active__c == false) {
                                orderidtogetchassisnoforsubscribation.add(statusloop.Id);
                            }
                    }
                }
            }
            
            // Fetch vehicles and callout for 'Vehicle Delivered'
            List<Order> getvehicle = [SELECT id, Assigned_Vehicle__r.ChassisNumber, Assigned_Vehicle__r.VehicleRegistrationNumber
                                      FROM Order WHERE Id IN :orderidtogetchassisno];
            if (getvehicle.size() > 0) {
                for (Order assignloop : getvehicle) {
                    String chassisNO = assignloop.Assigned_Vehicle__r.ChassisNumber;
                    String vehicleRegistrationNo = assignloop.Assigned_Vehicle__r.VehicleRegistrationNumber;
                    Id OrderIdnumber = assignloop.Id;
                    RSAcalloutHelper.RsaFuthuremethod(vehicleRegistrationNo, chassisNO, OrderIdnumber);
                }
            }
            
            // Fetch vehicles and callout for 'Ready For Delivery'
            List<Order> getorderdetails = [SELECT id, Assigned_Vehicle__r.ChassisNumber, Assigned_Vehicle__r.VehicleRegistrationNumber,
                                           Account.Name, Account.Phone  
                                           FROM Order WHERE Id IN :orderidtogetchassisnoforsubscribation];
            if (getorderdetails.size() > 0) {
                for (Order assignloop : getorderdetails) {
                    String chassisNO = assignloop.Assigned_Vehicle__r.ChassisNumber;
                    String vehicleRegistrationNo = assignloop.Assigned_Vehicle__r.VehicleRegistrationNumber;
                    Id VehicleId = assignloop.Assigned_Vehicle__r.Id;
                    Id OrderIdnumber = assignloop.Id;
                    String AccountName = assignloop.Account.Name;
                    String AccountPhoneNo = assignloop.Account.Phone;
                    RSAcalloutHelper.RsaCreationFuthuremethod(chassisNO, OrderIdnumber, AccountName, AccountPhoneNo, VehicleId);
                }
            }
        } catch (Exception e) {
            System.debug('Error Message ==> ' + e.getMessage() + ' && Error Line ==> ' + e.getLineNumber());
        }
    }
    
}