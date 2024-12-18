@istest
public class homecontrollertest {
  @istest
    public static void getLeadsListtest(){
      
        lead l=new lead();
        l.LastName='test1234';
        l.FirstName='test';
        l.Salutation='Mr.';
        l.LeadSource='BikeWale';
        l.Phone='8373879087';
        l.Company='tcs';
           l.City='test';
        l.Country='India';
        l.State='Bihar';
        l.Street='test';
        l.PostalCode='test';
        Insert l;
        Test_Drive__c td=new Test_Drive__c();
        td.Lead__c=l.Id;
        td.Name=l.LastName;
        td.Drivers_License_Number__c='AB1234567890123';
        td.Test_ride_executive_s_Name__c='testexcutive';
       
        insert td;
 DateTime testDateTime = DateTime.newInstance(2023, 10, 6, 12, 0, 0);
         DateTime testDateTime1 = DateTime.newInstance(2023, 10, 7, 12, 0, 0);
        Follow_Up__c f=new Follow_Up__c();
        f.Lead__c=l.Id;
        f.Status__c='In Progress';
        f.Follow_Up_Date__c=testDateTime;
        f.Name=l.LastName;
        Insert f;
        homecontroller.getLeadsList('test');
        homecontroller.getLeads();
        homecontroller.getLeaddeatails(l.Id);
        homecontroller.updatelead(l.Id,'BikeWale','9827739327',34,'test@gmail.com','test','India','0000000','Bihar','test','New','test');
        homecontroller.bookingid(l.Id,'000000000');
        homecontroller.createnewfollowup(l.Id,testDateTime1,'bcbvhgvfgfvchb');
        homecontroller.createnewfollowuptestride(l.Id,testDateTime1,'bcbvhgvfgfvchb');
        homecontroller.createstoreride(l.Id,'test',testDateTime);
         homecontroller.createhomeride(l.Id,'test',testDateTime,'test','test','Bihar','India','test');
        homecontroller.leadcancelreason(l.Id,'Others','tset');
        homecontroller.updatefollowup(f.Id);
        homecontroller.updatedltestride(td.Id,'Ka1234567890123',true);
         homecontroller.updatedstatustestridecomplete(td.Id);
        homecontroller.updatedstatustestride(td.Id);
                homecontroller.updatedtestdrivefeedback(td.Id,'testing');
                        homecontroller.newgetLeadsList('test');



    }
   
    
    

}