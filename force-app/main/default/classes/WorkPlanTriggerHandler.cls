public class WorkPlanTriggerHandler {
    /*
    public static void handleInsert(List<WorkPlan> workPlans) {    
        Set<Id> workOrderIds = new Set<Id>(); 
        for (WorkPlan workPlan : workPlans) {
            if (workPlan.WorkOrderId != null && workPlan.RR_Labour_Category__c != 'Paid') {
                workOrderIds.add(workPlan.WorkOrderId);
            }
        }
        System.debug('WorkOrder IDs: ' + workOrderIds); 
        Map<Id, Warranty_Prior__c> warrantyMap = new Map<Id, Warranty_Prior__c>([SELECT Id, Job_Card__c FROM Warranty_Prior__c WHERE Job_Card__c IN :workOrderIds]);
        System.debug('Existing Warranty Priors == > ' + warrantyMap);
        
        List<WorkPlan> workPlansToUpdate = new List<WorkPlan>();
        
        for (WorkPlan workPlan : [SELECT Id,WorkOrderId FROM WorkPlan WHERE Id IN:workOrderIds]) {
            System.debug('workPlan === > ' + workPlan);
            if (workPlan.WorkOrderId != null && warrantyMap.containsKey(workPlan.WorkOrderId)) { 
                WorkPlan updatedWorkPlan = new WorkPlan(
                    Id = workPlan.Id,
                    Warranty_Prior__c = warrantyMap.get(workPlan.WorkOrderId).Id
                );
                workPlansToUpdate.add(updatedWorkPlan);
            }else{
                System.debug('Conditon False');       
            }
        }
        
        if (!workPlansToUpdate.isEmpty()) {
            update workPlansToUpdate;
        }
    }
*/
}