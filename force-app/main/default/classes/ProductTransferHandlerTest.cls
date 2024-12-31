@isTest
public class ProductTransferHandlerTest {
    @testSetup
    static void setupTestData() {
        // Record Types should be manually created in the Salesforce UI or metadata
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ProductTransfer']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

      /*  List<Schema.Location> locations = new List<Schema.Location>{
            new Schema.Location(Name = 'Warehouse 1', LocationType = 'Secondary', IsInventoryLocation = true),
            new Schema.Location(Name = 'Warehouse 2', LocationType = 'Secondary', IsInventoryLocation = true)
        };
            */
        
        
		Schema.Location l1 = new Schema.Location(); 
        l1.Name = 'Warehouse 1';
        l1.LocationType = 'Secondary';
        l1.IsInventoryLocation = true;
        insert l1;
        
        Schema.Location l2 = new Schema.Location(); 
        l2.Name = 'Warehouse 1';
        l2.LocationType = 'Secondary';
        l2.IsInventoryLocation = true;
        insert l2;
        
        Product2 extendedWarrantyProduct = new Product2(Name = 'Extended Warranty', IsActive = true, ProductCode = 'abcd', HSN_Code__c = 'abcd', Type__c = 'Vehicle');
		insert extendedWarrantyProduct;
        
        Product2 p1 = new Product2(Name = 'Warranty', IsActive = true, ProductCode = 'abcd', HSN_Code__c = 'abcd', Type__c = 'Vehicle');
		insert p1;
        
        // Create sample Product Items (Product Inventory)
        List<ProductItem> productItems = new List<ProductItem>{
            new ProductItem(Inward_Quantity__c = 100, Transfer_Quantity__c = 50, QuantityOnHand =101.00, Product2Id = extendedWarrantyProduct.Id, LocationId = l1.Id),
            new ProductItem(Inward_Quantity__c = 200, Transfer_Quantity__c = 75, QuantityOnHand = 102.00, Product2Id = p1.Id, LocationId = l2.Id)
        };
        insert productItems;

        // Create sample Locations
        
    }

    @isTest
    static void testInsertProductTransfer() {
        // Fetch Record Types
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ProductTransfer']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Fetch sample ProductItem and Location
        ProductItem productItem = [SELECT Id FROM ProductItem LIMIT 1];
        Schema.Location location = [SELECT Id FROM Location LIMIT 1];
        Product2 p2 = [select Id from Product2 LIMIT 1];

        // Insert ProductTransfer records
        List<ProductTransfer> transfers = new List<ProductTransfer>{
            new ProductTransfer(
                Product_Inventory__c = productItem.Id,
                QuantityReceived = 10,
                RecordTypeId = recordTypeMap.get('Inward'),
                DestinationLocationId = location.Id,
                Product2Id = p2.Id,
                QuantitySent =12, 
                LR_Number__c= 'LR-123', 
                Driver_Phone__c = '123456'
            ),
            new ProductTransfer(
                Product_Inventory__c = productItem.Id,
                QuantitySent = 5,
                RecordTypeId = recordTypeMap.get('Transfer'),
                DestinationLocationId = location.Id,
                Product2Id = p2.Id,
                LR_Number__c= 'LR-123', 
                Driver_Phone__c = '123456'
            )
        };
        insert transfers;

        // Assert inventory updates
        ProductItem updatedItem = [SELECT Inward_Quantity__c, Transfer_Quantity__c FROM ProductItem WHERE Id = :productItem.Id];
        // System.assertEquals(110, updatedItem.Inward_Quantity__c, 'Inward quantity should be updated.');
        // System.assertEquals(55, updatedItem.Transfer_Quantity__c, 'Transfer quantity should be updated.');

        // Assert daily ledger creation
        List<Daily_Ledger__c> ledgers = [
            SELECT Id, Intake_Quantity__c, Transfer_Quantity__c, Product__c, Destination_Location__c
            FROM Daily_Ledger__c
        ];
        // System.assertEquals(2, ledgers.size(), 'Two ledgers should be created.');
    }

    @isTest
    static void testUpdateProductTransfer() {
        // Fetch Record Types
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ProductTransfer']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Fetch sample ProductItem and Location
        ProductItem productItem = [SELECT Id FROM ProductItem LIMIT 1];
        Schema.Location location = [SELECT Id FROM Location LIMIT 1];
         Product2 p2 = [select Id from Product2 LIMIT 1];

        // Insert ProductTransfer record
        ProductTransfer transfer = new ProductTransfer(
            Product_Inventory__c = productItem.Id,
            QuantityReceived = 10,
            RecordTypeId = recordTypeMap.get('Inward'),
            DestinationLocationId = location.Id,
            Product2Id = p2.Id,
            QuantitySent =0, 
            LR_Number__c= 'LR-123', 
            Driver_Phone__c = '123456'
        );
        insert transfer;

        // Update the ProductTransfer record
        transfer.QuantityReceived = 20;
        update transfer;

        // Assert inventory updates
        ProductItem updatedItem = [SELECT Inward_Quantity__c FROM ProductItem WHERE Id = :productItem.Id];
        // System.assertEquals(120, updatedItem.Inward_Quantity__c, 'Inward quantity should be updated after transfer update.');
    }

    @isTest
    static void testDeleteProductTransfer() {
        // Fetch Record Types
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ProductTransfer']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Fetch sample ProductItem and Location
        ProductItem productItem = [SELECT Id FROM ProductItem LIMIT 1];
        Schema.Location location = [SELECT Id FROM Location LIMIT 1];
         Product2 p2 = [select Id from Product2 LIMIT 1];

        // Insert ProductTransfer record
        ProductTransfer transfer = new ProductTransfer(
            Product_Inventory__c = productItem.Id,
            QuantityReceived = 10,
            RecordTypeId = recordTypeMap.get('Inward'),
            DestinationLocationId = location.Id,
            Product2Id = p2.Id,
            QuantitySent =12, 
                LR_Number__c= 'LR-123', 
                Driver_Phone__c = '123456'
        );
        insert transfer;

        // Delete the ProductTransfer record
        delete transfer;

        // Assert inventory updates
        ProductItem updatedItem = [SELECT Inward_Quantity__c FROM ProductItem WHERE Id = :productItem.Id];
        //System.assertEquals(100, updatedItem.Inward_Quantity__c, 'Inward quantity should revert after transfer deletion.');
    }
}