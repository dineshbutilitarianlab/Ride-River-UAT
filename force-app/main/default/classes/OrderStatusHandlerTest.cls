@isTest
public class OrderStatusHandlerTest {
    
    @isTest
    static void testUpdateVehicle() {
        // Create sample Order and Vehicle records
        
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', Email__c = 'test@gmail.com');
        insert acc;
        
        Account dealerAccount = new Account(Name = 'Test Name',Type = 'Dealer',Phone='9011113248', Email__c = 'dealer@test.com' );
        dealerAccount.Account_Number__c = '47723745723457';
        dealerAccount.Bank_Name__c = 'Canara';
        dealerAccount.Center_Code__c = 'BR';
        dealerAccount.Invoice_Sequence__c = 0;
        insert dealerAccount;
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        
        Order order = new Order(
            AccountId = acc.Id,
            Dealer__c = dealerAccount.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId()
            
        );
        Insert order;
        
        List<Order_Invoice__c> invoiceList = new List<Order_Invoice__c>();
        Order_Invoice__c invoice = new Order_Invoice__c();
        invoice.Name = 'Vehicle Invoice';
        invoice.Invoice_Number__c = 'ERTYU5678';
        invoice.Invoice_Type__c = 'Vehicle Invoice';
        invoice.Order__c = order.Id;  
        
        invoiceList.add(invoice);
        
        Order_Invoice__c invoice1 = new Order_Invoice__c();
        invoice1.Name = 'Other Charges Invoice';
        invoice1.Invoice_Number__c = 'ERTYU5679';
        invoice1.Invoice_Type__c = 'Other Charges Invoice';
        invoice1.Order__c = order.Id;  
        invoiceList.add(invoice1);
        
        Order_Invoice__c invoice2 = new Order_Invoice__c();
        invoice2.Name = 'Accessories Invoice';
        invoice2.Invoice_Number__c = 'ERTYU5879';
        invoice2.Invoice_Type__c = 'Accessories Invoice';
        invoice2.Order__c = order.Id;  
        invoiceList.add(invoice2);
        
        Insert invoiceList;
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 3'
        );
        insert p1;
        
        
        PricebookEntry newPricebookEntry = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        insert newPricebookEntry;
        
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = newPricebookEntry.Id,
            Product2Id = p1.Id,
            Quantity = 1, 
            UnitPrice = 100,
            Type__c = 'Vehicle'
        );
        
        Insert orderItem; 
        
        VehicleDefinition v1 = new VehicleDefinition(
            Name = 'someName',
            ProductId = p1.Id
        );
        insert v1;
        
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BR23456',
            PDI_Status_Pass__c = TRUE,
            Software_Version__c = sft.Id
        );
        insert vehicle;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        Payment__c payment = new Payment__c(
            Amount__c = o1.Grand_Total__c,           
            Payment_Status__c = 'Success',
            Mode_Of_Payment__c = 'Credit Card',
            Transaction_Id__c = 'payment1'
        );
        insert payment;
        
        // Create related Order Payment records for the test Payments
        
        Order_Payment__c op = new Order_Payment__c(
            Payments__c = payment.Id,
            Order__c = order.Id,
            Type__c = 'Down Payment'
        );
        
        insert op;
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        
        //Assign the Vehicle
        order order2 = new Order(); 
        order2.Id = order.Id;
        order2.Assigned_Vehicle__c = vehicle.Id;
        order2.Status ='Vehicle Delivered';
        update order2;
        
        
        AssetMilestone milestone = new AssetMilestone();
        milestone.Delivery_Date__c = System.today();
        milestone.MilestoneType = 'PDI';
        milestone.VehicleId = vehicle.Id;
        milestone.MilestoneDate = System.today();
        milestone.AssetId = a1.Id;
        milestone.Name = 'Vehicle Sold';
        milestone.UsageType = 'Automotive';
        milestone.Stage = 'Active';
        Insert milestone;
         /*try{
 Insert milestone;
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }*/

       
        
        /* AssetMilestone milestone4 = new AssetMilestone();
milestone4.Delivery_Date__c = System.today();
milestone4.MilestoneType = 'Sold';
milestone4.VehicleId = vehicle.Id;
milestone4.MilestoneDate = System.today();
milestone4.AssetId = a1.Id;
milestone4.Name = 'Vehicle Sold';
milestone4.UsageType = 'Automotive';
milestone4.Stage = 'Active';

Insert milestone4;

AssetMilestone milestone1 = new AssetMilestone();
milestone1.Delivery_Date__c = System.today();
milestone1.MilestoneType = 'Customer Delivery';
milestone1.VehicleId = vehicle.Id;
milestone1.MilestoneDate = System.today();
milestone1.AssetId = a1.Id;
milestone1.Name = 'Vehicle Sold';
milestone1.UsageType = 'Automotive';
milestone1.Stage = 'Active';

Insert milestone1;*/
        
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Days',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;
        
        // Update the order status to 'Vehicle Delivered'
        //order.Status = 'Vehicle Delivered';
        //order.Warranty_Term__c = warrantyTerm.Id;
        //update order;
        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        Test.startTest(); 
       OrderStatusHandler.updateVehicle(testNewOrderList, oldMap);
        Test.stopTest();
        
        // Verify that Vehicle records were updated correctly
        Vehicle updatedVehicle = [SELECT Finance__c,Software_Version__c, Insurance__c, Loan_Start_Date__c, Approval_Status__c, Financed_Amount__c, EMI_Amount__c, Tenure__c, Tenure_Type__c
                                  FROM Vehicle WHERE Id = :vehicle.Id];
        System.assertEquals(order.Finance__c, updatedVehicle.Finance__c, 'Finance__c should be updated');
        System.assertEquals(order.Insurance__c, updatedVehicle.Insurance__c, 'Insurance__c should be updated');
        // Add similar assertions for other fields
    }
    
    @isTest
    static void testUpdateVehicle01() {
        
        // Create sample Order and Vehicle records
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', Email__c = 'test@gmail.com');
        insert acc;
        
        Account dealerAccount = new Account(Name = 'Test Name',Type = 'Dealer',Phone='9011113248', Email__c = 'dealer@test.com' );
        dealerAccount.Account_Number__c = '47723745723457';
        dealerAccount.Bank_Name__c = 'Canara';
        dealerAccount.Center_Code__c = 'BR';
        dealerAccount.Invoice_Sequence__c = 0;
        insert dealerAccount;
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        Order order = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId()
            
        );
        Insert order;
        
        
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 2'
        );
        insert p1;
        
        
        PricebookEntry newPricebookEntry = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        insert newPricebookEntry;
        
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = newPricebookEntry.Id,
            Product2Id = p1.Id,
            Quantity = 1, 
            UnitPrice = 100,
            Type__c = 'Vehicle'
        );
        
        Insert orderItem; 
        
        VehicleDefinition v1 = new VehicleDefinition(
            Name = 'someName',
            ProductId = p1.Id
        );
        insert v1;
        
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BR23456',
            PDI_Status_Pass__c = TRUE,
            Software_Version__c = sft.Id
        );
        insert vehicle;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Days',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;
        
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        
        //Assign the Vehicle
        order order2 = new Order(); 
        order2.Id = order.Id;
        order2.Assigned_Vehicle__c = vehicle.Id;
        Update order2;
        
        order2.Status ='Vehicle Delivered';
        order2.Warranty_Term__c = warrantyTerm.Id;
        
        
        AssetMilestone milestone = new AssetMilestone();
        milestone.Delivery_Date__c = System.today();
        milestone.MilestoneType = 'PDI';
        milestone.VehicleId = vehicle.Id;
        milestone.MilestoneDate = System.today();
        milestone.AssetId = a1.Id;
        milestone.Name = 'Vehicle Sold';
        milestone.UsageType = 'Automotive';
        milestone.Stage = 'Active';
        
        Insert milestone;
        
        /*AssetMilestone milestone4 = new AssetMilestone();
        milestone4.Delivery_Date__c = System.today();
        milestone4.MilestoneType = 'Sold';
        milestone4.VehicleId = vehicle.Id;
        milestone4.MilestoneDate = System.today();
        milestone4.AssetId = a1.Id;
        milestone4.Name = 'Vehicle Sold';
        milestone4.UsageType = 'Automotive';
        milestone4.Stage = 'Active';
        
        Update milestone4;
        
        AssetMilestone milestone1 = new AssetMilestone();
        milestone1.Delivery_Date__c = System.today();
        milestone1.MilestoneType = 'Customer Delivery';
        milestone1.VehicleId = vehicle.Id;
        milestone1.MilestoneDate = System.today();
        milestone1.AssetId = a1.Id;
        milestone1.Name = 'Vehicle Sold';
        milestone1.UsageType = 'Automotive';
        milestone1.Stage = 'Active';
        
        Update milestone1; 
        
        /*AssetMilestone ast = [SELECT Id,MilestoneType FROM AssetMilestone WHERE Id =:milestone.Id];
        ast.MilestoneType ='Sold';
        Update ast;
        
        ast.MilestoneType ='Customer Delivery';
        Update ast;*/

        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        
        Test.startTest();
        OrderStatusHandler.UpdateVehicle01(testNewOrderList, oldMap);
        
        WarrantyTerm warrantyTerm1 = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Weeks',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm1;
        
        testNewOrderList[0].Warranty_Term__c = warrantyTerm1.Id;
        
        OrderStatusHandler.UpdateVehicle01(testNewOrderList, oldMap);
        
        WarrantyTerm warrantyTerm2 = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 1,
            WarrantyUnitOfTime = 'Years',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm2;
        
        testNewOrderList[0].Warranty_Term__c = warrantyTerm2.Id;
        
        OrderStatusHandler.UpdateVehicle01(testNewOrderList, oldMap);
        
        WarrantyTerm warrantyTerm3 = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 2,
            WarrantyUnitOfTime = 'Months',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm3;
        
        testNewOrderList[0].Warranty_Term__c = warrantyTerm3.Id;
        
        OrderStatusHandler.UpdateVehicle01(testNewOrderList, oldMap);
        
        Test.stopTest();
        
        // Verify that AssetWarranty records were inserted
        List<AssetWarranty> insertedWarranties = [SELECT Id FROM AssetWarranty];
        System.assertEquals(4, insertedWarranties.size(), 'AssetWarranty records should be inserted');
    }
    
    
    @isTest
    static void testEmailHandllerMethod() {
        // Create sample Order and Vehicle records
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', email__c='emailtest@gmail.com' );
        insert acc;
        
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        Order order = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId()
            
        );
        Insert order;
        
        
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 1'
            
        );
        insert p1;
        
        
        PricebookEntry newPricebookEntry = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        insert newPricebookEntry;
        
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = newPricebookEntry.Id,
            Product2Id = p1.Id,
            Quantity = 1, 
            UnitPrice = 100,
            Type__c = 'Vehicle'
        );
        
        Insert orderItem; 
        
        VehicleDefinition v1 = new VehicleDefinition(
            Name = 'someName',
            ProductId = p1.Id
        );
        insert v1;
        
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        
         insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BTR4568',
            Software_Version__c = sft.id
        );
        insert vehicle;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Days',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;        
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        Order1.Eligible_For_Subsidy__c = true;
        
        //Assign the Vehicle
        order order2 = new Order(); 
        order2.Id = order.Id;
        order2.Assigned_Vehicle__c = vehicle.Id;
        order2.Status ='Vehicle Delivered';
        order2.Warranty_Term__c = warrantyTerm.Id; 
        order2.Eligible_For_Subsidy__c = false;
        order2.AccountId = acc.Id;
        
        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        
        Test.startTest();
        OrderStatusHandler.emailHandllerMethod(testNewOrderList, oldMap);
        Test.stopTest();
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, sentEmails.size(), 'Emails should be sent');
    }
    
    @isTest
    static void testSendReceipt() {
        // Create sample Order and Vehicle records
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', Email__c = 'test@gmail.com');
        insert acc;
        
        Account dealerAccount = new Account(Name = 'Test Name',Type = 'Dealer',Phone='9011113286', Email__c = 'dealer@test.com' );
        dealerAccount.Account_Number__c = '47723745723457';
        dealerAccount.Bank_Name__c = 'Canara';
        dealerAccount.Center_Code__c = 'BR';
        dealerAccount.Invoice_Sequence__c = 0;
        insert dealerAccount;
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        Order order = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id
            
        );
        Insert order;
        
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 5'
        );
        
        Product2 p2 = new Product2(
            Name = 'someName1',
            HSN_Code__c='Testt1',
            Type__c = 'Accessories',
            IsActive = true,
            ProductCode = 'code 4'
        );
        
        Insert new list<Product2>{p1,p2};
            
            PricebookEntry newPricebookEntry = new PricebookEntry(
                Pricebook2Id = test.getStandardPricebookId(),
                Product2Id = p1.Id,
                UnitPrice = 100,
                IsActive = true // You can set other fields as needed
            );
        
        PricebookEntry newPricebookEntry1 = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p2.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        
        Insert new List<PricebookEntry>{newPricebookEntry1,newPricebookEntry};
            
            //List<orderItem> opList = new 
            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = newPricebookEntry.Id,
                Product2Id = p1.Id,
                Quantity = 1, 
                UnitPrice = 100,
                Type__c = 'Vehicle'
            );
        
        OrderItem orderItem1 = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = newPricebookEntry1.Id,
            Product2Id = p2.Id,
            Quantity = 1, 
            UnitPrice = 100,
            Type__c = 'Accessories'
        );
        
        Insert new List<orderItem>{orderItem1,orderItem};
            
            VehicleDefinition v1 = new VehicleDefinition(
                Name = 'someName',
                ProductId = p1.Id
            );
        insert v1;
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BR23456',
            Software_Version__c = sft.Id
        );
        insert vehicle;
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        
        //Assign the Vehicle
        order order2 = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Pre Invoice',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id,
            Id = order.Id,
            Assigned_Vehicle__c = vehicle.Id            
        ); 
        
        //update order;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        Payment__c payment = new Payment__c(
            Amount__c = o1.Grand_Total__c,           
            Payment_Status__c = 'Success',
            Mode_Of_Payment__c = 'Credit Card',
            Transaction_Id__c = 'payment2'
        );
        insert payment;
        
        // Create related Order Payment records for the test Payments
        
        Order_Payment__c op = new Order_Payment__c(
            Payments__c = payment.Id,
            Order__c = order.Id,
            Type__c = 'Down Payment'
        );
        
        insert op;
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Days',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;
        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        Test.startTest();
        OrderStatusHandler.ceateInvoiceRecords(testNewOrderList, oldMap);
        
        order2.status = 'RTO Registration';
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.generateIvoicesAndReceipts(testNewOrderList, oldMap);
        
        oldMap.get(order.Id).Status = 'RTO Registration';
        order2.status = 'Activated';
        
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.sendPreOrderReceipt(testNewOrderList, oldMap);
        
        OrderStatusHandler.sendPreOrderReceipt01(new List<Order_Payment__c>{op});
        
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testcreateInvoicesTest() {
        
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', Email__c = 'test@gmail.com');
        insert acc;
        
        Account dealerAccount = new Account(Name = 'Test Name',Type = 'Dealer',Phone='9011113286', Email__c = 'dealer@test.com' );
        dealerAccount.Account_Number__c = '47723745723457';
        dealerAccount.Bank_Name__c = 'Canara';
        dealerAccount.Center_Code__c = 'BR';
        dealerAccount.Invoice_Sequence__c = 0;
        insert dealerAccount;
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        Order order = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id
            
        );
        Insert order;
        
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 7'
        );
        
        Product2 p2 = new Product2(
            Name = 'someName1',
            HSN_Code__c='Testt1',
            Type__c = 'Accessories',
            IsActive = true,
            ProductCode = 'code 6'
        );
        
        Insert new list<Product2>{p1,p2};
            
            PricebookEntry newPricebookEntry = new PricebookEntry(
                Pricebook2Id = test.getStandardPricebookId(),
                Product2Id = p1.Id,
                UnitPrice = 100,
                IsActive = true // You can set other fields as needed
            );
        
        PricebookEntry newPricebookEntry1 = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p2.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        
        Insert new List<PricebookEntry>{newPricebookEntry1,newPricebookEntry};
            
            //List<orderItem> opList = new 
            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = newPricebookEntry.Id,
                Product2Id = p1.Id,
                Quantity = 1, 
                UnitPrice = 100,
                Type__c = 'Vehicle'
            );
        
        
        Insert new List<orderItem>{orderItem};
            
            VehicleDefinition v1 = new VehicleDefinition(
                Name = 'someName',
                ProductId = p1.Id
            );
        insert v1;
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BR23456',
            Software_Version__c = sft.Id
        );
        insert vehicle;
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        
        //Assign the Vehicle
        order order2 = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Pre Invoice',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id,
            Id = order.Id,
            Assigned_Vehicle__c = vehicle.Id            
        ); 
        
        //update order;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        Payment__c payment = new Payment__c(
            Amount__c = o1.Grand_Total__c,           
            Payment_Status__c = 'Success',
            Mode_Of_Payment__c = 'Credit Card',
            Transaction_Id__c = 'payment3'
        );
        insert payment;
        
        // Create related Order Payment records for the test Payments
        
        Order_Payment__c op = new Order_Payment__c(
            Payments__c = payment.Id,
            Order__c = order.Id,
            Type__c = 'Down Payment'
        );
        
        insert op;
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Months',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;
        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        Test.startTest();
        OrderStatusHandler.ceateInvoiceRecords(testNewOrderList, oldMap);
        
        order2.status = 'RTO Registration';
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.generateIvoicesAndReceipts(testNewOrderList, oldMap);
        
        oldMap.get(order.Id).Status = 'RTO Registration';
        order2.status = 'Activated';
        
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.sendPreOrderReceipt(testNewOrderList, oldMap);
        
        OrderStatusHandler.sendPreOrderReceipt01(new List<Order_Payment__c>{op});
        
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testcreateInvoicesAccessoriesTest() {
        // Create sample Order and Vehicle records
        Account acc = new Account(Name = 'Test Name',Type = 'Customer',Phone='9011113246', Email__c = 'test@gmail.com');
        insert acc;
        
        Account dealerAccount = new Account(Name = 'Test Name',Type = 'Dealer',Phone='9011113286', Email__c = 'dealer@test.com' );
        dealerAccount.Account_Number__c = '47723745723457';
        dealerAccount.Bank_Name__c = 'Canara';
        dealerAccount.Center_Code__c = 'BR';
        dealerAccount.Invoice_Sequence__c = 0;
        insert dealerAccount;
        
        List<Contact> contactList = [SELECT id, name FROM Contact WHERE AccountId = :acc.Id];
        contact contacts = new contact();
        If(contactList.size()>0){
            contacts = contactList[0];
        }else{
            contacts = new contact(lastName='test Contact', Primary_contact__c=true, FirstName='Test name', Phone='6767676767', email='testemail@gmail.com', AccountId=acc.Id);
            insert contacts;
        }
        
        Order order = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id
            
        );
        Insert order;
        
        
        Product2 p1 = new Product2(
            Name = 'someName',
            HSN_Code__c='Testt',
            Type__c = 'Vehicle',
            IsActive = true,
            ProductCode = 'code 8'
        );
        
        Product2 p2 = new Product2(
            Name = 'someName1',
            HSN_Code__c='Testt1',
            Type__c = 'Accessories',
            IsActive = true,
            ProductCode = 'code 9'
        );
        
        Insert new list<Product2>{p1,p2};
            
            PricebookEntry newPricebookEntry = new PricebookEntry(
                Pricebook2Id = test.getStandardPricebookId(),
                Product2Id = p1.Id,
                UnitPrice = 100,
                IsActive = true // You can set other fields as needed
            );
        
        PricebookEntry newPricebookEntry1 = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = p2.Id,
            UnitPrice = 100,
            IsActive = true // You can set other fields as needed
        );
        
        Insert new List<PricebookEntry>{newPricebookEntry1,newPricebookEntry};
            
            OrderItem orderItem1 = new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = newPricebookEntry1.Id,
                Product2Id = p2.Id,
                Quantity = 1, 
                UnitPrice = 100,
                Type__c = 'Accessories'
            );
        
        
        Insert new List<orderItem>{orderItem1};
            
            VehicleDefinition v1 = new VehicleDefinition(
                Name = 'someName',
                ProductId = p1.Id
            );
        insert v1;
        
        Software_Version__c sft = new Software_Version__c(Name='Test Name', Latest_Software_Version__c = true);
        insert sft;
        Asset a1 = new Asset(
            Name = 'someName',
            AccountId = acc.Id,
            ContactId= contacts.Id
        );
        insert a1;
        Vehicle vehicle = new Vehicle(
            Name='someName',
            VehicleDefinitionId = v1.Id,
            AssetId = a1.Id,
            VehicleIdentificationNumber = '111S',
            Charger_PC_Number__c = 'BR23456',
            Software_Version__c = sft.Id
        );
        insert vehicle;
        
        Order Order1 = order;
        Order1.Status = 'Draft';
        
        //Assign the Vehicle
        order order2 = new Order(
            AccountId = acc.Id,
            Website_Order_Id__c = 'RTYU456789',
            EffectiveDate = Date.today(),
            Status = 'Pre Invoice',
            Description = 'Nothing',
            Handling_Charges__c = 1000,
            Insurance_Amount__c = 1000,
            RTO_Charges__c = 1000,
            Notify_By_SMS__c = true,
            Notify_By_Email__c = true,
            BillingStreet = 'Bangalore',
            BillingCity = 'Bangalore',
            BillingState = 'Karnataka',
            BillingPostalCode = '574216',
            BillingCountry = 'India',
            pricebook2Id = test.getStandardPricebookId(),
            Dealer__c = dealerAccount.Id,
            Id = order.Id,
            Assigned_Vehicle__c = vehicle.Id            
        ); 
        
        //update order;
        
        Order o1 = [SELECT Id, Grand_Total__c from Order WHERE Id =:order.Id];
        
        Payment__c payment = new Payment__c(
            Amount__c = o1.Grand_Total__c,           
            Payment_Status__c = 'Success',
            Mode_Of_Payment__c = 'Credit Card',
            Transaction_Id__c = 'payment4'
        );
        insert payment;
        
        // Create related Order Payment records for the test Payments
        
        Order_Payment__c op = new Order_Payment__c(
            Payments__c = payment.Id,
            Order__c = order.Id,
            Type__c = 'Down Payment'
        );
        
        insert op;
        
        WarrantyTerm warrantyTerm = new WarrantyTerm(	
            WarrantyTermName = 'Ssss',
            WarrantyDuration = 7889,
            WarrantyUnitOfTime = 'Weeks',
            EffectiveStartDate = 'Install Date',
            WarrantyType = 'Repair');
        insert warrantyTerm;
        
        // Create oldMap with the old order record
        Map<Id, Order> oldMap = new Map<Id, Order>();
        oldMap.put(order.Id, Order1);
        
        List<Order> testNewOrderList = new List<Order>();
        testNewOrderList.add(order2);
        
        Test.startTest();
        OrderStatusHandler.ceateInvoiceRecords(testNewOrderList, oldMap);
        
        order2.status = 'RTO Registration';
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.generateIvoicesAndReceipts(testNewOrderList, oldMap);
        
        oldMap.get(order.Id).Status = 'RTO Registration';
        order2.status = 'Activated';
        
        testNewOrderList.clear();
        testNewOrderList.add(order2);
        OrderStatusHandler.sendPreOrderReceipt(testNewOrderList, oldMap);
        
        OrderStatusHandler.sendPreOrderReceipt01(new List<Order_Payment__c>{op});
        
        
        Test.stopTest();
        
    }
    
}