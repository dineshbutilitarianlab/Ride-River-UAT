trigger CaseTrigger on Case (before insert, before Update) {
     for (Case c : Trigger.new) {
        if (c.Origin == 'Email') { // Ensure 'Email' matches your Case Origin value
            c.Case_Type__c = 'General Query'; // Set the Case Type
           
            system.debug(c);
        }
    }
}