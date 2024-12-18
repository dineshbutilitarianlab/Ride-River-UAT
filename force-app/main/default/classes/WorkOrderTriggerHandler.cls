public class WorkOrderTriggerHandler {
    
    public static void handleTrigger(List<WorkPlan> newobjWorkPlan) {

        Set<Id> setobjWorkPlan = new Set<Id>();

        for (WorkPlan objWorkPlan : newobjWorkPlan) {
            if (objWorkPlan.Labour_Charge__c != null && objWorkPlan.WorkOrderId != null && objWorkPlan.Amount__c != null) {
                System.debug('objWorkPlan.WorkOrderId==?' + objWorkPlan.WorkOrderId);
                setobjWorkPlan.add(objWorkPlan.WorkOrderId);
            }
        }

        updateWorkPlan(setobjWorkPlan);
    }

    @future
    public static void updateWorkPlan(Set<Id> setobjWorkPlan) {

        System.debug('setobjWorkPlan==>' + setobjWorkPlan);
        List<WorkOrder> lstWorkorders = new List<WorkOrder>();

        List<WorkOrder> lstWorkorder = [SELECT Id, Total_Duration_Min__c, Total_Duration_Hour__c, Labour_Charge__c, SGST_on_Labour_Charges__c, IGST_on_Labour_Charges__c, CGST_on_Labour_Charges__c,
            (SELECT Id, Duration_Min__c, Duration_Hour__c, Labour_Charge__c, CGST_Amount__c, SGST_Amount__c, IGST_Amount__c, Discount__c  FROM WorkPlans)
            FROM WorkOrder WHERE Id IN :setobjWorkPlan];

        System.debug('lstWorkorder==>' + lstWorkorder);

        for (WorkOrder objWorkOrder : lstWorkorder) {
            Decimal totalMinutes = 0;
            Decimal totalHours = 0;
            Decimal totalCharge = 0;
            Decimal totalCGST = 0;
            Decimal totalSGST = 0;
            Decimal totalIGST = 0;
            Decimal totalDiscount = 0;

            for (WorkPlan objobjWorkPlan : objWorkOrder.WorkPlans) {
                if (objobjWorkPlan != null) {
                    if (objobjWorkPlan.Duration_Min__c != null) {
                        totalMinutes += objobjWorkPlan.Duration_Min__c;
                    }
                    if (objobjWorkPlan.Duration_Hour__c != null) {
                        totalHours += objobjWorkPlan.Duration_Hour__c;
                    }
                    if (objobjWorkPlan.Labour_Charge__c != null) {
                        totalCharge += objobjWorkPlan.Labour_Charge__c;
                        System.debug('totalCharge==>' + totalCharge);
                    }
                    if (objobjWorkPlan.SGST_Amount__c != null) {
                        totalSGST += objobjWorkPlan.SGST_Amount__c;
                    }
                    if (objobjWorkPlan.CGST_Amount__c != null) {
                        totalCGST += objobjWorkPlan.CGST_Amount__c;
                    }
                    if (objobjWorkPlan.IGST_Amount__c != null) {
                        totalIGST += objobjWorkPlan.IGST_Amount__c;
                    }
                    if (objobjWorkPlan.Discount__c != null && objobjWorkPlan.Labour_Charge__c != null) {
                        totalDiscount += (objobjWorkPlan.Discount__c * objobjWorkPlan.Labour_Charge__c)/100;
                    }
                }
            }
            
           // Convert excess minutes to hours
            if (totalMinutes >= 60) {
                Decimal hoursToAdd = Math.floor(totalMinutes / 60);
                totalHours += hoursToAdd;
                totalMinutes -= hoursToAdd * 60;
            }
            
            system.debug('total kabour charge is>>'+totalCharge);
            system.debug('totalDiscount charge is>>'+totalDiscount);
            system.debug('total charge is>>'+(totalDiscount/totalCharge)*100);
            
            objWorkOrder.Total_Duration_Min__c = totalMinutes;
            objWorkOrder.Total_Duration_Hour__c = totalHours;
            objWorkOrder.Labour_Charge__c = totalCharge;
            objWorkOrder.SGST_on_Labour_Charges__c = totalSGST;
            objWorkOrder.IGST_on_Labour_Charges__c = totalIGST;
            objWorkOrder.CGST_on_Labour_Charges__c = totalCGST;
            objWorkOrder.Discount_on_Labour_Codes__c = (totalDiscount/totalCharge)*100;
            
            lstWorkorders.add(objWorkOrder);
        }

        update lstWorkorders;
    }

    public static void handleWorkPlanInsert(List<WorkPlan> newWorkPlans) {
        // Step 1: Collect WorkOrder IDs (Job_Card__c) from WorkPlans
        Set<Id> workOrderIds = new Set<Id>();
        for (WorkPlan workPlan : newWorkPlans) {
            if (workPlan.WorkOrderId != null) {
                workOrderIds.add(workPlan.WorkOrderId);
            }
        }
    
        // Step 2: Query existing Warranties related to Job_Card__c (WorkOrder IDs)
        Map<Id, Warranty_Prior__c> existingWarrantyMap = new Map<Id, Warranty_Prior__c>(
            [SELECT Id, Job_Card__c
             FROM Warranty_Prior__c
             WHERE Job_Card__c IN :workOrderIds]
        );
    
        // Step 3: Map existing warranties by Job_Card__c
        Map<Id, Id> workOrderToWarrantyMap = new Map<Id, Id>();
        for (Warranty_Prior__c warranty : existingWarrantyMap.values()) {
            workOrderToWarrantyMap.put(warranty.Job_Card__c, warranty.Id); // Map Job_Card__c to Warranty ID
        }
    
        // Step 4: Query WorkOrder details for creating new Warranties
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [SELECT Id,
                    Vehicle__c,
                    Odometer_Reading__c,
                    Vehicle_Registration_Number__c,
                    Vehicle__r.EngineNumber,
                    Vehicle__r.VehicleIdentificationNumber
             FROM WorkOrder
             WHERE Id IN :workOrderIds]
        );
    
        // Step 5: Create new Warranties for WorkOrders without an existing Warranty
        List<Warranty_Prior__c> newWarranties = new List<Warranty_Prior__c>();
    
        for (WorkPlan workPlan : newWorkPlans) {
            if (workPlan.WorkOrderId != null && !workOrderToWarrantyMap.containsKey(workPlan.WorkOrderId)) {
                WorkOrder relatedWorkOrder = workOrderMap.get(workPlan.WorkOrderId);
                if (relatedWorkOrder != null) {
                    // Create a new Warranty Prior record and populate the additional details
                    Warranty_Prior__c newWarranty = new Warranty_Prior__c(
                        Job_Card__c = workPlan.WorkOrderId,
                        Motor_Number__c = relatedWorkOrder.Vehicle__r.EngineNumber,
                        Odometer_Reading__c = relatedWorkOrder.Odometer_Reading__c,
                        Registration_Number__c = relatedWorkOrder.Vehicle_Registration_Number__c,
                        VIN__c = relatedWorkOrder.Vehicle__r.VehicleIdentificationNumber,
                        Warranty_Prior_Date__c = Date.today(),
                        Status__c = 'Pending'
                    );
                    newWarranties.add(newWarranty);
                }
            }
        }
    
        if (!newWarranties.isEmpty()) {
            insert newWarranties;
    
            // Map newly created Warranties
            for (Warranty_Prior__c warranty : newWarranties) {
                workOrderToWarrantyMap.put(warranty.Job_Card__c, warranty.Id);
            }
        }
    
        // Step 6: Update WorkPlans with related Warranty Prior
        List<WorkPlan> workPlansToUpdate = new List<WorkPlan>();
        for (WorkPlan workPlan : newWorkPlans) {
            if (workPlan.WorkOrderId != null && workOrderToWarrantyMap.containsKey(workPlan.WorkOrderId)) {
                // Update the WorkPlan with Warranty information
                WorkPlan updatedWorkPlan = new WorkPlan(
                    Id = workPlan.Id,
                    Warranty_Prior__c = workOrderToWarrantyMap.get(workPlan.WorkOrderId) // Assign Warranty Prior
                );
                workPlansToUpdate.add(updatedWorkPlan);
            }
        }
    
        if (!workPlansToUpdate.isEmpty()) {
            update workPlansToUpdate;
            System.debug('Updated WorkPlans: ' + workPlansToUpdate);
        }
    }
    
    
}