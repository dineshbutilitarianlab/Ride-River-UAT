@isTest
public class createPurchaseOrderFormControllerTest {
    @isTest
    static void testCreatePurchaseOrder() {
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Location testLocation = new Location(Name = 'Test Location',LocationType='State');
        //insert testLocation;
        
        
        String status = 'New';
        String shipmentType = 'VOR';
        String accountRecordId = testAccount.Id;
        String locationRecordId = '131F4000000CvarIAC';
        
        
        Test.startTest();
        
        String result = createPurchaseOrderFormController.createPurchaseorder(status, shipmentType, accountRecordId, locationRecordId);
        
        Test.stopTest();
        
        
        System.assertNotEquals(null, result, 'The result should not be null.');
      //  System.assert(result.startsWith('a'), 'The result should be a valid Salesforce Id.');
        
       
        ProductRequest insertedProductRequest = [SELECT Id, Status, ShipmentType, Account__c, Destination_Location__c 
                                                 FROM ProductRequest 
                                                 WHERE Id = :result 
                                                 LIMIT 1];
        
        
        System.assertEquals(status, insertedProductRequest.Status, 'Status should match.');
        System.assertEquals(shipmentType, insertedProductRequest.ShipmentType, 'ShipmentType should match.');
        System.assertEquals(accountRecordId, insertedProductRequest.Account__c, 'Account__c should match.');
        System.assertEquals(locationRecordId, insertedProductRequest.Destination_Location__c, 'Destination_Location__c should match.');
    }

    @isTest
    static void testCreatePurchaseOrderError() {
        
        try {
            String result = createPurchaseOrderFormController.createPurchaseorder(null, null, null, null);
          //  System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error'), 'Error message should contain "Error".');
        }
    }

}