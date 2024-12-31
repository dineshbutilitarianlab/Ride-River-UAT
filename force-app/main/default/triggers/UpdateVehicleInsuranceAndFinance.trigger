trigger UpdateVehicleInsuranceAndFinance on Order (before insert, before update, after update,After Insert) {
    
    if(trigger.isBefore && trigger.isInsert){
        /*Assigning Vechicle recordType
for(Order ord:trigger.new){
ord.recordTypeid = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
}*/
        
        
        // Jitendra added for Order validaiton
        OrderStatusHandler.checkUniqueDealerVIN(trigger.new);
    }   
    
    if(trigger.isBefore && trigger.isUpdate){
        // Jitendra added for Order validaiton
        OrderStatusHandler.checkValidaionStatus(trigger.newMap, trigger.oldMap);
        // OrderStatusHandler.updatehandler(trigger.new, trigger.oldMap);
        // Added By Uma Mahesh
    }
    
    //Edited By Sudarshan
    if(trigger.isAfter && trigger.isupdate){
        
        OrderStatusHandler.updateVehicle(trigger.new, trigger.oldMap);
        OrderStatusHandler.updateVehicle01(trigger.new, trigger.oldMap);
        OrderStatusHandler.emailHandllerMethod(trigger.new, trigger.oldMap);
        OrderStatusHandler.generateIvoicesAndReceipts(trigger.new, trigger.oldMap);
        OrderStatusHandler.sendPreOrderReceipt(trigger.new, trigger.oldMap);
        
        Map<Id, Order> oldMap = Trigger.oldMap;
        //Commented RSA Class according to Pratap input
        //RSACalloutHandler.getchasisnumber(trigger.new,oldMap);
        // Added By Uma Mahesh
        
        // method to create the invoice records
        OrderStatusHandler.ceateInvoiceRecords(trigger.new, trigger.oldMap);
    } 
    
}