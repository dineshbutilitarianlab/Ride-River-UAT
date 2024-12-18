public class WarrantyPriorTriggerHandler {

    // Method to handle warranty approval
    public static void handleWarrantyApproval(List<Warranty_Prior__c> newRecords, Map<Id, Warranty_Prior__c> oldMap) {
        List<Claim> claimsToInsert = new List<Claim>();

        // Step 1: Collect all Warranty IDs
        Set<Id> warrantyIds = new Set<Id>();
        for (Warranty_Prior__c warranty : newRecords) {
            Warranty_Prior__c oldWarranty = oldMap.get(warranty.Id);
            if (warranty.Status__c == 'Approved' && oldWarranty.Status__c != 'Approved') {
                warrantyIds.add(warranty.Id);
            }
        }

        if (warrantyIds.isEmpty()) {
            return; // Exit if there are no warranties to process
        }

        // Step 2: Query related WorkOrders and their Accounts
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [SELECT Id, AccountId,Vehicle__c
             FROM WorkOrder
             WHERE Id IN (SELECT Job_Card__c FROM Warranty_Prior__c WHERE Id IN :warrantyIds)]
        );

        // Step 3: Process each Warranty and create Claims
        for (Warranty_Prior__c warranty : newRecords) {
            Warranty_Prior__c oldWarranty = oldMap.get(warranty.Id);

            if (warranty.Status__c == 'Approved' && oldWarranty.Status__c != 'Approved') {
                // Find the related WorkOrder
                WorkOrder relatedWorkOrder = workOrderMap.get(warranty.Job_Card__c);

                if (relatedWorkOrder != null && relatedWorkOrder.AccountId != null) {
                    // Create a Claim
                    Claim newClaim = new Claim(
                        Name              = 'Claim_' + warranty.Name,
                        Warranty_Prior__c = warranty.Id,
                        AccountId         = relatedWorkOrder.AccountId, // Assign the Account from the WorkOrder
                        Status            = 'Submitted', // Set an appropriate initial status
                        Vehicle__c        = relatedWorkOrder.Vehicle__c,      
                        Job_Card__c       = relatedWorkOrder.Id // Assign the WorkOrder so we can track the Claim
                    );
                    claimsToInsert.add(newClaim);
                } else {
                    System.debug('Related WorkOrder or Account not found for Warranty: ' + warranty.Id);
                }
            }
        }

        // Step 4: Insert Claims
        if (!claimsToInsert.isEmpty()) {
            insert claimsToInsert;
            System.debug('Inserted Claims: ' + claimsToInsert);
        }
    } // Ensure this method is properly closed here

    public static void enforceCommentsOnRejection(List<Warranty_Prior__c> newList, Map<Id, Warranty_Prior__c> oldWarrantyMap) {
        List<Id> warrantyIdsToCheck = new List<Id>();
        Map<Id, String> commentsMap = new Map<Id, String>();
    
        // Step 1: Collect IDs of warranties whose status changed to 'Rejected'
        for (Warranty_Prior__c war : newList) {
            if ((war.Status__c == 'Rejected'   || war.Status__c == 'Approved' ) && oldWarrantyMap.get(war.Id).Status__c != war.Status__c) {
                warrantyIdsToCheck.add(war.Id);
            }
        }
    
        if (!warrantyIdsToCheck.isEmpty()) {
            // Step 2: Query ProcessInstance and related ProcessInstanceStep records
            List<ProcessInstance> processInstances = [
                SELECT Id, TargetObjectId, 
                       (SELECT Id, StepStatus, Comments FROM Steps WHERE StepStatus IN ('Rejected', 'Approved')) 
                FROM ProcessInstance 
                WHERE TargetObjectId IN :warrantyIdsToCheck
            ];
    
            // Step 3: Extract rejection comments for each Warranty_Prior__c record
            for (ProcessInstance pi : processInstances) {
                for (ProcessInstanceStep step : pi.Steps) {
                    // Only consider steps with 'Rejected' status and valid comments
                    if (step.Comments != null && !String.isBlank(step.Comments)) {
                        commentsMap.put(pi.TargetObjectId, step.Comments);
                    }
                }
            }
    
            // Step 4: Update ASM_Feedback__c and enforce validation
            for (Warranty_Prior__c war : newList) {
                if (warrantyIdsToCheck.contains(war.Id)) {
                    if (commentsMap.containsKey(war.Id)) {
                        war.ASM_Feedback__c = commentsMap.get(war.Id); // Assign rejection comments to ASM_Feedback__c
                    }  else if (war.Status__c == 'Rejected') {
                        war.addError('Feedback are required when rejecting a Warranty.');
                    }
                }
            }
        }
    }
    

    
}