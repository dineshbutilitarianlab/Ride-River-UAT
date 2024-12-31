public class TestRideCreateWhatsappmsgcallout {
 @future(callout=true)
    public static void TestRideCreateWhatsappmsgcalloutfuthermethod(string MobileNo,string ridetime,string venue){
        TestRideCreateWhatsappmsgcallout.TestRideCreateWhatsappmsgcalloutexcution(MobileNo,ridetime,venue);
    }
     public static void TestRideCreateWhatsappmsgcalloutexcution(string MobileNo,string times,string store){
         
        String recipientId = '91' + mobileNo;

       String endpoint = 'https://in-ccaas.ozonetel.com/api/v1/WhatsAppSendOzone/reply';

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('recipient', new Map<String, String>{ 'id' => recipientId });
        requestBody.put('kookoo_id', 'OZNTLWA:918197205802');
        requestBody.put('type', 'template');

        Map<String, Object> template = new Map<String, Object>();
        template.put('name', 'test_ride_booked_text');
        template.put('language', 'en_US');
        template.put('parameters', new Map<String, String>{ '1' => store,
            '2'=>times });

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