/**********************************************************************************************
* Name          : IDB_DataGenerator 
* Author        : Alejandro Ramirez
* Description   : Class to generate dummy data to use in test classes
* Created Date  : 16/04/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 16/04/2021            | v1.0              | First Class version Version
Alejandro Ramirez       | 19/05/2021            | v1.1              | Adding methods to generate dummy files
*********************************************************************************************/
public with sharing class IDB_DataGenerator {
    public static Account objAccount;
    public static Contact objContact;
    public static Opportunity objOpportunity;
    public static Document_Checklist_Item__c objDocCI;

    /* Method Name: createAccount
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Account
    * Parameters: boolean isInsert
    * Returns: Account
    */
    public static Account createAccount(boolean isInsert) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
        objAccount = new Account();
        objAccount.Name = 'Dummy Banco Agricola S.A. 10';
        objAccount.recordTypeId = recordTypeId;

        if(isInsert) {
            insert objAccount;
        }
        return objAccount; 
    }

    /* Method Name: createContact
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Contact
    * Parameters: boolean isInsert
    * Returns: Contact
    */
    public static Contact createContact(boolean isInsert, Id accountIdIn) {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        objContact = new Contact();
        objContact.FirstName = 'Dummy Max';
        objContact.LastName = 'Philiph';
        objContact.recordTypeId = recordTypeId;
        objContact.AccountId = (accountIdIn != null) ? accountIdIn : null;

        if(isInsert) {
            insert objContact;
        }
        return objContact; 
    }

    /* Method Name: createOpportunity
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Opportunity
    * Parameters: boolean isInsert
    * Returns: Opportunity
    */
    public static Opportunity createOpportunity(boolean isInsert, Id contactIdIn) {
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity (Wallet Share)').getRecordTypeId();
        objOpportunity = new Opportunity();
        objOpportunity.Name = 'Dummy Banco Agricola S.A. - TFFP (ES-L1031)';
        objOpportunity.recordTypeId = recordTypeId;
        objOpportunity.StageName = 'Initial Review';
        objOpportunity.CloseDate = System.today();
        objOpportunity.Primary_Contact__c = contactIdIn;

        if(isInsert) {
            insert objOpportunity;
        }
        return objOpportunity; 
    }

    /* Method Name: createDocumentChecklistItem
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy DocumentChecklistItem
    * Parameters: boolean isInsert
    * Returns: Document_Checklist_Item__c
    */
    public static Document_Checklist_Item__c createDocumentChecklistItem(boolean isInsert, Id opportunityIdIn) {
        Id recordTypeId = Schema.SObjectType.Document_Checklist_Item__c.getRecordTypeInfosByName().get('Documents').getRecordTypeId();
        objDocCI = new Document_Checklist_Item__c();
        objDocCI.Name = 'Dummy Insurance Policy';
        objDocCI.recordTypeId = recordTypeId;
        objDocCI.Opportunity__c = opportunityIdIn;
        objDocCI.Section__c = 'Initial Review';
        objDocCI.IDB_Team_Role__c = 'Team Leader';
        objDocCI.Status__c = 'Published';
        objDocCI.Description__c = 'Dummy Description';

        if(isInsert) {
            insert objDocCI;
        }
        return objDocCI; 
    }

    /* Method Name: createContentVersion
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy ContentVersion
    * Parameters: boolean isInsert, String strToConcat
    * Returns: ContentVersion
    */
    public static ContentVersion createContentVersion(boolean isInsert, String strToConcat) {
        ContentVersion objContentVersion = new ContentVersion(
            Title = 'Dummy Penguins ' + strToConcat,
            PathOnClient = 'DummyPenguins' + strToConcat + '.jpg',
            VersionData = Blob.valueOf('Test Content ' + strToConcat),
            IsMajorVersion = true
        );
        if(isInsert) {
            insert objContentVersion;
        }
        return objContentVersion;
    }

    /* Method Name: createContentDocumentLink
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy ContentVersion
    * Parameters: boolean isInsert, String strToConcat
    * Returns: ContentVersion
    */
    public static ContentDocumentLink createContentDocumentLink(boolean isInsert, Id linkedEntityId, Id contentDocumentId) {
        ContentDocumentLink objContentDocLink = New ContentDocumentLink();
        objContentDocLink.LinkedEntityId = linkedEntityId;
        objContentDocLink.ContentDocumentId = contentDocumentId;
        objContentDocLink.shareType = 'V';
        if(isInsert) {
            insert objContentDocLink;
        }
        return objContentDocLink;
    }

    /* Method Name: createOpportunityTeamMember
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Opportunity team members
    * Parameters: boolean isInsert, Id oppId, Id usrId
    * Returns: OpportunityTeamMember
    */
    public static OpportunityTeamMember createOpportunityTeamMember(boolean isInsert, Id oppId, Id usrId) {
        OpportunityTeamMember objOTMtoReturn =  new OpportunityTeamMember();
        objOTMtoReturn.OpportunityId = oppId;
        objOTMtoReturn.UserId = usrId;
        objOTMtoReturn.TeamMemberRole = 'Team Leader';
        objOTMtoReturn.OpportunityAccessLevel = 'read'; 
        
        if(isInsert) {
            insert objOTMtoReturn;
        }
        return objOTMtoReturn;
    }

    /* Method Name: createDummyUser
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Users
    * Parameters: boolean isInsert
    * Returns: User
    */
    public static User createDummyUser(boolean isInsert) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Profile objProfile = [SELECT ID FROM Profile Where Name = 'IDB Invest Business Admin'];
        //[TimeZoneSidKey]
        User objDummyUser = new User(
            alias = 'dummTst',
            LastName = 'DummyTest',
            Username = uniqueName + '@test' + orgId + '.org',
            email = 'TstDmmy@test.com',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Chicago',
            ProfileId = objProfile.Id
        );
        if(isInsert) {
            insert objDummyUser;
        }
        return objDummyUser;
    }

    /* Method Name: createCustomDummyUser
    * Author Name: Alejandro Ramirez
    * Description: Method to create dummy Users
    * Parameters: boolean isInsert
    * Returns: User
    */
    public static User createCustomDummyUser(boolean isInsert, String strConcat) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        Profile objProfile = [SELECT ID FROM Profile Where Name = 'IDB Invest Business Admin'];
        //[TimeZoneSidKey]
        User objDummyUser = new User(
            alias = 'dumm' + strConcat,
            LastName = 'Dummy' + strConcat,
            Username = uniqueName + '@test' + orgId + '.org',
            email = 'Tst' +  + strConcat + 'Dmmy@test.com',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Chicago',
            ProfileId = objProfile.Id
        );
        if(isInsert) {
            insert objDummyUser;
        }
        return objDummyUser;
    }
}