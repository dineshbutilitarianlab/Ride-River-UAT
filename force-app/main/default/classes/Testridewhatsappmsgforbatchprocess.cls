public class Testridewhatsappmsgforbatchprocess implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date twoDaysAgo = Date.today();
        DateTime startOfDay = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
DateTime endOfDay = DateTime.newInstance(Date.today(), Time.newInstance(23, 59, 59, 999));

List<Test_Drive__c> testDrives = [
    SELECT Id, Lead__c, Test_Ride_Date__c, Ride_Type__c
    FROM Test_Drive__c
    WHERE Test_Ride_Date__c >= :startOfDay AND Test_Ride_Date__c <= :endOfDay
];

        if (Test.isRunningTest()) {
  return Database.getQueryLocator(
    'SELECT Id, Lead__c, Test_Ride_Date__c, Ride_Type__c ' +
    'FROM Test_Drive__c ' +
    'WHERE Test_Ride_Date__c >= :startOfDay AND Test_Ride_Date__c <= :endOfDay'
);
        }else{
          return Database.getQueryLocator(
    'SELECT Id, Lead__c, Test_Ride_Date__c, Ride_Type__c ' +
    'FROM Test_Drive__c ' +
    'WHERE Test_Ride_Date__c >= :startOfDay AND Test_Ride_Date__c <= :endOfDay'
);
        }
    }

    public void execute(Database.BatchableContext bc, List<Test_Drive__c> scope) {
        Map<String, String> storeMap = new Map<String, String>{
    '291001' => 'River Store JP Nagar',
    '291002' => 'River Store Indiranagar',
    '292001' => 'River Store Yelahanka',
    '292002' => 'River Store Rajajinagar',
    '292003' => 'River Store Hubli',
    '362001' => 'River Store Kukatpally',
    '332001' => 'River Store Coimbatore',
    '331001' => 'River Store Anna Nagar',
    '321001' => 'River Store Kochi',
    '122001' => 'River Store Visakhapatnam'
};

        system.debug('list======'+scope);
        for(Test_Drive__c td:scope){
       list<lead> leaddetails=[select Id ,LeadSource,Lead_Dealer_Code__c,phone from Lead where Id=:td.Lead__c];
            for(lead leadid:leaddetails){
                string parameter;
                string recientphoneno=leadid.Phone;
                string fullrecientphoneno='91'+recientphoneno;
                
         if((leadid.LeadSource!='OzoneTel WhatsApp')&&(leadid.Lead_Dealer_Code__c=='291001'||leadid.Lead_Dealer_Code__c=='291002'||leadid.Lead_Dealer_Code__c=='292001'||leadid.Lead_Dealer_Code__c=='292002'||leadid.Lead_Dealer_Code__c=='292003'||leadid.Lead_Dealer_Code__c=='362001'||leadid.Lead_Dealer_Code__c=='332001'||leadid.Lead_Dealer_Code__c=='331001'||leadid.Lead_Dealer_Code__c=='321001'||leadid.Lead_Dealer_Code__c=='122001')){
               system.debug('phone'+fullrecientphoneno);
             if(td.Ride_Type__c=='Home Ride'){
                    parameter='At Your Doorstep';
                }else if(td.Ride_Type__c=='Store Ride'){
                    parameter=storeMap.get(leadid.Lead_Dealer_Code__c);

                }
                     String endpoint = 'https://in-ccaas.ozonetel.com/api/v1/WhatsAppSendOzone/reply';

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('recipient', new Map<String, String>{ 'id' => fullrecientphoneno });
        requestBody.put('kookoo_id', 'OZNTLWA:918197205802');
        requestBody.put('type', 'template');

        Map<String, Object> template = new Map<String, Object>();
        template.put('name', 'on_day_of_test_ride');
        template.put('language', 'en_US');
        template.put('parameters', new Map<String, String>{ '2' => parameter });

        requestBody.put('template', template);

        String jsonBody = JSON.serialize(requestBody);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('apikey', 'KK47b958dee3505cf2e2c6391c27bbaba4');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cookie', 'PHPSESSID=864bfee61e1e8d9cf56873a82389476b');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
                                            
                                            
}
                
            }
        }
        
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Lead batch processing with callouts completed.');
    }
}