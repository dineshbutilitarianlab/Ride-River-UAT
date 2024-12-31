public class RSAcalloutHelper {
    
    @future(callout=true)
    public static void RsaFuthuremethod(string vehicleRegistrationNo,string chassisNO,Id OrderidNo){
        RSAcalloutHelper.getrefreshtokent(vehicleRegistrationNo,chassisNO,OrderidNo);   
    }
    
    public static void getrefreshtokent(string vehicleRegistrationNo,string chassisNO,Id OrderidNo){
        try{
            httprequest req=new httprequest();
            req.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/login');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('key-id', 'RAD494NL5HV63');
            String bodydata = '{"clientId":"9f600062-b3d5-4207-8039-c92d04f888c8", "clientSecretCode":"RAD494NL5HV63"}';
            req.setBody(bodydata);
            Http h = new Http();
            
            HttpResponse response = h.send(req);
            if (response.getStatusCode() == 200) {
                System.debug('Response1: ' + response.getBody());
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> dataMap = (Map<String, Object>) jsonResponse.get('data');
                string token= (String) dataMap.get('token');
                string refrehtoken=(String)dataMap.get('refreshToken');
                system.debug('token1='+token);
                system.debug('refrehtoken='+refrehtoken);
                
                RSAcalloutHelper.getbareertooken(vehicleRegistrationNo,chassisNO,OrderidNo,refrehtoken,token);
                
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }   
    }
    
    public static void getbareertooken(string vehicleRegistrationNo,string chassisNO,Id OrderidNo,string refrehtoken,string token){
        httprequest req=new httprequest();
        req.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/refresh-token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+token);
        req.setHeader('key-id', 'RAD494NL5HV63');
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('clientId', '9f600062-b3d5-4207-8039-c92d04f888c8');
        requestBody.put('refreshToken', refrehtoken);
        
        String bodydata = JSON.serialize(requestBody);
        system.debug('hj========'+bodydata);
        
        req.setBody(bodydata);
        Http h = new Http();
        
        HttpResponse response = h.send(req);
        if (response.getStatusCode() == 200) {
            System.debug('Response2: ' + response.getBody());
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) jsonResponse.get('data');
            string bareertoken=(String)dataMap.get('token');
            system.debug('bareer='+bareertoken);
            
            RSAcalloutHelper.getvehiclesync( vehicleRegistrationNo,chassisNO,OrderidNo,bareertoken);
            
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        
    }
    
    public static void getvehiclesync(string vehicleRegistrationNo,string chassisNO,Id OrderidNo,string bareertoken){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint (URL)
        request.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/sync-reg');
        request.setMethod('PUT');
        
        // Set the headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer '+bareertoken);
        request.setHeader('key-id', 'RAD494NL5HV63');
        
        // Set the body
        String requestBody = '{"chassisNo":"' + chassisNO + '", "registrationNo":"' + vehicleRegistrationNo + '"}';
        request.setBody(requestBody);
        
        // Send the HTTP request
        HttpResponse response = http.send(request);
        
        // Process the response
        if (response.getStatusCode() == 200) {
            System.debug('Response Body: ' + response.getBody());
            
            
        } else {
            System.debug('Error: HTTP Status ' + response.getStatusCode() + ' - ' + response.getStatus());
        } 
        
    }
    
    @future(callout=true)
    public static void RsaCreationFuthuremethod(string chassisNO,Id OrderidNo,string Accountname,string MobileNo,Id VehicleId){
        try{
            RSAcalloutHelper.getrefreshtokentlogin(chassisNO,OrderidNo,Accountname,MobileNo,VehicleId);
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }        
    }
    
    public static void getrefreshtokentlogin(string chassisNO,Id OrderidNo,string Accountname,string MobileNo,Id VehicleId){
        try{
            httprequest req=new httprequest();
            req.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/login');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('key-id', 'RAD494NL5HV63');
            String bodydata = '{"clientId":"9f600062-b3d5-4207-8039-c92d04f888c8", "clientSecretCode":"RAD494NL5HV63"}';
            req.setBody(bodydata);
            Http h = new Http();
            HttpResponse response = h.send(req);
            
            if (response.getStatusCode() == 200) {
                System.debug('Response1: ' + response.getBody());
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> dataMap = (Map<String, Object>) jsonResponse.get('data');
                string token= (String) dataMap.get('token');
                string refrehtoken=(String)dataMap.get('refreshToken');
                
                RSAcalloutHelper.getbareertokenforcreation(chassisNO,OrderidNo,Accountname,MobileNo,refrehtoken,token,VehicleId);
                
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        }
    }
    
    public static void getbareertokenforcreation(string chassisNO,Id OrderidNo,string Accountname,string MobileNo,string refrehtoken,string token,Id VehicleId){
        httprequest req=new httprequest();
        req.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/refresh-token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+token);
        req.setHeader('key-id', 'RAD494NL5HV63');
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('clientId', '9f600062-b3d5-4207-8039-c92d04f888c8');
        requestBody.put('refreshToken', refrehtoken);
        
        String bodydata = JSON.serialize(requestBody);
        
        req.setBody(bodydata);
        Http h = new Http();
        
        HttpResponse response = h.send(req);
        if (response.getStatusCode() == 200) {
            System.debug('Response2: ' + response.getBody());
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) jsonResponse.get('data');
            string bareertoken=(String)dataMap.get('token');
            
            RSAcalloutHelper.fetchSubscriptionPlans(chassisNO,OrderidNo,Accountname,MobileNo,bareertoken,VehicleId);
            
        } else {
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        
    }
    
    public static void fetchSubscriptionPlans(string chassisNO,Id OrderidNo,string Accountname,string MobileNo,string bareertoken,Id VehicleId){
        
        String clientId = '9f600062-b3d5-4207-8039-c92d04f888c8';
        
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        
        String url = 'https://vms.readyassist.net/api/order/client/tieup/tagged/subscription-plans?clientId=' +clientId ;
        req.setEndpoint(url);
        
        req.setMethod('GET');
        
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+bareertoken);
        req.setHeader('key-id', 'RAD494NL5HV63');
        
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            System.debug('Response3: ' + response.getBody());// Deserialize the JSON response into an untyped Map
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            List<Object> dataList = (List<Object>) jsonResponse.get('data');
            Integer planId;
            if (!dataList.isEmpty()) {
                Map<String, Object> firstDataItem = (Map<String, Object>) dataList[0];
                
                planId = (Integer) firstDataItem.get('planId');
                
                System.debug('Plan ID: ' + planId);
            }
            
            
            
            RSAcalloutHelper.createSubscription( chassisNO,OrderidNo,Accountname,MobileNo,bareertoken,planId,VehicleId);
            
            
        } else {
            System.debug('Error: ' + response.getStatus() + ' ' + response.getBody());
        }
        
    }
    
    public static void createSubscription(string chassisNO,Id OrderidNo,string Accountname,string MobileNo,string bareertoken,Integer planId,Id VehicleId) {
        try{
            String payload = JSON.serialize(new Map<String, Object>{
                'clientId' => '9f600062-b3d5-4207-8039-c92d04f888c8',
                    'customerName' => Accountname,
                    'customerMobileNo' => MobileNo,
                    'vehicleType' => 'BIKE',
                    'vehicleMake' => 'River',
                    'vehicleModel' => 'Indie',
                    'vehicleChassisNo' =>chassisNO,
                    'sellerId' => 2289,
                    'planId' => planId,
                    'purchaseThrough' => 'credit'
                    });
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            
            req.setEndpoint('https://vms.readyassist.net/api/order/client/tieup/subscription-creation');
            
            req.setMethod('POST');
            
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer '+bareertoken);
            req.setHeader('key-id', 'RAD494NL5HV63');
            
            req.setBody(payload);
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug('Subscription created successfully: ' + res.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Access the data object
                Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
                
                // Extract required fields
                Integer subscriptionId = (Integer) dataMap.get('subscriptionId');
                string expiryDateString = (string) dataMap.get('expiryDate');
                string startDatestring = (string) dataMap.get('startDate');
                String formattedDateTimeString = expiryDateString.replace('T', ' ').replace('Z', '');
                DateTime dtexpiryDateString = DateTime.valueOf(formattedDateTimeString);
                String formattedDateTimeStringstartDatestring = startDatestring.replace('T', ' ').replace('Z', '');
                DateTime dtstartDatestring = DateTime.valueOf(formattedDateTimeStringstartDatestring);
                String formattedStringexpiryDateString = dtexpiryDateString.format('dd-MM-yyyy HH:mm:ss');
                String formattedStringstartDatestring = dtstartDatestring.format('dd-MM-yyyy HH:mm:ss');
                
                order resultorder=[select Id,RSA_Active__c from Order r where Id=:OrderidNo];
                resultorder.RSA_Active__c=true;
                Update resultorder;
                Vehicle ve=[select Id from Vehicle where Id=:VehicleId ];
                ve.RSA_Activation__c=true;
                ve.RSA_Subscription_ID__c=subscriptionId;
                ve.RSA_Start_Date__c=formattedStringstartDatestring;
                ve.RSA_End_Date__c=formattedStringexpiryDateString;
                update ve;
                system.debug('hfdbhb======='+resultorder);
                
            } else {
                System.debug('Error : ' + res.getStatus() + ' - ' + res.getBody());
            }
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage()+' && Error Line == >'+e.getLineNumber());
        } 
    }
    
}