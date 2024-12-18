public with sharing class WorkOrderLineItemController {
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItem> getRelatedWorkOrderLineItems(Id workOrderId){
        try{
            System.debug('Fetching related Products for Work Order Id: ' + workOrderId);
            List<WorkOrderLineItem> WorkOrderLineItems = [SELECT WorkOrderId, Id, LineItemNumber, PricebookEntryId, PricebookEntry.Product2.Name, Quantity, RR_Parts_Category__c, Status,
                                                          PricebookEntry.Product2.ProductCode,CreatedDate,WorkOrder.WorkOrderNumber, PricebookEntry.Product2Id,Labour_Code__c,Labour_Code__r.Name
                                                          FROM WorkOrderLineItem
                                                          WHERE WorkOrderId=: workOrderId
                                                          ORDER BY CreatedDate ASC];
            System.debug('Retrieved related WorkOrderLineItems: ' + WorkOrderLineItems);
            
            RETURN WorkOrderLineItems;
        }catch(exception e){
            system.debug('Error Message'+e.getMessage()+ ' at Line Number'+ e.getLineNumber());
            return null;
        }
        
        
    }
    @AuraEnabled
    public static Id getWarrantyForJobCard(Id workOrderId) {
        try{
            Warranty_Prior__c warranty = [
                SELECT Id
                FROM Warranty_Prior__c
                WHERE Job_Card__c = :workOrderId
                LIMIT 1
            ];
            return warranty != null ? warranty.Id : null;
        }catch(exception e){
            system.debug('Error Message'+e.getMessage()+ ' at Line Number'+ e.getLineNumber());
            return null;
        }
    }
    
}