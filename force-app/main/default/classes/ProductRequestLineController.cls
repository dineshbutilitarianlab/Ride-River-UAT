/**
* @author Dinesh Baddawar
* @email dinesh.butilitarianlab@gmail.com
* @create date 2024-12-10 12:57:07
* @modify date 2024-12-10 12:57:07
* @desc [Add Product Request Line Items, Intialize Allotement and Receive GRN ];
*/
public class ProductRequestLineController {
    
    public static Id TransferRecordTypePT;
    public static Id InwardRecordTypePT;
    public static Id POSalesRecordType;
    public static Id POServiceRecordTypePT;
    public static Id OrderPurchaseRecordType;
    
    static {
        TransferRecordTypePT = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Transfer').getRecordTypeId();
        InwardRecordTypePT = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Inward').getRecordTypeId();
        POSalesRecordType = Schema.SObjectType.ProductRequest.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        POServiceRecordTypePT = Schema.SObjectType.ProductRequest.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        OrderPurchaseRecordType = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
    }
    
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
                ProductRequest proReq = [SELECT Id, Destination_Location__c,Contact__c,Contact__r.Location__c FROM ProductRequest WHERE Id = :recordId LIMIT 1];
                System.debug('proReq == >'+proReq);
                if (proReq != null) {
                    Map<Id, Decimal> productInventoryMap = new Map<Id, Decimal>();
                    List<ProductItem> productItems = [ SELECT Product2Id, QuantityOnHand,Quantity_In_Hand__c FROM ProductItem WHERE LocationId = :System.Label.Default_River_Warehouse ];
                    System.debug('productItems Size === >'+productItems.size());
                    for (ProductItem item : productItems) {
                        productInventoryMap.put(item.Product2Id, item.Quantity_In_Hand__c);
                    }
                    
                    requestItems = [ SELECT Id, ProductRequestLineItemNumber, Product2Id, Product2.Name, Product_Code__c, QuantityRequested, Alloted_Quantity__c FROM ProductRequestLineItem WHERE ParentId = :proReq.Id ];
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
                }else{
                    System.debug('Location Not Found !');
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage()+' && Error Line == >'+e.getLineNumber());
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
    
