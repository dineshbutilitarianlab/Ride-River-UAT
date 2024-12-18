trigger OrderPaymentTrigger on Order_Payment__c (before insert, before update, after update, after insert) {
     
    If(trigger.isBefore){ 
        If(trigger.isInsert){            
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, false);            
            OrderPaymentTriggerHandler.insertHandler(trigger.new);
            
        }    
        if(trigger.isUpdate){
            OrderPaymentTriggerHandler.checkDuplicateOnInsert(trigger.new, true);
        }
    }
    
    if(trigger.isAfter){
        
        If(trigger.isInsert){
            
            OrderPaymentTriggerHandler.updateOrderOnInsert(trigger.new);
            OrderStatusHandler.sendPreOrderReceipt01(trigger.new); 
        }
        
        If(trigger.isUpdate){
            OrderPaymentTriggerHandler.updateOrderOnUpdate(trigger.new, trigger.oldMap);
        }
    }

}