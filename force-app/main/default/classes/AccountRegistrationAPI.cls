@RestResource(urlMapping='/RegisterAccount')
global with sharing class AccountRegistrationAPI {
    
    @HttpPost
    global static void createAccountContact() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        Map<String, String> response = new Map<String, String>();
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        // Deserialize the JSON request body into a map
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
        Map<String, Object> billing_address = (Map<String, Object>)requestMap.get('billing_address') != null? (Map<String, Object>)requestMap.get('billing_address'):null;
        Map<String, Object> shipping_address = (Map<String, Object>)requestMap.get('shipping_address') != null? (Map<String, Object>)requestMap.get('shipping_address'):null;
        
        String leadEmail = (String)requestMap.get('email_address') != null? (String)requestMap.get('email_address'): '';
        String phone = (String)requestMap.get('phone_number') != null?(String)requestMap.get('phone_number'):'';
        String accountId = null;
        List<lead> existingLead = new List<lead>();
        List<Account> existingAccount = new List<Account>();
        
        Try{
            
            If(phone != '')
                existingAccount = [SELECT Id FROM Account WHERE Phone = :phone LIMIT 1];
            
            If(existingAccount.isEmpty()){
                // Check if a Lead with the provided email exists
                If(leadEmail != '' && phone != ''){
                    existingLead = [SELECT Id FROM Lead WHERE Email = :leadEmail AND Phone = :phone AND isConverted = false LIMIT 1];
                }else if(leadEmail != '' && phone == ''){
                    existingLead = [SELECT Id FROM Lead WHERE Email = :leadEmail AND isConverted = false LIMIT 1];
                }else if(leadEmail == '' && phone != ''){
                    existingLead = [SELECT Id FROM Lead WHERE Phone = :phone AND isConverted = false LIMIT 1];
                }
                
                if (existingLead.size()>0) {
                    // Convert the Lead to an Account and Contact
                    system.debug('existing lead found>>'+existingLead[0]);
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(existingLead[0].Id);
                    lc.setConvertedStatus('Qualified');
                    
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    
                    if (lcr.isSuccess()) {
                        system.debug('Lead converted to Account and Contact' + lcr.getAccountId() + ' contact is >> ' + lcr.getContactId());
                        Id newContactId = lcr.getContactId();
                        
                        // Set the custom field Primary_Contact__c to true on the Contact
                        //Contact newContact = new Contact(Id = newContactId, Primary_Contact__c = true);
                        //update newContact;
                        
                        // Set billing and shipping addresses on the Account
                        Account newAccount = new Account(Id = lcr.getAccountId(),
                                                         Type = 'Customer',
                                                         Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                                                         Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                                                         BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                                                         BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+ ((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                                                         BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                                                         BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                                                         BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                                                         //BillingCountry = 'IN',
                                                         ShippingCountry = (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India',
                                                         ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '')+ ' '+((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                                                         ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                                                         ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                                                         ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                                                         //ShippingCountry = 'IN'
                                                        );
                        update newAccount;
                        
                        accountId = lcr.getAccountId();
                    } else {
                        system.debug('error occurred >> ' + lcr);
                    }
                } else {
                    system.debug('creating new account and contact1');
                    // Create a new Account and Contact
                    Account newAccount = new Account(
                        Name = (String)requestMap.get('full_name'),
                        AccountSource = 'Web',
                        Type = 'Customer',
                        Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                        BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                        Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                        BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                        BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                        BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                        BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                        //BillingCountry = 'IN',
                        ShippingCountry = (String)shipping_address.get('country') != null ? (String)shipping_address.get('country') : 'India',
                        ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '') +' '+ ((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                        ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                        ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                        ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                        //ShippingCountry = 'IN'
                    );
                    insert newAccount;
                    
                    
                    /*Contact newContact = new Contact(
LastName = (String)requestMap.get('full_name'),
Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
Email = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
AccountId = newAccount.Id,
Primary_Contact__c = true
);
insert newContact;

system.debug('new contact is inserted>>'+newContact);*/
                    
                    accountId = newAccount.Id;
                }
            }
            Else{
                accountId = existingAccount[0].Id;
                
                Account newAccount = new Account(
                    id = accountId, 
                    Name = (String)requestMap.get('full_name'),
                    Type = 'Customer',
                    Email__c = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
                    BillingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                    Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
                    BillingStreet = ((String)billing_address.get('address_1') != null ? (String)billing_address.get('address_1') : '') +' '+((String)billing_address.get('address_2') != null ? (String)billing_address.get('address_2') : ''),
                    BillingCity = (String)billing_address.get('city') != null ? (String)billing_address.get('city') : '',
                    BillingState = (String)billing_address.get('state') != null ? (String)billing_address.get('state') : '',
                    BillingPostalCode = (String)billing_address.get('pin_code') != null ? (String)billing_address.get('pin_code') : '',
                    //BillingCountry = 'IN',
                    ShippingCountry = (String)billing_address.get('country') != null ? (String)billing_address.get('country') : 'India',
                    ShippingStreet = ((String)shipping_address.get('address_1') != null ? (String)shipping_address.get('address_1') : '') +' '+ ((String)shipping_address.get('address_2') != null ? (String)shipping_address.get('address_2') : ''),
                    ShippingCity = (String)shipping_address.get('city') != null ? (String)shipping_address.get('city') : '',
                    ShippingState = (String)shipping_address.get('state') != null ? (String)shipping_address.get('state') : '',
                    ShippingPostalCode = (String)shipping_address.get('pin_code') != null ? (String)shipping_address.get('pin_code') : ''
                    //ShippingCountry = 'IN'
                );
                Update newAccount;
                
                /*List<contact> conlist = [SELECT Id FROM Contact WHERE AccountId = :accountId AND Primary_Contact__c = true LIMIT 1];
If(conlist.isEmpty()){
List<contact> conlist1 = [SELECT Id, Primary_Contact__c FROM Contact WHERE AccountId = :accountId LIMIT 1];

If(conlist1.isEmpty()){
Contact newContact = new Contact(
LastName = (String)requestMap.get('full_name'),
Phone = (String)requestMap.get('phone_number') != null ? (String)requestMap.get('phone_number') : '',
Email = (String)requestMap.get('email_address') != null ? (String)requestMap.get('email_address') : '',
AccountId = accountId,
Primary_Contact__c = true
);
insert newContact; 
}else{
conlist1[0].Primary_Contact__c = true;
Update conlist1[0];
}
}*/
            }
            
            response.put('status', 'Success');
            
            response.put('accountId', accountId);
            res.statusCode = 200; 
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            
            //Creating a Log record
            Integration_Log__c  logObj = new Integration_Log__c(
                Integration_Type__c = 'Account Registration',
                Request_Payload__c = JSON.seriaLizePretty(requestMap),
                Response_Payload__c = JSON.seriaLizePretty(response),
                Status__c = 'Success'
            );
            Insert logObj;
            system.debug('Log created>>'+logObj);
        }
        catch(exception e){
            
            system.debug('Exception occured: '+e);
            response.put('status', 'Failed');
            res.statusCode = 500; 
            res.responseBody = Blob.valueOf('Exception: '+e.getMessage());
            
            //Creating a Log record
            Integration_Log__c  logObj = new Integration_Log__c(
                Integration_Type__c = 'Account Registration',
                Request_Payload__c = JSON.seriaLizePretty(requestMap),
                Response_Payload__c = JSON.seriaLizePretty(res),
                Error_Message__c = 'Exception: '+e.getMessage(),
                Status__c = 'Failed'
            );
            Insert logObj;
            system.debug('Log created exception>>'+logObj);
            
        }
    }
    
    Global class CommonException extends Exception {}
}