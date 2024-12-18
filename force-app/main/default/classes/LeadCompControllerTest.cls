@istest
public class LeadCompControllerTest {
    @istest
    public static void LeadCompControllertest(){
         lead l=new lead();
        l.LastName='test1234';
        l.FirstName='test';
        l.Salutation='Mr.';
        l.LeadSource='BikeWale';
        l.Phone='8373879087';
        l.Company='tcs';
           l.City='KA';
        l.Country='India';
        l.State='Karnataka';
        l.Street='test';
        l.PostalCode='560036';
        Insert l;
DateTime nowDateTime = DateTime.now();
        Follow_Up__c f=new Follow_Up__c();
        f.Lead__c=l.Id;
        f.Status__c='In Progress';
        f.Follow_Up_Date__c=nowDateTime;
        f.Name=l.LastName;
        Insert f;
       
       /* Vehicle ve=new Vehicle();
        ve.Name='test';
        ve.Charger_PC_Number__c='23456';
        ve.VehicleIdentificationNumber='AP30246526';
        ve.VehicleDefinitionId='1PqIp0000004C9DKAU';
        ve.AssetId='02iIp0000001qXuIAI';
        insert ve;*/
        Test_Drive__c td=new Test_Drive__c();
        td.Lead__c=l.Id;
        td.Name=l.LastName;
        td.Test_Drive_Date__c=nowDateTime;
        td.Drivers_License_Number__c='AB1234567890123';
        td.Test_ride_executive_s_Name__c='testexcutive';
        td.Test_Drive_Status__c='Scheduled';
        insert td;
        LeadCompController.TodaysFollowUp();
      LeadCompController.getLeads();
        LeadCompController.getLeadsList('test');
        LeadCompController.getLeaddeatails(l.Id);
       // LeadCompController.getVehicleOptions();
       // LeadCompController.createtestdrive('test',nowDateTime,l.Id,'Home Ride');
        //LeadCompController.createfollowup('test', l.Id);
        LeadCompController.updatelead(l.id, l.LeadSource, '1234567890', 43, 'test@gmail.com', 'test', 'India', '1234556', 'Karnataka', 'test', 'New','test');
        LeadCompController.followupfeedback(f.Id,'idjnfdnfndkf');
       // LeadCompController.newfollowup(l.Id,'test',nowDateTime,f.Id,'testing');
       LeadCompController.getTestDriveRecords();
        LeadCompController.rescheduledate(nowDateTime,td.Id,'Home Ride');
        LeadCompController.updateLeadStatus(l.Id);
        LeadCompController.leadstatuscancel(td.Id,'testing');
        LeadCompController.leadstatuscomplete(td.Id,'testing');
             LeadCompController.getPreviousfollowUp(f.Id);
            LeadCompController.createnewfollowup(td.Id,l.Id,nowDateTime,'testing');
                    LeadCompController.newgetLeads();
        LeadCompController.NotAttendedtestdrives();
        LeadCompController.createnewfollowupFromFollowup(f.Id,l.Id,nowDateTime,'testing');
                LeadCompController.NotAttendedfllowups();
                LeadCompController.summarrywrappersetcount();


        

        

    }

}