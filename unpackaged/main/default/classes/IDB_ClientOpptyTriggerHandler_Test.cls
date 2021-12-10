@isTest
private class IDB_ClientOpptyTriggerHandler_Test {
 @testSetup 
    static void setup(){
        //Inserting Contact  
        Contact newContact = new Contact();
        newContact.LastName = 'TestLastName';
        insert newContact;
        
        // Inserting Opportunity  
        Opportunity newOpportunity = new opportunity();
        newOpportunity.Name = 'TestOpportunity';
        newOpportunity.StageName = 'Initial Review';
        newOpportunity.CloseDate = System.today()+1;
        newOpportunity.Primary_Contact__c = newContact.Id;
        insert newOpportunity;
        
               
         Id clientProfId = [SELECT Id FROM Profile WHERE Name='IDB Invest Team Lead' LIMIT 1].Id;
        User Usr = new User(LastName = 'Client User', Alias = 'Client', Email = 'test@test.com',Username = 'usertestinvest@iadbtest.com',
                            ProfileId = clientProfId,TimeZoneSidKey = 'GMT',LanguageLocaleKey = 'en_US',EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        Insert Usr;
        
         
        User Usr2 = new User(LastName = 'Client User', Alias = 'Client', Email = 'test@test.com',Username = 'usertestinvesttl@iadbtest.com',
                            ProfileId = clientProfId,TimeZoneSidKey = 'GMT',LanguageLocaleKey = 'en_US',EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        Insert Usr2;
        
         // Inserting Opportunity Team
         OpportunityTeamMember oppTeam = new OpportunityTeamMember();
        oppTeam.OpportunityAccessLevel = 'Read';
        oppTeam.OpportunityId = newOpportunity.Id;
        oppTeam.UserId = Usr.Id;
        
        Insert oppTeam;
    }
    
    static testmethod void opptySharAccess(){
         User Usr = [SELECT Id FROM User WHERE Username='usertestinvest@iadbtest.com' LIMIT 1]; 
         User Usr2 = [SELECT Id FROM User WHERE Username='usertestinvesttl@iadbtest.com' LIMIT 1];
             Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        System.runAs(Usr){
            IDB_Client_Opportunity_Team_Member__c clntTeamMember = new IDB_Client_Opportunity_Team_Member__c();
            clntTeamMember.Opportunity__c = oppty.Id;
            clntTeamMember.Team_Role__c = Usr.Id;
            clntTeamMember.Team_Role__c = 'IDB Invest Client Team Member';
            Test.startTest();
            Insert clntTeamMember;
              try{
            IDB_Client_Opportunity_Team_Member__c clntTeamMember2 = new IDB_Client_Opportunity_Team_Member__c();
            clntTeamMember2.Opportunity__c = oppty.Id;
            clntTeamMember2.Team_Role__c = Usr.Id;
            clntTeamMember2.Team_Role__c = 'IDB Invest Client Team Member';
            Insert clntTeamMember2;
            }catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Same Client Team Member') ? true : false;
                System.assertEquals(expectedExceptionThrown, true); 
            }
            clntTeamMember.User__c = Usr2.Id;
            update clntTeamMember;
            
            delete clntTeamMember;
          
            Test.stopTest();
        }
        
    }
}