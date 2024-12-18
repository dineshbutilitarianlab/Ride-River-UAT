trigger WarrantyPriorTrigger on Warranty_Prior__c (before update,after update) {
    if (Trigger.isAfter) {
       WarrantyPriorTriggerHandler.handleWarrantyApproval(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        WarrantyPriorTriggerHandler.enforceCommentsOnRejection(Trigger.new,Trigger.oldMap);
    }
    
}