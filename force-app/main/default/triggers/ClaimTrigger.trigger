trigger ClaimTrigger on Claim (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ClaimTriggerHandler.handleAfterInsert(Trigger.new);
    }

  
}