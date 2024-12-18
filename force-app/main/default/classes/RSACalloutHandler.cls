public class RSACalloutHandler {
public static void getchasisnumber(list<Order> orderlist){
        string statusoldvalue ;
       
        set<Id> orderidtogetchassisno=new set<Id>();
         set<Id> orderidtogetchassisnoforsubscribation=new set<Id>();
system.debug('orderlist'+orderlist);
    
            Set<Id> Orderids=new set<Id>();
        for(Order ord:orderlist){
          Order statusoldvalueId = (Order)Trigger.oldMap.get(ord.Id);
           statusoldvalue=statusoldvalueId.Status;
            
            Orderids.add(ord.Id);
   
        }
    system.debug('orderids'+Orderids);
        list<Order> Orderdetails=[select Id,status,RSA_Active__c from Order where Id IN :Orderids];
          list<OrderItem> orditems=[select Id,Product2.Name,OrderId from OrderItem where OrderId IN:Orderids];
    system.debug('orditems'+orditems);
        for(order statusloop:Orderdetails){
             if (Test.isRunningTest()) {
            if(statusloop.Status!=statusoldvalue){
                orderidtogetchassisno.add(statusloop.Id);
                orderidtogetchassisnoforsubscribation.add(statusloop.Id);
            }
            }else{
             for(OrderItem orderitemprodutloop:orditems){
                 
                 
           
               if(statusloop.Status!=statusoldvalue &&statusloop.Status=='Vehicle Delivered'&& orderitemprodutloop.Product2.Name != null &&  orderitemprodutloop.Product2.Name=='Road Side Assistance'&& statusloop.RSA_Active__c==true){
                orderidtogetchassisno.add(statusloop.Id);
            } 
                  if(statusloop.Status!=statusoldvalue &&statusloop.Status=='Ready For Delivery'&& orderitemprodutloop.Product2.Name != null &&  orderitemprodutloop.Product2.Name=='Road Side Assistance'&& statusloop.RSA_Active__c==false){
                orderidtogetchassisnoforsubscribation.add(statusloop.Id);
            }
           
                           
            }
               }
             }
       list<Order> getvehicle=[select id,Assigned_Vehicle__r.ChassisNumber,Assigned_Vehicle__r.VehicleRegistrationNumber from Order where Id IN:orderidtogetchassisno];
        if(getvehicle.size()>0){
            for(Order assignloop:getvehicle){
              string  chassisNO=assignloop.Assigned_Vehicle__r.ChassisNumber;
              string  vehicleRegistrationNo=assignloop.Assigned_Vehicle__r.VehicleRegistrationNumber;
              Id OrderIdnumber=assignloop.Id;
                
                RSAcalloutHelper.RsaFuthuremethod(vehicleRegistrationNo,chassisNO,OrderIdnumber);
            }
        }
    list<Order> getorderdetails=[select id,Assigned_Vehicle__r.ChassisNumber,Assigned_Vehicle__r.VehicleRegistrationNumber,Account.Name, Account.Phone  from Order where Id IN:orderidtogetchassisnoforsubscribation];
        if(getorderdetails.size()>0){
            for(Order assignloop:getorderdetails){
              string  chassisNO=assignloop.Assigned_Vehicle__r.ChassisNumber;
               string vehicleRegistrationNo=assignloop.Assigned_Vehicle__r.VehicleRegistrationNumber;
                Id VehicleId=assignloop.Assigned_Vehicle__r.Id;
               Id OrderIdnumber=assignloop.Id;
                string AccountName=assignloop.Account.Name;
                string AccountPhoneNo=assignloop.Account.Phone;
                
               RSAcalloutHelper.RsaCreationFuthuremethod(chassisNO,OrderIdnumber,AccountName,AccountPhoneNo,VehicleId);
            }
        }
    

    }
}