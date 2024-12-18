trigger TestDriveTrigger on Test_Drive__c (before insert, after insert) {
    
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
}