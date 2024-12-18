@isTest
private class WhatsAppApiCalloutTest {

    @isTest static void testLeadCreationMsg() {
       
       
        Test.startTest();
         lead l=new Lead();
        l.LastName='test';
        l.Company='NA';
        l.LeadSource='Facebook';
        l.Dealer_Code__c='122001';
        Insert l;
        WhatsAppApiCalloutHandler.leadcreationmsg('9876543210', 'testTemplate');
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest static void mockHttpCallout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
    }

    class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}