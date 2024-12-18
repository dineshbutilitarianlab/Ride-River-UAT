public class WhatsAppApiCallout {
    public static  void sendWhatsAppMessage(string Mobile,string templatename) {
                String recipientPhoneNumber = '91' + Mobile; // Concatenates '91' with the passed mobile number

        String url = 'https://in-ccaas.ozonetel.com/api/v1/WhatsAppSendOzone/reply';
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(url);
        request.setMethod('POST');
        
        request.setHeader('apikey', 'KK47b958dee3505cf2e2c6391c27bbaba4');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Cookie', 'PHPSESSID=864bfee61e1e8d9cf56873a82389476b');
        
        String body = '{' +
    '"recipient": {' +
        '"id": "' + recipientPhoneNumber + '"' + 
    '},' +
    '"kookoo_id": "OZNTLWA:918197205802",' +
    '"type": "template",' +
    '"header": {' +
        '"type": "image",' +
        '"image": {' +
            '"link":"https://s3.ap-south-1.amazonaws.com/ca.chat/images/0f0ebf1a8f8451265bc9cd1d1182aa36.jpg"' +
        '}' +
    '},' +
    '"template": {' +
       '"name": "' + templatename + '",' + 
        '"language": "en_US",' +
        '"parameters": {}' +
    '}' +
'}';

        request.setBody(body);
        
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Success: ' + response.getBody());
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

}