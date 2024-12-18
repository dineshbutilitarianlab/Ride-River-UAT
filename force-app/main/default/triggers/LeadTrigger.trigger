trigger LeadTrigger on Lead (After insert) {
    if(trigger.isafter && trigger.Isinsert){
        for(lead leadid:trigger.new){
            if((leadid.LeadSource=='Bike Dekho'||leadid.LeadSource=='91Wheels'||leadid.LeadSource=='Facebook'||leadid.LeadSource=='Google')&&(leadid.Dealer_Code__c=='291001'||leadid.Dealer_Code__c=='291002'||leadid.Dealer_Code__c=='292001'||leadid.Dealer_Code__c=='292002'||leadid.Dealer_Code__c=='292003'||leadid.Dealer_Code__c=='362001'||leadid.Dealer_Code__c=='332001'||leadid.Dealer_Code__c=='331001'||leadid.Dealer_Code__c=='321001'||leadid.Dealer_Code__c=='122001')){
            string mobileNO=leadid.Phone;
            WhatsAppApiCalloutHandler.leadcreationmsg(mobileNO,'new_lead_book_a_test_ride_03');
            }
            
        }
    }
    

}