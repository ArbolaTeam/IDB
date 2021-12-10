@isTest
private class IDB_ContentDocuLinkTriggerHandler_Test {
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
        
        // Inserting Opportunity Team        
         Id clientProfId = [SELECT Id FROM Profile WHERE Name='IDB Invest Team Lead' LIMIT 1].Id;
        User Usr = new User(LastName = 'Client User', Alias = 'Client', Email = 'test@test.com',Username = 'usertestinvest@iadbtest.com',
                            ProfileId = clientProfId,TimeZoneSidKey = 'GMT',LanguageLocaleKey = 'en_US',EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        Insert Usr;
        
        OpportunityTeamMember oppTeam = new OpportunityTeamMember();
        oppTeam.OpportunityAccessLevel = 'Read';
        oppTeam.OpportunityId = newOpportunity.Id;
        oppTeam.UserId = Usr.Id;
        
        Insert oppTeam;
        
        // Inserting Document Checklist Item  
        Document_Checklist_Item__c newDCI = new Document_Checklist_Item__c();
        newDCI.Opportunity__c= newOpportunity.Id;
        newDCI.Description__c = 'Test Document Checklist Item';
        newDCI.Section__c= 'Initial Review';
        newDCI.Status__c= 'Approved';
        newDCI.IDB_Team_Role__c = 'Investment Officer';
        newDCI.Period__c = '2021';        
        insert newDCI;
    }
    
     static testmethod void validationRestrictionMethod(){
     
        User Usr = [SELECT Id FROM User WHERE Username='usertestinvest@iadbtest.com' LIMIT 1];
        System.runAs(Usr){
            Document_Checklist_Item__c newDCI = [SELECT Id FROM Document_Checklist_Item__c LIMIT 1];
            
            
               // Creating Content Document  
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        Approval.lock(newDCI.Id);
            Test.startTest();
            try{
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = newDCI.Id;
        cdl.ContentDocumentId = conDocId;
        //cdl.shareType = 'V';
        Insert cdl;
            }catch(Exception e){
                 Boolean expectedExceptionThrown =  e.getMessage().contains('File cannot be uploaded') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
             Test.stopTest();
        }
     }
}