@isTest
public class ProductRequestLineControllerTest {
    
    @isTest
    static void testData(){
        Product2 testProduct = new Product2( Name = 'Test Product', IsActive = true, ProductCode = 'SDFGHJ', HSN_Code__c = 'DFGHJ',Type__c = 'Parts');
        insert testProduct;
        Account acc =new Account(name = 'test');
        insert acc;
        
        ProductRequest testProductRequest = new ProductRequest(AccountId = acc.id, ShipmentType = 'VOR' );
        insert testProductRequest;
        
        ProductRequestLineItem lineItem1 = new ProductRequestLineItem( ParentId = testProductRequest.Id, Product2Id = testProduct.Id, QuantityRequested = 10, Alloted_Quantity__c = 5);
        insert lineItem1;
        
        Test.startTest();
        List<ProductRequestLineItem> result = ProductRequestLineController.getProductRequestItems(testProductRequest.Id);
        Test.stopTest();
    }
}