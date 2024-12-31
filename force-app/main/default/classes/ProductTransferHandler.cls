public with sharing class ProductTransferHandler {
    
    public static  Id InwardRecordTypeId = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Inward').getRecordTypeId();
    
    public static  Id TransferRecordTypeId = Schema.SObjectType.ProductTransfer.getRecordTypeInfosByName().get('Transfer').getRecordTypeId();
    
    public static void onInsertProductTransferUpdateInventory(List<ProductTransfer> newTransfers) {
        try {
            Set<Id> productInventoryIds = new Set<Id>();
            System.debug('newTransfers == > ' + newTransfers);
            Map<Id, Decimal> inventoryInwardUpdates = new Map<Id, Decimal>(); 
            System.debug('inventoryInwardUpdates: ' + inventoryInwardUpdates);
            Map<Id, Decimal> inventoryTransferUpdates = new Map<Id, Decimal>();
            for (ProductTransfer transfer : newTransfers) {
                System.debug('Processing transfer = > ' + transfer);
                if (transfer.Product_Inventory__c != null) {
                    productInventoryIds.add(transfer.Product_Inventory__c);
                    
                    if (transfer.RecordTypeId == InwardRecordTypeId) {
                        Decimal currentValue = inventoryInwardUpdates.containsKey(transfer.Product_Inventory__c)
                            ? inventoryInwardUpdates.get(transfer.Product_Inventory__c) : 0;
                        System.debug('currentValue ==> ' + currentValue);
                        System.debug('Adding transfer quantity received ==> ' + (transfer.QuantityReceived != null ? transfer.QuantityReceived : 0));
                        System.debug('Adding to inventoryInwardUpdates ==> ' + inventoryInwardUpdates);
                        inventoryInwardUpdates.put(transfer.Product_Inventory__c, currentValue  + (transfer.QuantityReceived != null ? transfer.QuantityReceived : 0));
                        System.debug('Updated inventoryInwardUpdates =>  ' + inventoryInwardUpdates);
                        
                    } else if (transfer.RecordTypeId ==TransferRecordTypeId) {
                        Decimal currentValue = inventoryTransferUpdates.containsKey(transfer.Product_Inventory__c)
                            ? inventoryTransferUpdates.get(transfer.Product_Inventory__c): 0;
                        System.debug('currentValue #1 ==> ' + currentValue);
                        System.debug('Adding transfer quantity sent #2 ==> ' + (transfer.QuantitySent != null ? transfer.QuantitySent : 0));
                        System.debug('Adding to inventoryTransferUpdates #3 ==> ' + inventoryTransferUpdates);
                        inventoryTransferUpdates.put(transfer.Product_Inventory__c, currentValue  + (transfer.QuantitySent != null ? transfer.QuantitySent : 0));
                        System.debug('Updated inventoryTransferUpdates #4 == > ' + inventoryTransferUpdates);
                    }
                }
            }
            
            System.debug('productInventoryIds === > ' + productInventoryIds+' && inventoryInwardUpdates == >'+inventoryInwardUpdates+' && inventoryTransferUpdates == >'+inventoryTransferUpdates);
            updateProductInventory(productInventoryIds, inventoryInwardUpdates, inventoryTransferUpdates);
            
        } catch (Exception e) {
            
            System.debug('Error Message ' +e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        
    }
    
    public static void onUpdateProductTransferUpdateInventory(Map<Id, ProductTransfer> newMap, Map<Id, ProductTransfer> oldMap) {
        
        try {
            Set<Id> productInventoryIds = new Set<Id>();
            System.debug('productInventoryIds: ' + productInventoryIds);
            Map<Id, Decimal> inventoryInwardUpdates = new Map<Id, Decimal>();
            System.debug('inventoryInwardUpdates: ' + inventoryInwardUpdates);
            Map<Id, Decimal> inventoryTransferUpdates = new Map<Id, Decimal>();
            System.debug('inventoryTransferUpdates: ' + inventoryTransferUpdates);
            
            for (Id transferId : newMap.keySet()) {
                ProductTransfer newTransfer = newMap.get(transferId);
                ProductTransfer oldTransfer = oldMap.get(transferId);
                System.debug('Processing transferId: ' + transferId + ', newTransfer: ' + newTransfer + ', oldTransfer: ' + oldTransfer);
                
                if (newTransfer.Product_Inventory__c != null) {
                    productInventoryIds.add(newTransfer.Product_Inventory__c);
                    
                    if (newTransfer.RecordTypeId == InwardRecordTypeId) {
                        Decimal oldValue = oldTransfer.QuantityReceived != null ? oldTransfer.QuantityReceived : 0;
                        Decimal newValue = newTransfer.QuantityReceived != null ? newTransfer.QuantityReceived : 0;
                        Decimal currentValue = inventoryInwardUpdates.containsKey(newTransfer.Product_Inventory__c)
                            ? inventoryInwardUpdates.get(newTransfer.Product_Inventory__c)
                            : 0;    
                        System.debug('oldValue: ' + oldValue);
                        System.debug('newValue: ' + newValue);
                        System.debug('Adding to inventoryInwardUpdates: ' + inventoryInwardUpdates);
                        inventoryInwardUpdates.put(newTransfer.Product_Inventory__c, currentValue + (newValue - oldValue));
                        System.debug('Updated inventoryInwardUpdates: ' + inventoryInwardUpdates);
                        
                    } else if (newTransfer.RecordTypeId == TransferRecordTypeId) {
                        Decimal oldValue = oldTransfer.QuantitySent != null ? oldTransfer.QuantitySent : 0;
                        Decimal newValue = newTransfer.QuantitySent != null ? newTransfer.QuantitySent : 0;
                        Decimal currentValue = inventoryTransferUpdates.containsKey(newTransfer.Product_Inventory__c)
                            ? inventoryTransferUpdates.get(newTransfer.Product_Inventory__c)
                            : 0;
                        System.debug('oldValue: ' + oldValue);
                        System.debug('newValue: ' + newValue);
                        System.debug('Adding to inventoryTransferUpdates: ' + inventoryTransferUpdates);
                        inventoryTransferUpdates.put(newTransfer.Product_Inventory__c, currentValue + (newValue - oldValue));
                        System.debug('Updated inventoryTransferUpdates: ' + inventoryTransferUpdates);
                    }
                }
            }
            
            System.debug('Final productInventoryIds: ' + productInventoryIds);
            updateProductInventory(productInventoryIds, inventoryInwardUpdates, inventoryTransferUpdates);
        } catch (Exception e) {
            System.debug('Error Message ' +e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        
    }
    
    public static void onDeleteProductTransferUpdateInventory(List<ProductTransfer> oldTransfers) {
        
        try {
            Set<Id> productInventoryIds = new Set<Id>();
            System.debug('productInventoryIds: ' + productInventoryIds);
            Map<Id, Decimal> inventoryInwardUpdates = new Map<Id, Decimal>();
            System.debug('inventoryInwardUpdates: ' + inventoryInwardUpdates);
            Map<Id, Decimal> inventoryTransferUpdates = new Map<Id, Decimal>();
            System.debug('inventoryTransferUpdates: ' + inventoryTransferUpdates);
            
            
            for (ProductTransfer transfer : oldTransfers) {
                System.debug('Processing transfer: ' + transfer);
                if (transfer.Product_Inventory__c != null) {
                    productInventoryIds.add(transfer.Product_Inventory__c);
                    System.debug('Adding to productInventoryIds: ' + productInventoryIds);
                    
                    if (transfer.RecordTypeId ==InwardRecordTypeId) {
                        Decimal currentValue = inventoryInwardUpdates.containsKey(transfer.Product_Inventory__c)
                            ? inventoryInwardUpdates.get(transfer.Product_Inventory__c)
                            : 0;
                        System.debug('Current values:::::' + currentValue);
                        inventoryInwardUpdates.put(transfer.Product_Inventory__c, currentValue 
                                                   - (transfer.QuantityReceived != null ? transfer.QuantityReceived : 0));
                        System.debug('Updated inventoryInwardUpdates: ' + inventoryInwardUpdates);
                        
                    } else if (transfer.RecordTypeId == TransferRecordTypeId) {
                        Decimal currentValue = inventoryTransferUpdates.containsKey(transfer.Product_Inventory__c)
                            ? inventoryTransferUpdates.get(transfer.Product_Inventory__c)
                            : 0;
                        System.debug('Current values:::::' + currentValue);
                        inventoryTransferUpdates.put(transfer.Product_Inventory__c, currentValue 
                                                     - (transfer.QuantitySent != null ? transfer.QuantitySent : 0));
                        System.debug('Updated inventoryTransferUpdates: ' + inventoryTransferUpdates);
                    }
                }
            }
            
            System.debug('Final productInventoryIds: ' + productInventoryIds);
            updateProductInventory(productInventoryIds, inventoryInwardUpdates, inventoryTransferUpdates);
            
        } catch (Exception e) {
            System.debug('Error Message ' +e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        
    }
    
    private static void updateProductInventory(Set<Id> productInventoryIds, Map<Id, Decimal> inventoryInwardUpdates, Map<Id, Decimal> inventoryTransferUpdates) {
        System.debug('productInventoryIds #12 === > ' + productInventoryIds+' && inventoryInwardUpdates == >'
        +inventoryInwardUpdates+' && inventoryTransferUpdates == >'+inventoryTransferUpdates);
        try {
            if (productInventoryIds.isEmpty()){
                System.debug('No productInventoryIds to process.');
                return;
            } 
            
            List<ProductItem> productInventoryList = [SELECT Id, Inward_Quantity__c, Transfer_Quantity__c FROM ProductItem WHERE Id IN :productInventoryIds];
            System.debug('productInventoryList  ### 1 ' + productInventoryList);
            
            for (ProductItem inventory : productInventoryList) {
                if (inventoryInwardUpdates.containsKey(inventory.Id)) {
                    inventory.Inward_Quantity__c = (inventory.Inward_Quantity__c != null ? inventory.Inward_Quantity__c : 0) 
                        + inventoryInwardUpdates.get(inventory.Id);
                    System.debug('Updated inventory.Id === > && ' + inventory.Id + ', inventory.Inward_Quantity__c == && ' + inventory.Inward_Quantity__c);
                }
                
                if (inventoryTransferUpdates.containsKey(inventory.Id)) {
                    inventory.Transfer_Quantity__c = (inventory.Transfer_Quantity__c != null ? inventory.Transfer_Quantity__c : 0) 
                        + inventoryTransferUpdates.get(inventory.Id);
                    System.debug('Updated inventory.Id &&  === > ' + inventory.Id + ', inventory.Transfer_Quantity__c: && == > ' + inventory.Transfer_Quantity__c);
                }
            }
            
            if (!productInventoryList.isEmpty()) {
                update productInventoryList;
                System.debug('productInventoryList === >'+productInventoryList);
            }
            
        } catch (Exception e) {
            System.debug('Error Message ' +e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    public static void handleDailyLedgerCreationOrUpdate(List<ProductTransfer> transfers) {
        
        try {
            System.debug('Starting handleDailyLedgerCreationOrUpdate with transfers: ' + transfers);
            
            // Prepare a map to fetch existing ledgers by Product, Location, and Date
            Set<Id> locationIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<Date> transferDates = new Set<Date>();
            
            for (ProductTransfer transfer : transfers) {
                if (transfer.DestinationLocationId != null && transfer.Product2Id != null) {
                    locationIds.add(transfer.DestinationLocationId);
                    productIds.add(transfer.Product2Id);
                    transferDates.add(transfer.CreatedDate.date());
                }
            }
            
            System.debug('Location IDs: ' + locationIds);
            System.debug('Product IDs: ' + productIds);
            System.debug('Transfer Dates: ' + transferDates);
            
            // Fetch existing Daily Ledgers
            Map<String, Daily_Ledger__c> existingLedgerMap = new Map<String, Daily_Ledger__c>();
            for (Daily_Ledger__c ledger : [
                SELECT Id, Ledger_Date__c, Product__c, Intake_Quantity__c, Transfer_Quantity__c, 
                Destination_Location__c
                FROM Daily_Ledger__c
                WHERE Ledger_Date__c IN :transferDates
                AND Destination_Location__c IN :locationIds
                AND Product__c IN :productIds
            ]) {
                // Key: Date + LocationId + ProductId
                String key = ledger.Ledger_Date__c + '-' + ledger.Destination_Location__c + '-' + ledger.Product__c;
                System.debug('Found existing ledger with key: ' + key);
                existingLedgerMap.put(key, ledger);
            }
            
            List<Daily_Ledger__c> ledgersToInsert = new List<Daily_Ledger__c>();
            List<Daily_Ledger__c> ledgersToUpdate = new List<Daily_Ledger__c>();
            
            Map<Id, Id> productTransferToLedgerMap = new Map<Id, Id>();
            System.debug('existingLedgerMap: ' + existingLedgerMap);
            System.debug('ProductTransfertoledfg' + productTransferToLedgerMap );
            
            // Prepare new ledgers and map product transfers to ledgers
            for (ProductTransfer transfer : transfers) {
                if (transfer.DestinationLocationId == null || transfer.Product2Id == null) continue;
                
                // Generate key based on Date, Location, and Product
                Date transferDate = transfer.CreatedDate.date();
                String key = transferDate + '-' + transfer.DestinationLocationId + '-' + transfer.Product2Id;
                Id sourceLocation = System.Label.Default_River_Warehouse;
                
                Daily_Ledger__c ledger = existingLedgerMap.get(key);
                if (ledger == null) {
                    // Create new ledger if no existing record matches the key
                    ledger = new Daily_Ledger__c();
                    ledger.Ledger_Date__c = transferDate;
                    ledger.Destination_Location__c = transfer.DestinationLocationId;
                    ledger.Product__c = transfer.Product2Id;
                    ledger.Source_Location__c = sourceLocation;
                    
                    // Set quantities for new ledger
                    if (transfer.RecordTypeId == InwardRecordTypeId) {
                        ledger.Intake_Quantity__c = transfer.QuantityReceived != null ? transfer.QuantityReceived : 0;
                    } else if (transfer.RecordTypeId == TransferRecordTypeId) {
                        ledger.Transfer_Quantity__c = transfer.QuantitySent != null ? transfer.QuantitySent : 0;
                    }
                    
                    ledgersToInsert.add(ledger); // Add new ledger to insert list
                } else {
                    // Update existing ledger quantities
                    if (transfer.RecordTypeId == InwardRecordTypeId) {
                        ledger.Intake_Quantity__c = 
                            (ledger.Intake_Quantity__c != null ? ledger.Intake_Quantity__c : 0) 
                            + (transfer.QuantityReceived != null ? transfer.QuantityReceived : 0);
                    } else if (transfer.RecordTypeId == TransferRecordTypeId) {
                        ledger.Transfer_Quantity__c = 
                            (ledger.Transfer_Quantity__c != null ? ledger.Transfer_Quantity__c : 0) 
                            + (transfer.QuantitySent != null ? transfer.QuantitySent : 0);
                    }
                    
                    // Add ledger to the update list for persisting changes
                    ledgersToUpdate.add(ledger);
                }
                
            }
            
            if (!ledgersToInsert.isEmpty()) {
                insert ledgersToInsert;
                
                // Update the map with newly created ledger IDs
                for (Daily_Ledger__c insertedLedger : ledgersToInsert) {
                    System.debug('Inserted ledger: ' + insertedLedger);
                    String key = insertedLedger.Ledger_Date__c + '-' + 
                        insertedLedger.Destination_Location__c + '-' + insertedLedger.Product__c;
                    existingLedgerMap.put(key, insertedLedger);
                    
                }
            }
            
            // Map ProductTransfers to DailyLedgers (new and updated)
            for (ProductTransfer transfer : transfers) {
                Date transferDate = transfer.CreatedDate.date();
                String key = transferDate + '-' + transfer.DestinationLocationId + '-' + transfer.Product2Id;
                System.debug('Searching for ledger with key: ' + key);
                
                if (existingLedgerMap.containsKey(key)) {
                    Daily_Ledger__c matchingLedger = existingLedgerMap.get(key);
                    productTransferToLedgerMap.put(transfer.Id, matchingLedger.Id); // Tag the ProductTransfer with the ledger
                    
                    System.debug('Matched ledger: ' + matchingLedger);
                }
            }
            
            if (!ledgersToUpdate.isEmpty()) {
                System.debug('Updating ledgers: ' + ledgersToUpdate);
                update ledgersToUpdate;
            }
            
            // Prepare ProductTransfer records for update
            List<ProductTransfer> transfersToUpdate = new List<ProductTransfer>();
            for (ProductTransfer transfer : transfers) {
                if (productTransferToLedgerMap.containsKey(transfer.Id)) {
                    ProductTransfer updatedTransfer = new ProductTransfer(
                        Id = transfer.Id,
                        Daily_Ledger__c = productTransferToLedgerMap.get(transfer.Id)
                    );
                    System.debug('Updating ProductTransfer: ' + updatedTransfer);
                    transfersToUpdate.add(updatedTransfer);
                    
                }
            }
            
            if (!transfersToUpdate.isEmpty()) {
                update transfersToUpdate; // Perform the update
            }
        }
        catch (Exception e) {
            System.debug('Error Message ' +e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
        
    }
    
}