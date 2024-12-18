@isTest
public class OrderTriggerHandlerTest {
    @isTest 
   static void testOrderUpdate(){
         Account testAccount = new Account(Name = 'Test Account',Type='Customer');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true,ProductCode='abcd',HSN_Code__c='abcd',Type__c='Vehicle');
        insert testProduct;
        
        Id stdPrBk = Test.getStandardPricebookId();

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = stdPrBk,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        Asset testAsset = new Asset(Name='Test Asset',AccountId=testAccount.Id,	Product2Id=testProduct.Id);
        insert testAsset;
        
        VehicleDefinition testVD = new VehicleDefinition(Name='Test VehicleDefinition',ProductId=testProduct.Id);
        insert testVD;
       
        
        Software_Version__c testSV = new Software_Version__c(Name='Test Software Version');
        insert testSV;
        
        
        Vehicle testVehicle = new Vehicle(Name='Test Vehicle', Account__c=testAccount.Id, AssetId=testAsset.Id, 
                                          VehicleDefinitionId=testVD.Id, VehicleIdentificationNumber='A2B3', 
                                          Software_Version__c=testSV.Id, Charger_PC_Number__c='abcd',PDI_Status_Pass__c=true);
        insert testVehicle;
       
              AssetMilestone asm = new AssetMilestone(Name = 'ASM1', MilestoneDate = Date.today().addMonths(2), 
                                              Stage = 'Active', AssetId = testAsset.Id, UsageType = 'Automotive', MilestoneType = 'PDI', VehicleId = testVehicle.Id);
       insert asm;

        Order oldOrder = new Order(
            AccountId = testAccount.Id,
            Status__c = 'Processing',
            Status='Processing',
            Assigned_Vehicle__c = testVehicle.Id,
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPrBk,
            Payment_Status__c = 'Completed'
            
        );
        insert oldOrder;
        
        OrderItem testOrderItem = new OrderItem(
            OrderId = oldOrder.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.0,
            Quantity = 1,
            PricebookEntryId = testPricebookEntry.Id
        );
        insert testOrderItem;

        
        
        
        Test.startTest();
        oldOrder.Status = 'Vehicle Delivered';
        update oldOrder;
        Test.stopTest();

        
       
    }

  }