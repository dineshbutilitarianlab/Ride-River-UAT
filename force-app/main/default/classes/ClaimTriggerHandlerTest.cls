@isTest
public class ClaimTriggerHandlerTest {
    @isTest
    static void testHandleAfterInsertPositive() {
        // Step 1: Create related objects
        // 
         Account testAccount = new Account(Name = 'Test Account',Type='Customer');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        VehicleDefinition vehicleDefinition = new VehicleDefinition(Name = 'Vehicle Def 1', ProductId = testProduct.Id);
        insert vehicleDefinition;
        
        Asset asset = new Asset(Name = 'Test Asset', IsCompetitorProduct = false, IsInternal = true,AccountId=testAccount.Id, OwnerId = UserInfo.getUserId());
        insert asset;
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        
        Vehicle vehicle = new Vehicle(
            Name = 'Test Vehicle',
            VehicleDefinitionId = vehicleDefinition.Id,
            AssetId = asset.Id,
            IsRecallOpen = false,
            IsTelematicsServiceActive = true,
            Approval_Status__c = true,
            Spare_Vehicle__c = false,
            //Software_Version__c = null,
            PDI_Status_Pass__c = true,
            VehicleIdentificationNumber='A2B2', 
            Software_Version__c=testSV.Id, 
            Charger_PC_Number__c='123'
        );
        insert vehicle;

        WorkOrder workOrder = new WorkOrder(
            OwnerId = UserInfo.getUserId(),
            Vehicle__c = vehicle.Id,
            IsStopped = false
        );
        insert workOrder;

        Warranty_Prior__c warranty = new Warranty_Prior__c(OwnerId = UserInfo.getUserId(), Job_Card__c = workOrder.Id);
        insert warranty;

        WorkOrderLineItem lineItem = new WorkOrderLineItem(
            Warranty_Prior__c = warranty.Id,
            //TotalAmount__c = 500.00,
            Consequential_Part__c = 'Oil',
            Part_Description__c = 'Part A',
            Electrical_Value__c = '200',
            Quantity = 2,
            Hours__c = 4
        );
        insert lineItem;

        Claim claim = new Claim(Name = 'Test Claim', Warranty_Prior__c = warranty.Id, OwnerId = UserInfo.getUserId());
        insert claim;

        // Step 2: Query created ClaimItems and validate
        List<ClaimItem> claimItems = [SELECT Name, ClaimId, Part__c, Amount__c FROM ClaimItem WHERE ClaimId = :claim.Id];
        System.assertEquals(1, claimItems.size(), 'One ClaimItem should be created');
        System.assertEquals(claim.Id, claimItems[0].ClaimId, 'ClaimItem should be associated with the correct Claim');
        System.assertEquals(lineItem.Id, claimItems[0].Part__c, 'ClaimItem should be associated with the correct WorkOrderLineItem');
    }

    @isTest
    static void testHandleAfterInsertNegative() {
        
        
        // Scenario where Claim lacks Warranty_Prior__c
        // 
        Account testAccount = new Account(Name = 'Test Account',Type='Customer');
        insert testAccount;

        Claim claimWithoutWarranty = new Claim(Name = 'Invalid Claim', Warranty_Prior__c = null,AccountId=testAccount.Id, OwnerId = UserInfo.getUserId());
        insert claimWithoutWarranty;

        // No ClaimItems should be created
        List<ClaimItem> claimItems = [SELECT Id FROM ClaimItem WHERE ClaimId = :claimWithoutWarranty.Id];
        System.assertEquals(0, claimItems.size(), 'No ClaimItems should be created if Warranty_Prior__c is null');
    }
}