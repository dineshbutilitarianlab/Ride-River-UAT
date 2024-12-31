public with sharing class WarrantyTagPDFController {
    public ClaimItem claimItem { get; private set; }
    public String    warrantyClaimNumber { get; private set; }
    public Date      warrantyDate { get; private set; }
    public String   motorNumber { get; private set; }
    public String   vin { get; private set; }
    public String   registrationNumber { get; private set; }
    public Decimal  vehicleKilometer { get; private set; }
    public String   dealerName {get; set;}
    public String   modelName {get;set;}
    public Date     purchaseDate {get;set;}
    public String   partNumber {get;set;}
    public String   partDescription {get;set;}
    public String   dealerLocation {get;set;}
    public String   warrantyClaim {get;set;}
    public String   ElectricalValue {get;set;}
    public String   ConsequentialParts {get;set;}
    public String   dealerObs {get;set;}
    public Decimal   VehicleKMS {get;set;}
    public Decimal   failureQty {get;set;}
    public DateTime   DOF {get;set;}

    public WarrantyTagPDFController() {
        System.debug('Initializing WarrantyTagPDFController...');
        String claimItemId = ApexPages.currentPage().getParameters().get('cid');
        System.debug('Claim Item ID: ' + claimItemId);

        if (claimItemId != null) {
            try {
                System.debug('Fetching ClaimItem record...');
                claimItem = [
                    SELECT Id, Name, 
                    Claim.Warranty_Prior__c,
                    Claim.AccountId,Failure_Quantity__c,
                    Claim.Account.Name,
                    Claim.Account.AccountNumber,
                    Claim.Account.ShippingCountry,
                    Claim.Account.ShippingStreet,
                    Claim.Account.ShippingCity,
                    Claim.Account.ShippingState,
                    Claim.Account.ShippingPostalCode,
                    Claim.Warranty_Prior__r.Name, 
                    Claim.Warranty_Prior__r.Warranty_Prior_Date__c, 
                    Claim.Warranty_Prior__r.Odometer_Reading__c,
                    Claim.Job_Card__r.CreatedDate,
                    Claim.Job_Card__r.Dealer_Observation__c,
                    Part_Description__c,
                    Electrical_Value__c,
                    Quantity__c,
                    Claim.Vehicle__r.Dealer__r.Name,
                    Claim.Vehicle__r.ModelName,
                    Claim.Vehicle__r.LastOdometerReading,
                    Claim.Vehicle__r.Purchased_Date__c,
                    Claim.Vehicle__r.VehicleIdentificationNumber,
                    Claim.Vehicle__r.EngineNumber,
                    Claim.Vehicle__r.VehicleRegistrationNumber,

                    // Vehicle.Dealer__r.Name,
                    // Vehicle.ModelName,
                    // Vehicle.LastOdometerReading,
                    // Vehicle.Purchased_Date__c,
                    // Vehicle.VehicleIdentificationNumber,
                    // Vehicle.EngineNumber,
                    Consequential_Part__c,
                    // Vehicle.VehicleRegistrationNumber,
                    Part__r.LineItemNumber,
                    Part__r.Description
                    FROM ClaimItem
                    WHERE Id = :claimItemId
                    LIMIT 1
                ];
                System.debug('Fetched ClaimItem record: ' + claimItem);
                
                warrantyClaimNumber = claimItem.Claim.Warranty_Prior__r.Name;
                System.debug('Warranty Claim Number: ' + warrantyClaimNumber);
                
                warrantyDate = claimItem.Claim.Warranty_Prior__r.Warranty_Prior_Date__c;
                System.debug('Warranty Date: ' + warrantyDate);
                
                motorNumber = claimItem.Claim.Vehicle__r.EngineNumber;
                System.debug('Motor Number: ' + motorNumber);
                
                vin = claimItem.Claim.Vehicle__r.VehicleIdentificationNumber;
                System.debug('VIN: ' + vin);
                
                registrationNumber = claimItem.Claim.Vehicle__r.VehicleRegistrationNumber;
                System.debug('Registration Number: ' + registrationNumber);
                
                vehicleKilometer = claimItem.Claim.Vehicle__r.LastOdometerReading;
                System.debug('Vehicle Kilometer: ' + vehicleKilometer);
                
               dealerName = claimItem.Claim.Vehicle__r.Dealer__r.Name;
               System.debug('Dealer Name: ' + dealerName);
                
               modelName = claimItem.Claim.Vehicle__r.ModelName;
               System.debug('Model Name: ' + modelName);
                
                purchaseDate = claimItem.Claim.Vehicle__r.Purchased_Date__c;
                System.debug('Purchase Date: ' + purchaseDate);
                
                partNumber = claimItem.Part__r.LineItemNumber;
                System.debug('Part Number: ' + partNumber);
                
                partDescription = claimItem.Part_Description__c;
                System.debug('Part Description: ' + partDescription);
                
                dealerLocation = claimItem.Claim.Account.ShippingCity;
                System.debug('Dealer Location: ' + dealerLocation);
                
                warrantyClaim = claimItem.Name;
                System.debug('Warranty Claim: ' + warrantyClaim);
                
                ConsequentialParts = claimItem.Consequential_Part__c;
                System.debug('Consequential Parts: ' + ConsequentialParts);
                
                ElectricalValue = claimItem.Electrical_Value__c;
                System.debug('Electrical Value: ' + ElectricalValue);
                
                failureQty = claimItem.Quantity__c;
                System.debug('Failure Quantity: ' + failureQty);
                
                dealerObs = claimItem.Claim.Job_Card__r.Dealer_Observation__c;
                System.debug('Dealer Observation: ' + dealerObs);
                
                DOF = claimItem.Claim.Job_Card__r.CreatedDate;
                System.debug('Date of Failure (DOF): ' + DOF);

            } catch (Exception ex) {
                System.debug('Error fetching Claim Item:  ' + ex.getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error fetching Claim Item: ' + ex.getMessage()));
            } 
        } else {
            System.debug('No Claim Item found.');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Claim Item found.'));
        }
    }
}