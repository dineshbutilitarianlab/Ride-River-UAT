public class WorkPlanTriggerHandler {
    public static void handleInsert(List<WorkPlan> workPlans) {
        // Step 1: Collect WorkOrder IDs from the inserted WorkPlans
        Set<Id> workOrderIds = new Set<Id>();
        for (WorkPlan workPlan : workPlans) {
            if (workPlan.WorkOrderId != null && workPlan.RR_Labour_Category__c != 'Paid') {
                workOrderIds.add(workPlan.WorkOrderId);
            }
        }
        System.debug('WorkOrder IDs: ' + workOrderIds);

        // Step 2: Query existing Warranty Priors linked to the WorkOrders
        Map<Id, Warranty_Prior__c> warrantyMap = new Map<Id, Warranty_Prior__c>(
            [SELECT Id, Job_Card__c FROM Warranty_Prior__c WHERE Job_Card__c IN :workOrderIds]
        );
        System.debug('Existing Warranty Priors: ' + warrantyMap);

        // Step 3: Prepare WorkPlans for update
        List<WorkPlan> workPlansToUpdate = new List<WorkPlan>();
        for (WorkPlan workPlan : workPlans) {
            if (workPlan.WorkOrderId != null && warrantyMap.containsKey(workPlan.WorkOrderId)) {
                // Update the Warranty Prior lookup field on the WorkPlan
                WorkPlan updatedWorkPlan = new WorkPlan(
                    Id = workPlan.Id,
                    Warranty_Prior__c = warrantyMap.get(workPlan.WorkOrderId).Id
                );
                workPlansToUpdate.add(updatedWorkPlan);
            }
        }
        System.debug('WorkPlans to Update: ' + workPlansToUpdate);

        // Step 4: Perform update if necessary
        if (!workPlansToUpdate.isEmpty()) {
            update workPlansToUpdate;
        }
    }
}