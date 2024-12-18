public with sharing class WorkPlanController {
    @AuraEnabled(cacheable=true)
    public static List<WorkPlan> getRelatedWorkPlans(Id workOrderId) {
         System.debug('Fetching related Work Plans for Work Order Id: ' + workOrderId);
        List<WorkPlan> workplans = [SELECT Id, Name, RR_Labour_Code__r.Code, Status__c, Duration_Hour__c, Labour_Charge__c,CreatedDate, RR_Labour_Code__c
                                    FROM WorkPlan 
                                    WHERE WorkOrderId =:workOrderId
                                    ORDER BY CreatedDate ASC];
        System.debug('Retrieved related Work Plans: ' + workplans);
        return workplans;
    }
}