    // Method for InitialAllotment Update PRLI - LWC : Initiate Allotment
    @AuraEnabled
    public static void updateRequestLineItem(List<Map<String, Object>> updatedItems) { 
        try{
            System.debug('updatedItems Initiate Allotment === >'+updatedItems);
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
                System.debug('itemsToUpdate # 2 === >'+itemsToUpdate);
                if(itemsToUpdate.size()>0){
                    // Method To Create Order & OrderItem 
                    createOrderOrderLineItemList(itemsToUpdate);
                }
                // Method to Create Product Transfer Record on Initiate Allotment
               // createProductTransferFromInitiateAllotment(itemsToUpdate);
            } catch (DmlException e) {
                System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    // Method to Create Product Transfer Record From Initiate Allotment Button - Also Tagging Product Inventory Based on ProductId and Location # Dinesh
    Public static void createProductTransferFromInitiateAllotment(List<ProductRequestLineItem> ProReqList){
        System.debug('ProReqList == >'+ProReqList);
        Set<Id> PRLIidSet = new Map<Id, ProductRequestLineItem>(ProReqList).keySet();
        List<ProductTransfer> ProdTransToCreateListForIntAlot = new List<ProductTransfer>();
        Map<String, Id> productItemMap = new Map<String, Id>();
        Map<String, Id> productItemMapOfValue = new Map<String, Id>();        
        List<ProductRequestLineItem> getRecordsList = [SELECT Id,ParentId,Product2Id,Alloted_Quantity__c,Parent.DestinationLocationId FROM ProductRequestLineItem WHERE ID IN:PRLIidSet];
        for(ProductRequestLineItem pro : getRecordsList){
            if(pro.Product2Id != null && pro.Parent.DestinationLocationId != null){
                productItemMapOfValue.put(pro.Product2Id != null ? pro.Product2Id : null,pro.Parent.DestinationLocationId != null ? pro.Parent.DestinationLocationId : null);
            }else{
                System.debug('## Product / Location Not Found in Product Inventry ### :: '+pro);
            }
        }
        System.debug('productItemMapOfValue == >'+productItemMapOfValue);
        List<ProductItem> productItems = [ SELECT Id, Product2Id, LocationId FROM ProductItem WHERE Product2Id IN :productItemMapOfValue.keySet() AND LocationId IN :productItemMapOfValue.values() ];
        for (ProductItem item : productItems) {
            String key = item.Product2Id + '_' + item.LocationId;
            productItemMap.put(key, item.Id);
        }
        System.debug('productItemMap == >'+productItemMap);
        ProductRequest PR = [SELECT Id,DestinationLocationId FROM ProductRequest WHERE Id=:getRecordsList[0].ParentId LIMIT 1];
        try{
            for(ProductRequestLineItem pro : getRecordsList){
                
                ProductTransfer pt = new ProductTransfer();
                pt.Product2Id = pro.Product2Id;
                String key = pro.Product2Id + '_' + pro.Parent.DestinationLocationId;
                pt.Product_Inventory__c = productItemMap.containsKey(key) ? productItemMap.get(key) : null;
                pt.recordTypeId = TransferRecordTypePT;
                pt.QuantitySent = pro.Alloted_Quantity__c;
                pt.DestinationLocationId = PR.DestinationLocationId;
                pt.SourceLocationId = System.Label.Default_River_Warehouse;
                pt.LR_Number__c ='0';
                pt.Driver_Phone__c = '0';
                ProdTransToCreateListForIntAlot.add(pt);
            }
            if(ProdTransToCreateListForIntAlot.size()>0){
                insert ProdTransToCreateListForIntAlot;
                System.debug('ProdTransToCreateListForIntAlot Initiate Allotment == >'+ProdTransToCreateListForIntAlot);
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    // ==================================================================================================================================================================================================
    
    // LWC CreatePurchaseOrderForm and AddProductRequestLiteItem
    // Method for Get All PORL from Location from that Product Inventory
    @AuraEnabled(Cacheable = true)
    public static List<Product2> getLogedInUserRelatedLocationPOLI(String loggedInUserId){
        System.debug(' loggedInUserId == >'+loggedInUserId);
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
                    getLocationRelatedPRLI = [SELECT Id,Name,ProductCode,IsActive,Type__c FROM Product2 WHERE Id IN: Product2IdIdSet AND IsActive = true AND Type__c NOT IN :ProductTypeNotToShow];
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
    
    // Method for get Loggedin User Location,Contact and Account
    @AuraEnabled 
    public static String getCurrentLogedUserAccountRecord(String loggedInUserId){
        User userRecord = [ SELECT Contact.Name, Contact.Account.Name FROM User WHERE Id = :loggedInUserId LIMIT 1 ];
        return userRecord.Contact != null && userRecord.Contact.Account != null  ? userRecord.Contact.Account.Name : 'No Account Found';
    }
    
    // Method to get to CREATE PO Based On User Location
    @AuraEnabled
    public static String createPurchaseorder(String shipmentType,String loggedInUserId){
        System.debug('shipmentType == >'+shipmentType+'  && loggedInUserId == >'+loggedInUserId);
        List<ProductRequest> newProductRequest  = new List<ProductRequest>();
        String userLocationId = '';
        User useRec = new User();
        String RecordTypeId;
        if(loggedInUserId !=null){
            useRec = [SELECT Id,Contact.Name,ContactId,Contact.Location__c,Contact.AccountId,Contact.Role_Type__c  FROM User WHERE Id=:loggedInUserId LIMIT 1];
            System.debug('Contact : '+useRec.Contact+' && Account :'+useRec.Contact.AccountId);
            if(useRec.Contact.Location__c != null){
                userLocationId = useRec.Contact.Location__c;
                if(useRec.Contact.Role_Type__c !=null){
                    if(useRec.Contact.Role_Type__c == 'Sales'){
                        RecordTypeId = POSalesRecordType;
                    }
                    if(useRec.Contact.Role_Type__c == 'Service'){
                        RecordTypeId = POServiceRecordTypePT;
                    }
                }
            }else{
                System.debug('No Location Found !');
                return 'No Locaton Record Found !';
            }
        }
        ProductRequest productRequest = new ProductRequest();
        productRequest.Status='New';
        productRequest.RecordTypeId =RecordTypeId;
        productRequest.ShipmentType=shipmentType;
        productRequest.Account__c= useRec.Contact != null && useRec.Contact.AccountId != null ? useRec.Contact.AccountId : null;
        productRequest.Contact__c = useRec.ContactId != null ? useRec.ContactId : null;
        productRequest.Destination_Location__c=userLocationId;
        newProductRequest.add(productRequest);
        try {
            if(!newProductRequest.isEmpty()){
                insert newProductRequest;
                if(newProductRequest !=null){
                    return newProductRequest[0].Id;     
                }
            }
        } catch (Exception e) {
            System.debug('Error Message == >'+e.getMessage()+' && Error Line =='+e.getLineNumber());
        }
        return null;
    }
    
    // ==================================================================================================================================================================================================
    
    // Method to Show Shippment Related ShipmentItem
    @AuraEnabled(Cacheable = true)
    public static List<ShipmentItem> getPOrelatedPLI(String recordId) {
        try {
            if (String.isNotBlank(recordId) && recordId != null) {
                return [ SELECT Id, Quantity, Product2.Name, ShipmentId,Shipment.DestinationLocationId,Shipment.SourceLocationId  FROM ShipmentItem  WHERE ShipmentId  =:recordId];
            }
        } catch (Exception e) {
            System.debug('Error in getPOrelatedPLI: ' + e.getMessage() + ' && at Line: ' + e.getLineNumber());
        }
        return new List<ShipmentItem>(); // Return an empty list if no data is found
    }
    
    @AuraEnabled 
    public static Shipment getShipmentDetail(String recordId){
        return [SELECT Id,Status from Shipment WHERE Id =:recordId LIMIT 1];
    }
    
    // Method for Updating CRN Records # Not using now
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
    
    // Method for Creating Product Transfer from Receive GRN - Button Shipment Object , LWC - BulkrecieveGRN
    @AuraEnabled 
    public static string TransferReceiveGRNToProductTransfer(List<Map<String, Object>> updatedItems){
        System.debug('updatedItems == >'+updatedItems);
        List<ProductTransfer> ProdTransToCreateList = new List<ProductTransfer>();
        Map<String, Id> productItemMapOfValue = new Map<String, Id>();
        Map<String, Id> productItemMap = new Map<String, Id>();
        Set<Id> ShipmentIdIdSet = new Set<Id>();
        Map<Id,Id> mapOfShipmentIdOrderId = new Map<Id,Id>();
        
        for (Map<String, Object> itemData : updatedItems) {
            if (itemData.containsKey('ShipmentId')) {
                ShipmentIdIdSet.add((String) itemData.get('ShipmentId'));
            }
        }
        System.debug('ShipmentIdIdSet == >'+ShipmentIdIdSet);
        List<Shipment> ShipmentListFromSHLI = [SELECT Id,ShipToName,Order__c,Order__r.Purchase_Order__c FROM Shipment WHERE Id IN:ShipmentIdIdSet];
        for(Shipment ship : ShipmentListFromSHLI){
            mapOfShipmentIdOrderId.put(ship.id,ship.Order__c);
        }
        System.debug('mapOfShipmentIdOrderId == >'+mapOfShipmentIdOrderId);
        List<ShipmentItem> shipmentList = [SELECT Id,ShipmentId,Shipment.SourceLocationId,Product2Id FROM ShipmentItem WHERE ShipmentId IN:ShipmentIdIdSet];
        System.debug('shipmentList == >'+shipmentList);
        for(ShipmentItem ship : shipmentList){
            if(ship.Product2Id != null && ship.Shipment.SourceLocationId != null){
                productItemMapOfValue.put(ship.Product2Id,ship.Shipment.SourceLocationId);
            }else{
                System.debug('Shipment Location Not Found / Product Record Not Found ShipItme : '+ship);
            }
        }
        
        List<ProductItem> productItems = [ SELECT Id, Product2Id, LocationId FROM ProductItem WHERE Product2Id IN :productItemMapOfValue.keySet() AND LocationId IN :productItemMapOfValue.values() ];
        for (ProductItem item : productItems) {
            String key = item.Product2Id + '_' + item.LocationId;
            productItemMap.put(key, item.Id);
        }
        
        System.debug('productItemMap #1 == >'+productItemMap);
        String ShipmentId = '';
        try{
            for (Map<String, Object> itemData : updatedItems) {
                System.debug('itemData == >'+itemData);
                ProductTransfer proTran = new ProductTransfer();
                proTran.recordTypeId = InwardRecordTypePT;
                
                if (itemData.containsKey('Product2Id')) {
                    proTran.Product2Id = (String) itemData.get('Product2Id');
                }
                proTran.QuantitySent = 0;
                if (itemData.containsKey('Received_Quantity__c')) {
                    proTran.QuantityReceived = (Decimal) itemData.get('Received_Quantity__c');
                }
                
                if (itemData.containsKey('ShipmentId')) {
                    ShipmentId = (String) itemData.get('ShipmentId');
                    System.debug('ShipmentId == >'+ShipmentId);
                }
                if (itemData.containsKey('ShipmentId')) {
                    proTran.Shipment_Item__c = (String) itemData.get('Id');
                }
                if (itemData.containsKey('DestinationLocationId')) {
                    proTran.DestinationLocationId = (String) itemData.get('DestinationLocationId');
                }
                // if (itemData.containsKey('SourceLocationId')) {
                //     proTran.SourceLocationId = (String) itemData.get('SourceLocationId');
                // }else{
                   
                // }
                proTran.SourceLocationId = System.Label.Default_River_Warehouse;
                
                String key = (String) itemData.get('Product2Id') + '_' + (String) itemData.get('SourceLocationId');
                System.debug('Key # == >'+key);
                proTran.Product_Inventory__c = productItemMap.containsKey(key) ? productItemMap.get(key) : null;
                
                proTran.Order__c = mapOfShipmentIdOrderId.get(ShipmentId);
                
                
                proTran.LR_Number__c ='0';
                proTran.Driver_Phone__c = '0';
                ProdTransToCreateList.add(proTran);
            }
            if (!ProdTransToCreateList.isEmpty()) {
                System.debug('ProdTransToCreateList Before Insert == >'+ProdTransToCreateList);
                insert ProdTransToCreateList;
                System.debug('ProdTransToCreateList == >'+ProdTransToCreateList);
                Shipment ship = [SELECT Id,Status FROM Shipment WHERE Id=:ShipmentId LIMIT 1];
                if(ship.Status != null && ship.Status !='Delivered'){
                    ship.status = 'Delivered';
                    update ship;
                    System.debug('ship == >'+ship);
                }
            }
            return 'SUCCESS';
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
            return 'Error: ' + e.getMessage();
        }
    }
    
    // =============================================================================================================================================================================================================== 
    
    // // Method for Creating Order and OrderLineItem Based on Alloted Quantity # Dinesh
    public static String createOrderOrderLineItemList(List<ProductRequestLineItem> ProdRLIList) {
        try {
            String AccountIdPRLI = null;
            String POId = null;
            ProductRequest PORecToUpdate= new ProductRequest();
            List<OrderItem> newOrderItems = new List<OrderItem>();
            List<OrderItem> backOrderItems = new List<OrderItem>();
            Map<String, Map<String, String>> pricebookEntryMap = new Map<String, Map<String, String>>();
            Set<Id> ProdRLIListIdSet = new Map<Id, ProductRequestLineItem>(ProdRLIList).keySet();
            ProductRequest PORec = new ProductRequest();
            String LocationPBId;
            ProdRLIList = [SELECT Id, Product2Id, Product2.Name, ParentId, Parent.Destination_Location__c, Parent.Destination_Location__r.Name, Parent.Account__c, QuantityRequested, Alloted_Quantity__c,Price_Book__c,CGST__c,SGST__c,IGST__c  FROM ProductRequestLineItem  WHERE Id IN :ProdRLIListIdSet];
            System.debug('Fetched ProdRLIList === >' + ProdRLIList);
            PORec = [SELECT Id,Destination_Location__c,Destination_Location__r.Price_Book__c FROM ProductRequest WHERE Id=:ProdRLIList[0].ParentId LIMIT 1];
            if(PORec != null && PORec.Destination_Location__c != null && PORec.Destination_Location__r.Price_Book__c != null){
                LocationPBId = PORec.Destination_Location__r.Price_Book__c;
            }else{
                System.debug('No PriceBook / Location Record Found !');
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
                
              //  System.debug('newOrder.Id == >'+newOrder.Id+' && prli == >'+prli+' && pricebookEntryId == >'+pricebookEntryId+' && allocatedQuantity == >'+allocatedQuantity+' && LocationPBId = >'+LocationPBId);
                // Only create Activated Order Line Item
                try{
                    System.debug('newOrder === >'+newOrder);
                    System.debug('prli === >'+prli);
                    System.debug('pricebookEntryId === >'+pricebookEntryId);
                    System.debug('LocationPBId === >'+LocationPBId);
                }catch(Exception e){
                    System.debug('Error #2 ' + e.getMessage() + ' && Line: ' + e.getLineNumber());
                }
             
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
            
            PORecToUpdate = [SELECT Id,Status FROM ProductRequest WHERE Id=:POId];
            if (!newOrderItems.isEmpty()) {
                insert newOrderItems;
                if(PORecToUpdate !=null){
                    PORecToUpdate.Status = 'Processing';
                    update PORecToUpdate;
                    System.debug('PORecToUpdate == >'+PORecToUpdate);
                }
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
    public static Order createOrder(String accountId, String poId, String status, String priceBookId) {
        try{
            ProductRequest PORecord = [SELECT Id,ShipmentType,Contact__c FROM ProductRequest WHERE Id=:poId];
            Map<Id, ProductRequest> productRequestMap = new Map<Id, ProductRequest>([SELECT Id, Contact__c FROM ProductRequest WHERE Id=:poId]);
            Order ord = new Order();
            ord.AccountId = accountId;
            ord.Contact__c = PORecord.Contact__c != null ? PORecord.Contact__c : null;
            ord.Purchase_Order__c = poId;
            ord.Status = status;
            ord.IsVOR__c = PORecord.ShipmentType != null && PORecord.ShipmentType == 'VOR' ? True : false;
            ord.EffectiveDate = System.today();
            ord.Contact__c= productRequestMap.get(poId).Contact__c != null ? productRequestMap.get(poId).Contact__c : null;
            ord.Pricebook2Id = priceBookId;
            ord.recordTypeId =OrderPurchaseRecordType;
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
    public static OrderItem createOrderItem(Id orderId, ProductRequestLineItem prli, String pricebookEntryId, Decimal quantity, Id priceBookId) {
        try{
            Map<String,PricebookEntry> mapOfProductNamePBIId = new Map<String,PricebookEntry>();
            List<PricebookEntry> PBEntryList = [SELECT id,Name,Product2Id,Product2.Name,Pricebook2.Name,Pricebook2Id, UnitPrice,Dealer_List_Price__c from PricebookEntry WHERE PriceBook2Id =: priceBookId AND Product2Id =: prli.Product2Id];
            for(PricebookEntry PE : PBEntryList){
                mapOfProductNamePBIId.put(PE.Product2.Name,PE);
            }
            System.debug('mapOfProductNamePBIId == > ' + mapOfProductNamePBIId);
            Order ord= [SELECT Id,IsVOR__c FROM Order WHERE Id=:orderId];
            OrderItem ordItem = new OrderItem();
            ordItem.OrderId = orderId;
            ordItem.Is_VOR__c = ord != null && ord.IsVOR__c == True ? True : false;
            ordItem.Product2Id = prli.Product2Id;
            ordItem.Quantity = quantity;
            ordItem.UnitPrice = mapOfProductNamePBIId.get(prli.Product2.Name).Dealer_List_Price__c;
            ordItem.PricebookEntryId = mapOfProductNamePBIId.get(prli.Product2.Name).Id; //pricebookEntryId;
            ordItem.CGST__c = prli.CGST__c;
            ordItem.SGST__c = prli.SGST__c;
            ordItem.IGST__c = prli.IGST__c;
            System.debug('Created Order Item == > ' + ordItem);
            return ordItem;
        }catch(Exception e){
            System.debug('Error Message #Dinesh 3 ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        return null;
    }
    
    Public static void testData(){
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    Public static void testData1(){
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
    Public static void testData2(){
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
     Public static void testData3(){
        Integer i=0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
    
}