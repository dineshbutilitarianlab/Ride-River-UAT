trigger TriggerWorkPlan on WorkPlan (After insert, after Update,after delete,After Undelete) {

        // Handle after insert separately to ensure proper handling of WorkPlan insert logic
        if (trigger.isAfter && trigger.isInsert) {
            WorkOrderTriggerHandler.handleWorkPlanInsert(trigger.new);
        }
        
    if(trigger.isAfter && (trigger.Isinsert || trigger.isUndelete || trigger.isUpdate)){
        WorkOrderTriggerHandler.handleTrigger(trigger.new);
    }
    
    if(trigger.isAfter && (trigger.Isdelete)){
        WorkOrderTriggerHandler.handleTrigger(trigger.old);
    }
}