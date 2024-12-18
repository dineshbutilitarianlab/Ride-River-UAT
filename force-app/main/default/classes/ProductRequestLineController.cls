/**
* @author Dinesh Baddawar
* @email dinesh.butilitarianlab@gmail.com
* @create date 2024-12-10 12:57:07
* @modify date 2024-12-10 12:57:07
* @desc [Add Product Request Line Items, Intialize Allotement and Receive GRN ];
*/
public class ProductRequestLineController {
    
    // Method for InitialAllotment
    @AuraEnabled(Cacheable = true)
    public static List<ProductRequestLineItem> getProductRequestItems(String recordId) {
        return [SELECT Id, ProductRequestLineItemNumber, Product2.Name,Product2.isActive, Product_Code__c, QuantityRequested,Alloted_Quantity__c FROM ProductRequestLineItem WHERE ParentId =: recordId AND Product2.isActive = TRUE];
    }
    
    // Method for InitialAllotment Updated
    @AuraEnabled(Cacheable = true)
    public static List<ProductRequestWrapper> getProductRequestItemsWithAvailableQty(String recordId) {
        List<ProductRequestWrapper> wrapperList = new List<ProductRequestWrapper>();
        List<ProductRequestLineItem> requestItems  = new List<ProductRequestLineItem>();
        try {
            if (recordId != null) {
                ProductRequest proReq = [SELECT Id, Destination_Location__c FROM ProductRequest WHERE Id = :recordId LIMIT 1];
                if (proReq != null && proReq.Destination_Location__c != null) {
                    Map<Id, Decimal> productInventoryMap = new Map<Id, Decimal>();
                    List<ProductItem> productItems = [ SELECT Product2Id, QuantityOnHand,Quantity_In_Hand__c FROM ProductItem WHERE LocationId = :System.Label.Default_River_Warehouse ];
                    System.debug('productItems Size === >'+productItems.size());
                    for (ProductItem item : productItems) {
                        productInventoryMap.put(item.Product2Id, item.Quantity_In_Hand__c);
                    }
                    
                    requestItems = [ SELECT Id, ProductRequestLineItemNumber, Product2Id, Product2.Name, Product_Code__c, QuantityRequested, Alloted_Quantity__c FROM ProductRequestLineItem WHERE ParentId = :recordId ];
                    System.debug('requestItems Size === >'+requestItems.size());
                    for (ProductRequestLineItem item : requestItems) {
                        System.debug('item == >'+item);
                        ProductRequestWrapper wrapper = new ProductRequestWrapper();
                        wrapper.Id = item.Id;
                        wrapper.ProductRequestLineItemNumber = item.ProductRequestLineItemNumber;
                        wrapper.ProductName = item.Product2?.Name;
                        wrapper.ProductCode = item.Product_Code__c;
                        wrapper.QuantityRequested = item.QuantityRequested;
                        wrapper.AllocatedQuantity = item.Alloted_Quantity__c;
                        wrapper.QuantityOnHand = productInventoryMap.get(item.Product2Id) != null ? productInventoryMap.get(item.Product2Id) : 0;
                        wrapperList.add(wrapper);
                    }
                    System.debug('wrapperList == >'+wrapperList);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        System.debug('wrapperList Final == >'+wrapperList);
        return wrapperList;
    }
    
    public class ProductRequestWrapper {
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String ProductRequestLineItemNumber;
        @AuraEnabled
        public String ProductName;
        @AuraEnabled
        public String ProductCode;
        @AuraEnabled
        public Decimal QuantityRequested;
        @AuraEnabled
        public Decimal AllocatedQuantity;
        @AuraEnabled
        public Decimal QuantityOnHand;
    }
    
    // Method for InitialAllotment Update PRLI
    @AuraEnabled
    public static void updateRequestLineItem(List<Map<String, Object>> updatedItems) {
        List<ProductRequestLineItem> itemsToUpdate = new List<ProductRequestLineItem>();
        for (Map<String, Object> itemData : updatedItems) {
            Id itemId = (Id)itemData.get('Id');
            Decimal allocatedQuantity = (Decimal)itemData.get('Alloted_Quantity__c');            
            ProductRequestLineItem requestItem = [SELECT Id, Product2Id FROM ProductRequestLineItem WHERE Id = :itemId LIMIT 1];
            requestItem.Alloted_Quantity__c = allocatedQuantity;
            itemsToUpdate.add(requestItem);
        }
        try {
            update itemsToUpdate;
            if(itemsToUpdate.size()>0){
                createOrderOrderLineItemList(itemsToUpdate);
            }
        } catch (DmlException e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    // Method for Get PO Related Bulk PRLI Records
    @AuraEnabled(Cacheable = true)
    public static List<Product2> getPORelatedPRLI(String recordId, String loggedInUserId){
        System.debug('recordId === >'+recordId+' && loggedInUserId == >'+loggedInUserId);
        ProductRequest ProdReqRecord = new ProductRequest();
        List<ProductItem> getProdItemList = new List<ProductItem>();
        List<Product2> getLocationRelatedPRLI = new List<Product2>();
        Set<Id> Product2IdIdSet = new Set<Id>();
        Contact loggedInUserContactRecord = new Contact();
        User logedUser = new User();
        Set<String> ProductTypeNotToShow = new Set<String>();
        try{
            if(loggedInUserId !=null){
                logedUser = [SELECT Id,Contact.Name,ContactId  FROM User WHERE Id=:loggedInUserId LIMIT 1];
                System.debug('logedUser === >'+logedUser);
                if(logedUser.ContactId !=null){
                    loggedInUserContactRecord = [ SELECT Id,Name,Role_Type__c FROM Contact where Id =:logedUser.ContactId LIMIT 1];
                    System.debug('Contact Role Type === >'+loggedInUserContactRecord.Role_Type__c);
                }
                if(loggedInUserContactRecord.Role_Type__c !=null){
                    if(loggedInUserContactRecord.Role_Type__c == 'Service'){
                        ProductTypeNotToShow = new Set<String>{'Vehicle','Merchandise'};
                            }
                    if(loggedInUserContactRecord.Role_Type__c == 'Sales'){
                        ProductTypeNotToShow = new Set<String>{'Parts'};
                            }
                }
                System.debug('ProductTypeNotToShow === >'+ProductTypeNotToShow);
            }
            
            // By Default Location will be - Custom Label - 
            System.debug('Label Value == >'+System.Label.Default_River_Warehouse);
            getProdItemList  = [SELECT Id,Product2Id,LocationId FROM ProductItem WHERE LocationId =:System.Label.Default_River_Warehouse];
            System.debug('getProdItemList === >'+logedUser);
            if(getProdItemList.size()>0){
                for(ProductItem prod : getProdItemList){
                    if(prod.Product2Id !=  null){
                        Product2IdIdSet.add(prod.Product2Id);
                    }
                }
                System.debug('Product2IdIdSet === >'+Product2IdIdSet);
                if(Product2IdIdSet.size()>0){
                    getLocationRelatedPRLI = [SELECT Id,Name,HSN_Code__c,IsActive,Type__c FROM Product2 WHERE Id IN: Product2IdIdSet AND IsActive = true AND Type__c NOT IN :ProductTypeNotToShow];
                    System.debug('getLocationRelatedPRLI === >'+getLocationRelatedPRLI);
                    if(getLocationRelatedPRLI.size()>0){
                        return getLocationRelatedPRLI;
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;
    }
    
    // Method for Creation Bulk RLI Records
    @AuraEnabled
    public static String createProductRequestLineItems(String jsonData) {
        System.debug('jsonData === >'+jsonData);
        try {
            List<ProductRequestLineItemWrapper> lineItems = (List<ProductRequestLineItemWrapper>) JSON.deserialize(jsonData, List<ProductRequestLineItemWrapper>.class);
            List<ProductRequestLineItem> recordsToInsert = new List<ProductRequestLineItem>();
            for (ProductRequestLineItemWrapper item : lineItems) {
                ProductRequestLineItem newRecord = new ProductRequestLineItem(
                    Product2Id = item.Product2Id,
                    ParentId = item.ParentId,
                    QuantityRequested = item.QuantityRequested
                );
                recordsToInsert.add(newRecord);
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
                System.debug('recordsToInsert === >'+recordsToInsert);
                if(recordsToInsert.size()>0){
                    return 'SUCCESS';
                }
            }
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            return 'Error : '+e.getMessage();
        }
        return null;
    }
    
    public class ProductRequestLineItemWrapper {
        public String Product2Id { get; set; }
        public String ParentId { get; set; }
        public Decimal QuantityRequested { get; set; }
    }
    
    // Method to Show Shippment Related ShipmentItem
    @AuraEnabled(Cacheable = true)
    public static List<ShipmentItem> getPOrelatedPLI(String recordId) {
        try {
            if (String.isNotBlank(recordId) && recordId != null) {
                return [ SELECT Id, Quantity, Product2.Name, ShipmentId,Shipment.DestinationLocationId,Shipment.SourceLocationId  FROM ShipmentItem  WHERE ShipmentId  =:recordId];
            }
        } catch (Exception e) {
            System.debug('Error in getPOrelatedPLI: ' + e.getMessage() + ' && at Line: ' + e.getLineNumber());
            throw new AuraHandledException('Unable to fetch related data. Please contact support.');
        }
        return new List<ShipmentItem>(); // Return an empty list if no data is found
    }
    
    // Method for Updating CRN Records
    @AuraEnabled
    public static String updateProductRequestLineItem(List<Map<String, Object>> updatedItems) {
        try {
            List<ProductRequestLineItem> itemsToUpdate = new List<ProductRequestLineItem>();
            System.debug('updatedItems == >'+updatedItems);
            for (Map<String, Object> itemData : updatedItems) {
                Id itemId = (Id)itemData.get('Id');
                Decimal RecievedQuantity = (Decimal)itemData.get('Received_Quantity__c');            
                ProductRequestLineItem requestItem = [SELECT Id, Product2Id FROM ProductRequestLineItem WHERE Id = :itemId LIMIT 1];
                requestItem.Received_Quantity__c = RecievedQuantity;
                itemsToUpdate.add(requestItem);
            }
            update itemsToUpdate;
            System.debug('itemsToUpdate == >'+itemsToUpdate);
            if(itemsToUpdate !=null){
                return 'SUCCESS';
            }
        } catch (Exception e) {
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            return 'Error == >'+e.getMessage();
        }
        return null;
    }
    
    // Method for Creating Product Transfer from Receive GRN
    @AuraEnabled 
    public static string TransferReceiveGRNToProductTransfer(List<Map<String, Object>> updatedItems){
        System.debug('updatedItems == >'+updatedItems);
        List<ProductTransfer> ProdTransToCreateList = new List<ProductTransfer>();
        try{
            Id transferRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'ProductTransfer' AND Name = 'Transfer' LIMIT 1].Id;
            for (Map<String, Object> itemData : updatedItems) {
                System.debug('itemData == >'+itemData);
                ProductTransfer proTran = new ProductTransfer();
                proTran.recordTypeId = transferRecordTypeId;
                if (itemData.containsKey('Product2Id')) {
                    proTran.Product2Id = (String) itemData.get('Product2Id');
                }
                
                if (itemData.containsKey('Received_Quantity__c')) {
                    proTran.QuantitySent = (Decimal) itemData.get('Received_Quantity__c');
                }
                
                if (itemData.containsKey('ShipmentId')) {
                    proTran.Shipment_Item__c = (String) itemData.get('Id');
                }
                if (itemData.containsKey('DestinationLocationId')) {
                    proTran.DestinationLocationId = (String) itemData.get('DestinationLocationId');
                }
                if (itemData.containsKey('SourceLocationId')) {
                    proTran.SourceLocationId = (String) itemData.get('SourceLocationId');
                }
                proTran.LR_Number__c ='0';
                proTran.Driver_Phone__c = '0';
                ProdTransToCreateList.add(proTran);
            }
            if (!ProdTransToCreateList.isEmpty()) {
                insert ProdTransToCreateList;
                System.debug('ProdTransToCreateList == >'+ProdTransToCreateList);
            }
            return 'SUCCESS';
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            return 'Error: ' + e.getMessage();
        }
    }
    
    // // Method for Creating Order and OrderLineItem Based on Alloted Quantity # Dinesh
    public static String createOrderOrderLineItemList(List<ProductRequestLineItem> ProdRLIList) {
        try {
            String AccountIdPRLI = null;
            String POId = null;
            List<OrderItem> newOrderItems = new List<OrderItem>();
            List<OrderItem> backOrderItems = new List<OrderItem>();
            Map<String, Map<String, String>> pricebookEntryMap = new Map<String, Map<String, String>>();
            Set<Id> ProdRLIListIdSet = new Map<Id, ProductRequestLineItem>(ProdRLIList).keySet();
            String LocationPBId;
            ProdRLIList = [SELECT Id, Product2Id, Product2.Name, ParentId, Parent.Destination_Location__c, Parent.Destination_Location__r.Name, Parent.Account__c, QuantityRequested, Alloted_Quantity__c,Price_Book__c  FROM ProductRequestLineItem  WHERE Id IN :ProdRLIListIdSet];
            System.debug('Fetched ProdRLIList === >' + ProdRLIList);
            
            if(ProdRLIList.size()>0){
                LocationPBId = ProdRLIList[0].Price_Book__c !=null ? ProdRLIList[0].Price_Book__c : null;
            }else{
                System.debug('No ProdRLIList Record Found !');
                return null;
            }
            if (LocationPBId == null) {
                System.debug('LocationPBId Not Found!');
                return null;
            }
            List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id = :LocationPBId];
            for (PricebookEntry entry : pricebookEntries) {
                if (!pricebookEntryMap.containsKey(entry.Product2Id)) {
                    pricebookEntryMap.put(entry.Product2Id, new Map<String, String>());
                }
                pricebookEntryMap.get(entry.Product2Id).put(entry.Pricebook2Id, entry.Id);
            }
            if (!ProdRLIList.isEmpty() && ProdRLIList[0].ParentId != null) {
                POId = ProdRLIList[0].ParentId;
                AccountIdPRLI = ProdRLIList[0].Parent.Account__c;
            }
            
            Order newOrder = createOrder(AccountIdPRLI, POId, 'Activated', LocationPBId);
            Order backOrder = null;
            
            for (ProductRequestLineItem prli : ProdRLIList) {
                System.debug('Processing PRLI: ' + prli);
                String pricebookEntryId = null;
                
                if (pricebookEntryMap.containsKey(prli.Product2Id) &&
                    pricebookEntryMap.get(prli.Product2Id).containsKey(LocationPBId)) {
                        pricebookEntryId = pricebookEntryMap.get(prli.Product2Id).get(LocationPBId);
                    }
                if (pricebookEntryId == null) {
                    System.debug('PricebookEntryId not found for Product2Id: ' + prli.Product2Id);
                    continue;
                }
                Decimal requestedQuantity = prli.QuantityRequested;
                Decimal allocatedQuantity = prli.Alloted_Quantity__c;
                Decimal remainingQuantity = (requestedQuantity - allocatedQuantity).setScale(0, RoundingMode.HALF_UP);
                
                System.debug('Requested: ' + requestedQuantity + ', Allocated: ' + allocatedQuantity + ', Remaining: ' + remainingQuantity);
                
                // Only create Activated Order Line Item
                if (remainingQuantity == 0) {
                    System.debug('Condition: Requested == Allocated');
                    newOrderItems.add(createOrderItem(newOrder.Id, prli, pricebookEntryId, allocatedQuantity, LocationPBId));
                } 
                // Create Activated and Back Order Line Items
                else if (allocatedQuantity > 0 && remainingQuantity > 0) {
                    System.debug('Condition: Allocated < Requested');
                    newOrderItems.add(createOrderItem(newOrder.Id, prli, pricebookEntryId, allocatedQuantity, LocationPBId));
                    if (backOrder == null) { // Create backOrder only when needed
                        backOrder = createOrder(AccountIdPRLI, POId, 'Back Order', LocationPBId);
                    }
                    backOrderItems.add(createOrderItem(backOrder.Id, prli, pricebookEntryId, remainingQuantity, LocationPBId));
                }
            }
            
            if (!newOrderItems.isEmpty()) {
                insert newOrderItems;
                System.debug('Inserted Activated Order Items: ' + newOrderItems);
            }
            if (!backOrderItems.isEmpty()) {
                insert backOrderItems;
                System.debug('Inserted Back Order Items: ' + backOrderItems);
            }
        } catch (Exception e) {
            System.debug('Error Creating Orders: ' + e.getMessage() + ' && Line: ' + e.getLineNumber());
        }
        return null;
    }
    
    // Helper Method to Create an Order # Dinesh
    private static Order createOrder(String accountId, String poId, String status, String priceBookId) {
        try{
            Order ord = new Order();
            ord.AccountId = accountId;
            ord.Purchase_Order__c = poId;
            ord.Status = status;
            ord.EffectiveDate = System.today();
            ord.Pricebook2Id = priceBookId;
            ord.recordTypeId = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Order' AND Name = 'Purchase' LIMIT 1].Id;
            if(status == 'Back Order'){
                ord.IsBackOrder__c = true;
            }
            insert ord;
            System.debug('Created Order ==> ! ' + ord);
            return ord;
        }catch(Exception e){
            System.debug('Error Message #Dinehs 2 ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;   
    }
    
    // Helper Method to Create an Order Item # Dinesh
    private static OrderItem createOrderItem(Id orderId, ProductRequestLineItem prli, String pricebookEntryId, Decimal quantity, Id priceBookId) {
        try{
            Map<String,PricebookEntry> mapOfProductNamePBIId = new Map<String,PricebookEntry>();
            for(PricebookEntry PE : [SELECT id,Name,Product2Id,Product2.Name,Pricebook2.Name,Pricebook2Id, UnitPrice from PricebookEntry WHERE PriceBook2Id =: priceBookId AND Product2Id =: prli.Product2Id]){
                mapOfProductNamePBIId.put(PE.Product2.Name,PE);
            }
            System.debug('mapOfProductNamePBIId == > ' + mapOfProductNamePBIId);
            OrderItem ordItem = new OrderItem();
            ordItem.OrderId = orderId;
            ordItem.Product2Id = prli.Product2Id;
            ordItem.Quantity = quantity;
            ordItem.UnitPrice = mapOfProductNamePBIId.get(prli.Product2.Name).UnitPrice;
            ordItem.PricebookEntryId = mapOfProductNamePBIId.get(prli.Product2.Name).Id; //pricebookEntryId;
            System.debug('Created Order Item == > ' + ordItem);
            return ordItem;
        }catch(Exception e){
            System.debug('Error Message #Dinesh 3 ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;
    }
    
}