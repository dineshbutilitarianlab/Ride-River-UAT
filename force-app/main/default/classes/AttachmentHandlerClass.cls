public class AttachmentHandlerClass {
    
    @Future (callout=true)
    public static void AttachmentHandlerMethod(Set<Id> orderIds, string mapString) {  
        System.debug('AttachmentHandlerClass Called Dinesh 2');
        System.debug('orderIds == >'+ orderIds +' && mapString == >'+mapString);
        map<id,List<Attachment>> mapOrderIdToAttachments = new map<id,List<Attachment>>();
        Map<Id, Map<string,string>> orderIdToInvTypeToInvNoMap = new Map<Id, Map<string,string>>();
        Map<Id, Map<string,string>> orderIdToInvTypeToInvDateMap = new Map<Id, Map<string,string>>();
        Map<Id, Set<String>> orderToItemTypeMap = (Map<Id, Set<String>>) JSON.deserialize(mapString, Map<Id, Set<String>>.class);
        
        System.debug('orderToItemTypeMap>>'+ orderToItemTypeMap);
        
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        
        // Query the Orders
        List<Order> orders = [SELECT Id, Name,AccountId, Dealer__c, Website_Order_Id__c,Handling_Charges__c,Warranty_Amount__c,RTO_Charges__c,Insurance_Amount__c, OrderNumber FROM Order WHERE Id IN :orderIds];
        system.debug('orders==>'+orders);
        
        //mappring the invoice IDs
        For(Order_Invoice__c orderInvoice:[SELECT Id, Invoice_Number__c, Invoice_Type__c, Name, Order__c, Invoice_date__c  FROM Order_Invoice__c WHERE Order__c IN :orderIds]){
            If(!orderIdToInvTypeToInvNoMap.containskey(orderInvoice.Order__c)){
                
                orderIdToInvTypeToInvNoMap.Put(orderInvoice.Order__c, new Map<string,string>{orderInvoice.Invoice_Type__c => orderInvoice.Invoice_Number__c});
                
                If(orderInvoice.Invoice_date__c!= null){
                    orderIdToInvTypeToInvDateMap.Put(orderInvoice.Order__c, new Map<string,string>{orderInvoice.Invoice_Type__c => orderInvoice.Invoice_date__c.format()});
                }else{
                    orderIdToInvTypeToInvDateMap.Put(orderInvoice.Order__c, new Map<string,string>{orderInvoice.Invoice_Type__c => system.today().format()});
                }
                
            }else{
                orderIdToInvTypeToInvNoMap.get(orderInvoice.Order__c).Put(orderInvoice.Invoice_Type__c,orderInvoice.Invoice_Number__c);
                orderIdToInvTypeToInvDateMap.get(orderInvoice.Order__c).Put(orderInvoice.Invoice_Type__c,orderInvoice.Invoice_date__c.format());
            }
        }
        
        for (Order order : orders) {
            
            List<attachment> attachmentList = new List<Attachment>();
            set<string> itemTypes = orderToItemTypeMap.get(order.Id);
            
            String str;
            If(order.Website_Order_Id__c != null && order.Website_Order_Id__c != ''){
                str = String.valueOf(order.Website_Order_Id__c);
            }else {
                str = order.OrderNumber;
            }
            
            String result = str.substring(Math.max(0, str.length() - 4));
            System.debug('result==>' + result);
            
            
            If(itemTypes.contains('Vehicle')){
                
                // Generate Vehicle Invoice
                If(orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Vehicle Invoice')){
                    
                    // Create Attachment record
                    PageReference pdfPage = Page.CreateReceiptVehicle; 
                    Attachment att = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Vehicle Invoice'), 'Vehicle Tax Invoice - '+result, pdfPage, orderIdToInvTypeToInvDateMap.get(order.Id).get('Vehicle Invoice'));
                    
                    attachmentsToInsert.add(att);       
                    attachmentList.add(att);
                    
                }else{
                    If(!Test.isRunningTest())
                    throw new MyException('Vehicle Invoice record is not found for the order '+order.OrderNumber);
                }
                
                // Generate CreateDeliveryChallan PDF
                PageReference pdfPages = Page.CreateDeliveryChallan; 
                Attachment atta = createReceiptPDF(order.Id, 'Delivery Challan - ' +result, pdfPages);
                
                attachmentsToInsert.add(atta); 
                attachmentList.add(atta);
                
                // Generate CreateReceiptRtoInsurance PDF
                if(order.RTO_Charges__c!=null || order.Insurance_Amount__c!=null ){  
                    
                    PageReference pdfPage1 = Page.CreateReceiptRtoInsurance; 
                    Attachment att1 = createReceiptPDF(order.Id, 'RTO & Insurance Receipt - ' +result , pdfPage1);
                    
                    attachmentList.add(att1);
                    attachmentsToInsert.add(att1);
                }
                
                system.debug('handling started');
                if(order.Handling_Charges__c!=null || order.Warranty_Amount__c!=null ){
                    If(orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Other Charges Invoice')){
                        
                        // Create Attachment 
                        PageReference pdfPage2 = Page.CreateReceiptOtherCharges; 
                        Attachment att2 = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Other Charges Invoice'), 'Other Charges Tax Invoice - '+result, pdfPage2, orderIdToInvTypeToInvDateMap.get(order.Id).get('Other Charges Invoice'));
                        
                        attachmentsToInsert.add(att2); 
                        attachmentList.add(att2);
                    }else{
                        If(!Test.isRunningTest())
                        throw new MyException('Other Charges Invoice record is not found for the order '+order.OrderNumber);
                    }
                }
                
                //adding additional files
                List<River_Files_To_Customer__mdt> filesMetadata = [SELECT Id, DeveloperName, Label, File_Name__c FROM River_Files_To_Customer__mdt WHERE Active__c = true];
                List<String> filesNameListToSend = new List<String>();
                For(River_Files_To_Customer__mdt file : filesMetadata){
                    filesNameListToSend.add(file.File_Name__c);
                }
                
                For(contentVersion resource:[SELECT VersionData, ContentDocument.FileType, ContentDocument.Title, FileExtension FROM contentVersion WHERE ContentDocument.Title IN: filesNameListToSend]){
                    
                    // Create Attachment 
                    Attachment attachment = new Attachment();
                    
                    attachment.Name = resource.ContentDocument.Title + '.' + resource.fileExtension;
                    
                    attachment.Body = resource.VersionData;
                    attachment.ContentType = resource.ContentDocument.FileType;
                    attachmentList.add(attachment);
                    system.debug('attachment>>'+attachment);
                }
                
            }
            If(itemTypes.contains('Add-ons')){
                
                // Generate Add-ons Invoice
                If(orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Add-ons Invoice')){
                    
                    // Create Attachment record
                    PageReference pdfPage4 = Page.CreateReceiptAddOns; 
                    Attachment att4 = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Add-ons Invoice'), 'Add-ons Tax Invoice - '+result, pdfPage4, orderIdToInvTypeToInvDateMap.get(order.Id).get('Add-ons Invoice'));
                    
                    attachmentsToInsert.add(att4);       
                    attachmentList.add(att4);
                    
                }else{
                    If(!Test.isRunningTest())
                    throw new MyException('Add-ons Invoice record is not found for the order '+order.OrderNumber);
                }
            }
            if (itemTypes.contains('Accessories') || itemTypes.contains('Parts')) {       
                
                //Generate Accessories invoice PDF
                If(orderIdToInvTypeToInvNoMap.get(order.Id) != null && orderIdToInvTypeToInvNoMap.get(order.Id).containsKey('Accessories Invoice')){
                    
                    // Create Attachment 
                    PageReference pdfPage3 = Page.CreateReceiptAccessories; 
                    Attachment att3 = createInvoicePDF(order.Id, orderIdToInvTypeToInvNoMap.get(order.Id).get('Accessories Invoice'), 'Accessories Tax Invoice - '+result, pdfPage3, orderIdToInvTypeToInvDateMap.get(order.Id).get('Accessories Invoice'));
                    
                    attachmentsToInsert.add(att3);
                    attachmentList.add(att3);
                }else{
                    If(!Test.isRunningTest())
                    throw new MyException('Accessories Invoice record is not found for the order '+order.OrderNumber);
                }
            }
            
            // create map of attchments against each order Id
            mapOrderIdToAttachments.put(order.Id,attachmentList);
        }
        
        SendEmailHandller.SendEmailHandller(orders,mapOrderIdToAttachments);
        
        if (!attachmentsToInsert.isEmpty()) {
            insert attachmentsToInsert;
        }
        system.debug('attachmentsToInsert Dinesh==>'+attachmentsToInsert);
    }
    
    //Method to generate the invoice
    Public static Attachment createInvoicePDF(Id orderId, string invoiceSequence, string fileName, PageReference pdfPage, string invoiceDate){
        
        pdfPage.getParameters().put('id', orderId);
        pdfPage.getParameters().put('sequence', invoiceSequence);
        pdfPage.getParameters().put('date', invoiceDate);
        
        Blob pdfBlob;
        if (!Test.isRunningTest()) {
            pdfBlob = pdfPage.getContent();
        } else {
            pdfBlob = Blob.valueOf('Test');
        }
        
        // Create Attachment record
        Attachment attachment = new Attachment();
        attachment.Name = fileName+'.pdf';
        attachment.Body = pdfBlob;
        attachment.ParentId = orderId;
        attachment.ContentType = 'application/pdf';
        
        return attachment;
    }
    
    //Method to generate the Receipts
    Public static Attachment createReceiptPDF(Id orderId, string fileName, PageReference pdfPage){
        
        pdfPage.getParameters().put('id', orderId);
        Blob pdfBlob;
        if (!Test.isRunningTest()) {
            pdfBlob= pdfPage.getContent();
        } else {
            pdfBlob = Blob.valueOf('Test');
        }
        
        // Create Attachment record
        Attachment attachment = new Attachment();
        attachment.Name = fileName + '.pdf';
        attachment.Body = pdfBlob;
        attachment.ParentId = orderId;
        attachment.ContentType = 'application/pdf';
        
        return attachment;
    }
    
    //================================================================================================================================================================
    
    @future(callout=true)
    public static void AttachmentHandlerMethod03(string orderIds) {
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        map<id,List<Attachment>> mapOrderIdToAttachments = new map<id,List<Attachment>>();
        // Query the Orders
        List<Order> orders = [SELECT Id, Name,AccountId,Booking_Payment_Id__c,Website_Order_Id__c, OrderNumber FROM Order WHERE Id = :orderIds];
        system.debug('orders==>'+orders);
        
        for (Order order : orders) {
            
            List<attachment> attachmentList = new List<Attachment>();
            
            String str;
            If(order.Website_Order_Id__c != null && order.Website_Order_Id__c != ''){
                str = String.valueOf(order.Website_Order_Id__c);
            }else {
                str = order.OrderNumber;
            }
            
            String result = str.substring(Math.max(0, str.length() - 4));
            System.debug('result==>' + result);
            
            // Generate Charge PDF
            PageReference pdfPage1 = Page.PreOrderReceipt; 
            pdfPage1.getParameters().put('id', order.Id);
            Blob pdfBlob1;
            if (!Test.isRunningTest()) {
                pdfBlob1= pdfPage1.getContent();
            } else {
                pdfBlob1 = Blob.valueOf('Test');
            }
            
            // Create Attachment record
            Attachment att1 = new Attachment();
            att1.Name = 'Pre Order Receipt-' + result + '.pdf';
            att1.Body = pdfBlob1;
            att1.ParentId = order.Id;
            att1.ContentType = 'application/pdf';
            
            attachmentsToInsert.add(att1);
            attachmentList.add(att1);
        }
        
        system.debug('attachmentsToInsert 123==>'+attachmentsToInsert);
        
        // Insert attachments
        if (!attachmentsToInsert.isEmpty()) { 
            insert attachmentsToInsert;
        }
        
        SendEmailHandller.SendEmailHandller2(orders,attachmentsToInsert);
    }
    
    //================================================================================================================================================================
    
    @future(callout=true)
    public static void pdfAction(Id OrderpaymentId) {
        
        try{  
            //system.debug('OrderpaymentId==>'+OrderpaymentId);
            list<Order_Payment__c>lstOrderPayments=[SELECT name,Payments__r.Payment_Status__c,Order__r.Id FROM Order_Payment__c  WHERE Id=:OrderpaymentId];
            List<Attachment> attachmentsToInsert = new List<Attachment>();
            
            for(Order_Payment__c obj :lstOrderPayments){
                if(obj.Payments__r.Payment_Status__c=='Success'){
                    PageReference pdfPage1 = Page.CreateReceiptPayments; 
                    pdfPage1.getParameters().put('id', obj.Id);
                    Blob pdfBlob1;
                    if (!Test.isRunningTest()) {
                        pdfBlob1= pdfPage1.getContent();
                    } else {
                        pdfBlob1 = Blob.valueOf('Test');
                    }
                    
                    // Create Attachment record
                    Attachment att1 = new Attachment();
                    att1.Name = 'Payment Acknowledgement.pdf';
                    att1.Body = pdfBlob1;
                    att1.ParentId = obj.Id;
                    att1.ContentType = 'application/pdf';
                    
                    attachmentsToInsert.add(att1);
                }
            }
            
            if (!attachmentsToInsert.isEmpty()) {
                insert attachmentsToInsert;
                SendEmailHandller.sendPreAttchamnets(lstOrderPayments[0].Id,attachmentsToInsert); 
            }
        }catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
    }
    
    Public class myexception extends exception{}
    
}