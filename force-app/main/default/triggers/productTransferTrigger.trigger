// trigger productTransferTrigger on ProductTransfer (before insert,after insert,after update, before update) {
//     if(Trigger.isAfter && Trigger.isInsert){
//         //productTransferTriggerHandler.rollUpOnDailyLedger(Trigger.new);
//         //productTransferTriggerHandler.createDailyLedger(Trigger.new);
//     }
//     if(Trigger.isAfter && Trigger.isUpdate){
//         // productTransferTriggerHandler.rollUpOnDailyLedger(Trigger.new);
//         // productTransferTriggerHandler.createDailyLedger(Trigger.new);
//     }
// }

trigger productTransferTrigger on ProductTransfer (after insert, before update, after delete) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        ProductTransferHandler.onInsertProductTransferUpdateInventory(Trigger.new);
        ProductTransferHandler.handleDailyLedgerCreationOrUpdate(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        ProductTransferHandler.onUpdateProductTransferUpdateInventory(Trigger.newMap, Trigger.oldMap);

    }

    if (Trigger.isAfter && Trigger.isDelete) {
        ProductTransferHandler.onDeleteProductTransferUpdateInventory(Trigger.old);
    }
}