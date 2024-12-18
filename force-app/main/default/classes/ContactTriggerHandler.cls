public class ContactTriggerHandler {
    public static void validatePrimaryContact(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> currenctConIds = new Set<Id>();
        Map<Id, Integer> accountContactCountMap = new Map<Id, Integer>();

        for (Contact con : contacts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
            if(con.Id != null){
                currenctConIds.add(con.Id);
            }
        }

        if (!accountIds.isEmpty()) {
            List<AggregateResult> results = [
                SELECT AccountId, COUNT(Id) contactCount
                FROM Contact
                WHERE AccountId IN :accountIds AND ID Not IN :currenctConIds
                GROUP BY AccountId
            ];

            for (AggregateResult ar : results) {
                accountContactCountMap.put((Id)ar.get('AccountId'), (Integer)ar.get('contactCount'));
            }
        }

        for (Contact con : contacts) {
            Integer contactCount = accountContactCountMap.get(con.AccountId);

            // If it's a new contact and no other contacts exist, or if it's being updated
            if (contactCount == null || contactCount == 0) {
                contactCount = 0; // Initialize to 0 if there are no existing contacts
            }

            if (contactCount == 0 && (con.Primary_Contact__c == null || !con.Primary_Contact__c)) {
                con.Primary_Contact__c = true;
                // con.Primary_Contact__c.addError('The Primary Contact checkbox must be checked for the first contact of an account.');
            }
        }
    }
}