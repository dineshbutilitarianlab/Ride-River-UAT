trigger TestDriveTrigger on Test_Drive__c (before insert, after insert,after Update) {
    
    if(Trigger.isBefore){
        
        for(Test_Drive__c td : trigger.new){
                      
            td.Name = td.LeadName__c +'- Test Drive';
        }
       
        
    }
   /* if(Trigger.isAfter){
        Set<Id> leadIds = new Set<Id>();
        for(Test_Drive__c td : trigger.new){
            if (td.Lead__c != null) {
                leadIds.add(td.Lead__c);
            }
        }
        if(!leadIds.isEmpty()){
            List<Lead> llist1 = new List<Lead>();
            List<Lead> llist = [select id,status from lead where id =:leadIds];
            for(Lead l :llist){
                l.Status = 'Test Ride';
                llist1.add(l);
            }
            if(!llist1.isEmpty()){
                update llist1;
            }
        }
    }*/
    if(trigger.Isafter && trigger.Isupdate){
        for(Test_Drive__c Td:trigger.new){
                      Test_Drive__c statusoldvalueId = (Test_Drive__c)Trigger.oldMap.get(Td.Id);
           string statusoldvalue=statusoldvalueId.Test_Drive_Status__c;
            if(Td.Test_Drive_Status__c!=statusoldvalue &&Td.Test_Drive_Status__c=='Canceled'){
            
            Lead leadid=[select Id ,Phone,Lead_Dealer_Code__c,LeadSource from Lead Where Id=:Td.Lead__c];
                            if((leadid.LeadSource!='OzoneTel WhatsApp')&&(leadid.Lead_Dealer_Code__c=='291001'||leadid.Lead_Dealer_Code__c=='291002'||leadid.Lead_Dealer_Code__c=='292001'||leadid.Lead_Dealer_Code__c=='292002'||leadid.Lead_Dealer_Code__c=='292003'||leadid.Lead_Dealer_Code__c=='362001'||leadid.Lead_Dealer_Code__c=='332001'||leadid.Lead_Dealer_Code__c=='331001'||leadid.Lead_Dealer_Code__c=='321001'||leadid.Lead_Dealer_Code__c=='122001')){

                TestRidewhatsappmsgcallout.TestRidewhatsappmsgcalloutfuthermethod(leadid.Phone);
                            }
            }
        }
    }
    if(trigger.isafter && trigger.isInsert){
        for(Test_Drive__c td:trigger.new){
            
             Lead leadid=[select Id ,Phone,Lead_Dealer_Code__c,LeadSource from Lead Where Id=:Td.Lead__c];
                            if((leadid.LeadSource!='OzoneTel WhatsApp')&&(leadid.Lead_Dealer_Code__c=='291001'||leadid.Lead_Dealer_Code__c=='291002'||leadid.Lead_Dealer_Code__c=='292001'||leadid.Lead_Dealer_Code__c=='292002'||leadid.Lead_Dealer_Code__c=='292003'||leadid.Lead_Dealer_Code__c=='362001'||leadid.Lead_Dealer_Code__c=='332001'||leadid.Lead_Dealer_Code__c=='331001'||leadid.Lead_Dealer_Code__c=='321001'||leadid.Lead_Dealer_Code__c=='122001')){
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
Datetime dateTimeString = Td.Test_Ride_Date__c;
Datetime dt = Datetime.valueOf(dateTimeString);
String formattedTime = dt.format('dd/MM/yyyy');
System.debug('Time in AM/PM format: ' + formattedTime);
                                string ridetypevalue;
                                if(td.Ride_Type__c=='Home Ride'){
                                    ridetypevalue='the comfort of your home';
                                }else if(td.Ride_Type__c=='Store Ride'){
                                    ridetypevalue=storeMap.get(leadid.Lead_Dealer_Code__c);
                                    
                                }
               TestRideCreateWhatsappmsgcallout.TestRideCreateWhatsappmsgcalloutfuthermethod(leadid.Phone,formattedTime,ridetypevalue);
                            }
        }
    }
}