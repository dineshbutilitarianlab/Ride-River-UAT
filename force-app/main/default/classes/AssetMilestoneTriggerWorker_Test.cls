@isTest
public class AssetMilestoneTriggerWorker_Test {
    @isTest
    static void testcreatePDIItems() {
        Account acc = new Account();
        acc.Name = 'testing Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'testing Contact';
        con.AccountId = acc.Id;
        con.Phone = '9123456789';
        con.Email = 'test@test.com';
        con.Primary_Contact__c = true;
        insert con;
        
        Asset asst = new Asset();
        asst.Name = 'test Asset';
        asst.AccountId = acc.Id;
        asst.ContactId = con.Id;
        insert asst;
        
        Software_Version__c sv = new Software_Version__c();
        sv.Name = 'test version';
        sv.Latest_Software_Version__c = true;
        insert sv;
        
        Product2 prod = new Product2();
        prod.Name = 'test product';
        prod.HSN_Code__c = '123';
        prod.Type__c = 'Vehicle';
        insert prod;
        
        VehicleDefinition vd = new VehicleDefinition();
        vd.Name = 'test VehicleDefinition';
        vd.ProductId = prod.Id;
        insert vd;
        
        Vehicle vac = new Vehicle();
        vac.Name = 'test vehicle';
        vac.CurrentOwnerId = acc.Id;
        vac.Charger_PC_Number__c = '123CC';
        vac.VehicleRegistrationNumber = '123';
        vac.VehicleIdentificationNumber = 'NeoCity2022ZXi';
        vac.VehicleDefinitionId = vd.Id;
        vac.Software_Version__c = sv.Id;
        vac.AssetId = asst.Id;
        insert vac; 
        
        Pre_Delivery_Inspection__c pdi = new Pre_Delivery_Inspection__c();
        pdi.Parameter__c = 'Test Parameter';
        pdi.Description__c = 'Test Description';
        pdi.Attribute__c = 'Documentation/ Hardware verification';
        insert pdi;
        
        try{
            AssetMilestone milestone1 = new AssetMilestone();
            milestone1.Name = 'Test Milestone';
            milestone1.AssetId = asst.Id;
            milestone1.UsageType = 'Automotive';
            milestone1.MilestoneDate = System.today();
            milestone1.MilestoneType = 'Order Received';
            milestone1.Stage = 'Active';
            milestone1.VehicleId = vac.Id;
            insert milestone1;
            
            AssetMilestone milestone2 = new AssetMilestone();
            milestone2.Name = 'Test Milestone';
            milestone2.AssetId = asst.Id;
            milestone2.UsageType = 'Automotive';
            milestone2.MilestoneDate = System.today();
            milestone2.MilestoneType = 'Manufactured';
            milestone2.Stage = 'Active';
            milestone2.VehicleId = vac.Id;
            insert milestone2;
            
            AssetMilestone milestone3 = new AssetMilestone();
            milestone3.Name = 'Test Milestone';
            milestone3.AssetId = asst.Id;
            milestone3.UsageType = 'Automotive';
            milestone3.MilestoneDate = System.today();
            milestone3.MilestoneType = 'Delivered';
            milestone3.Stage = 'Active';
            milestone3.VehicleId = vac.Id;
            insert milestone3;
             
            AssetMilestone milestone4 = new AssetMilestone();
            milestone4.Name = 'Test Milestone';
            milestone4.AssetId = asst.Id;
            milestone4.UsageType = 'Automotive';
            milestone4.MilestoneDate = System.today();
            milestone4.MilestoneType = 'PDI';
            milestone4.Stage = 'Active';
            milestone4.VehicleId = vac.Id;
            insert milestone4;
            
            Vehicle vac1 = new Vehicle(
                Id = vac.Id,
                PDI_Status_Pass__c = true
            );
            
            update vac1;
    
            AssetMilestone milestone5 = new AssetMilestone();
            milestone5.Name = 'Test Milestone';
            milestone5.AssetId = asst.Id;
            milestone5.UsageType = 'Automotive';
            milestone5.MilestoneDate = System.today();
            milestone5.MilestoneType = 'Sold';
            milestone5.Stage = 'Active';
            milestone5.VehicleId = vac.Id;
            insert milestone5;
            
            AssetMilestone milestone6 = new AssetMilestone();
            milestone6.Name = 'Test Milestone';
            milestone6.AssetId = asst.Id;
            milestone6.UsageType = 'Automotive';
            milestone6.MilestoneDate = System.today();
            milestone6.MilestoneType = 'Customer Delivery';
            milestone6.Stage = 'Active';
            milestone6.VehicleId = vac.Id;
            insert milestone6;
        
            delete milestone4; 
        }
        catch(Exception e){
            
        }
        
        
    }
}