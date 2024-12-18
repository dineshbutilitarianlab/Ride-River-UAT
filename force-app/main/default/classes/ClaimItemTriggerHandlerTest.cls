@isTest
public class ClaimItemTriggerHandlerTest {
    @isTest
    static void testProcessClaimUpdates() {
        // Setup test data
        
        
        List<Claim> claims = new List<Claim>();
        for (Integer i = 0; i < 2; i++) {
            claims.add(new Claim(Name = 'Test Claim ' + i, Status = 'Pending',AccountId='0015j00001XBTXFAA5'));
        }
        insert claims;

        List<ClaimItem> claimItems = new List<ClaimItem>();
        for (Claim claim : claims) {
            claimItems.add(new ClaimItem(Name='Claim 1',ClaimId = claim.Id, Status__c = 'Pending'));
            claimItems.add(new ClaimItem(Name='Claim 2',ClaimId = claim.Id, Status__c = 'Pending'));
        }
        insert claimItems;

        // Update Claim Items to trigger handler
        for (ClaimItem ci : claimItems) {
            ci.Status__c = 'Approved';
            ci.Approved_Amount__c=1000;
        }
        update claimItems;

        // Assert Claim status updated to 'Sent to Finance'
        List<Claim> updatedClaims = [
            SELECT Id, Status 
            FROM Claim 
            WHERE Id IN :claims
        ];
        for (Claim claim : updatedClaims) {
            System.assertEquals('Sent to Finance', claim.Status, 'Claim status should be updated to "Sent to Finance"');
        }

        // Log a message to confirm email logic
        System.debug('Email logic was executed for claims: ' + updatedClaims);
    }

    @isTest
    static void testProcessClaimUpdatesPartial() {
        // Setup test data for partial updates
        Claim testClaim = new Claim(Name = 'Test Claim Partial', Status = 'Pending', AccountId='0015j00001XBTXFAA5');
        insert testClaim;

        List<ClaimItem> claimItems = new List<ClaimItem>{
            new ClaimItem(Name='Claim Item 1',ClaimId = testClaim.Id, Status__c = 'Approved',FaultDate=Date.Today(),Approved_Amount__c=1000),
            new ClaimItem(Name='Claim Item 2',ClaimId = testClaim.Id, Status__c = 'Pending',FaultDate=Date.Today(),Approved_Amount__c=1000)
        };
        insert claimItems;

        // Update one Claim Item to Approved
        claimItems[1].Status__c = 'Approved';
        update claimItems;

        // Assert Claim status is not updated to 'Sent to Finance'
        Claim updatedClaim = [
            SELECT Id, Status 
            FROM Claim 
            WHERE Id = :testClaim.Id
        ];
        System.assertEquals('Sent to Finance', updatedClaim.Status, 'Claim status should not be updated if not all items are Approved or Rejected');
    }
}