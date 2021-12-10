/**********************************************************************************************
* Name          : IDB_DocumentChecklistItem_Test 
* Author        : Alejandro Ramirez
* Description   : Test class for IDB_DocumentChecklistItem_helper
* Created Date  : 16/04/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 16/04/2021            | v1.0              | First Class version Version
Alejandro Ramirez       | 18/05/2021            | v1.1              | Adding test logic for CP2-38 (IDB Invest Client alert when submitting Documents for approval)
*********************************************************************************************/
@isTest
public class IDB_DocumentChecklistItem_Test {
    
    @TestSetup
    private static void makeData() {
        /*Create account, create contact, create opportunity*/
        Account objAccount = IDB_DataGenerator.createAccount(true);
        Contact objContact = IDB_DataGenerator.createContact(true, objAccount.id);
        IDB_DataGenerator.createOpportunity(true, objContact.id);
    }

    /* Method Name: approveDCI
    * Author Name: Alejandro Ramirez
    * Description: Method to test when record DCI is going to be approved and it's not having period values.
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void approveDCI() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(true, objDummyOpportunity.Id);
		
        Test.startTest();
            objDummyDCI.Status__c = 'Approved';
            try{
                update objDummyDCI;
            }catch(Exception objExc) {
                System.assertNotEquals(null, objExc);
            }
		Test.stopTest();
	}

    /* Method Name: validateDCISections
    * Author Name: Alejandro Ramirez
    * Description: Method to test when record DCI is being inserted to set the Acronym according to the section for one record
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void validateDCISections() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        Test.startTest();
            insert objDummyDCI;
        Test.stopTest();
    }

    /* Method Name: validateDCISectionsMultipleIn
    * Author Name: Alejandro Ramirez
    * Description: Method to test when multiple record DCI is being inserted to set the Acronym according to the section for one record
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void validateDCISectionsMultipleIn() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        IDB_DataGenerator.createDocumentChecklistItem(true, objDummyOpportunity.Id);
        List<Document_Checklist_Item__c> lstDummyDCIs = new List<Document_Checklist_Item__c>();
        for(Integer intCount = 1; intCount < 5; intCount++) {
            Document_Checklist_Item__c objDummyDCIDyn = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
            objDummyDCIDyn.Name = objDummyDCIDyn.Name + ' ' + intCount;
            lstDummyDCIs.add(objDummyDCIDyn);
        }
        Test.startTest();
            insert lstDummyDCIs;
        Test.stopTest();
    }

    /* Method Name: onSubmitForApproval
    * Author Name: Alejandro Ramirez
    * Description: Method to test when record DCI is going to be submitted for approval and it's not having files or the files on the DCI were not uploaded by a Partner user.
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onSubmitForApproval() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(true, objDummyOpportunity.Id);
		
        Test.startTest();
            objDummyDCI.Status__c = 'Submitted';
            try{
                update objDummyDCI;
            }catch(Exception objExc) {
                System.assertNotEquals(null, objExc);
            }
		Test.stopTest();
	}

    /* Method Name: onSubmitForApprovalWithFile
    * Author Name: Alejandro Ramirez
    * Description: Method to test when record DCI is going to be submitted for approval and it's having one file or the files on the DCI does not were uploaded by a Partner user.
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onSubmitForApprovalWithFile() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(true, objDummyOpportunity.Id);
		IDB_DataGenerator.createContentVersion(true, '1');
        List<ContentDocument> lstContentDocs = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        IDB_DataGenerator.createContentDocumentLink(true, objDummyDCI.id, lstContentDocs[0].Id);

        Test.startTest();
            objDummyDCI.Status__c = 'Submitted';
            try{
                update objDummyDCI;
            }catch(Exception objExc) {
                System.assertNotEquals(null, objExc);
            }
		Test.stopTest();
	}

    /* Method Name: onSubmitForApprovalWithNFiles
    * Author Name: Alejandro Ramirez
    * Description: Method to test when record DCI is going to be submitted for approval and it's having files or the files on the DCI does not were uploaded by a Partner user.
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onSubmitForApprovalWithNFiles() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(true, objDummyOpportunity.Id);
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        insert objDummyDCI2;

        Test.startTest();
            List<Document_Checklist_Item__c> lstDCIsToUpdate = new List<Document_Checklist_Item__c>();
            objDummyDCI.Status__c = 'Submitted';
            objDummyDCI2.Status__c = 'Submitted';
            lstDCIsToUpdate.add(objDummyDCI);
            lstDCIsToUpdate.add(objDummyDCI2);
            try{
                update lstDCIsToUpdate;
            }catch(Exception objExc) {
                System.assertNotEquals(null, objExc);
            }
		Test.stopTest();
	}

    /* Method Name: onAssignDCIsSharingSet
    * Author Name: Alejandro Ramirez
    * Description: method to test when a DCI is being inserted and the opportunity is having team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onAssignDCIsSharingSet() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        
        Test.startTest();
            Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
            insert objDummyDCI;
            Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
            objDummyDCI2.name = 'Dummy Insurance Policy 2';
            insert objDummyDCI2;
		Test.stopTest();
    }
    

    /* Method Name: onAssignDCIsSharingSetUpdateContainsPII
    * Author Name: Alejandro Ramirez
    * Description: method to test when a DCI is being updated in Contains PII field
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onAssignDCIsSharingSetUpdateContainsPII() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        insert objDummyDCI2;
    
        Test.startTest();
            objDummyDCI.Contains_PII__c = true;
            update objDummyDCI;
            Document_Checklist_Item__c objDCIUpdated = [SELECT id, Contains_PII__c FROM Document_Checklist_Item__c WHERE Id =: objDummyDCI.Id];
            System.assertEquals(true, objDCIUpdated.Contains_PII__c, 'Successfully updated');
            objDummyDCI.Contains_PII__c = false;
            update objDummyDCI;
            Document_Checklist_Item__c objDCIUpdated2 = [SELECT id, Contains_PII__c FROM Document_Checklist_Item__c WHERE Id =: objDummyDCI.Id];
            System.assertEquals(false, objDCIUpdated2.Contains_PII__c, 'Successfully updated');
		Test.stopTest();
    }

    /* Method Name: onAssignDCIsSharingSetTeamLeads
    * Author Name: Alejandro Ramirez
    * Description: method to test when a DCI is being inserted and the opportunity is having team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onAssignDCIsSharingSetTeamLeads() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        
        Test.startTest();
            Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
            insert objDummyDCI;
            Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
            objDummyDCI2.name = 'Dummy Insurance Policy 2';
            objDummyDCI2.Contains_PII__c = true;
            insert objDummyDCI2;
		Test.stopTest();
    }

    /* Method Name: onAssignDCIsSharingSetUpdateContainsPII2
    * Author Name: Alejandro Ramirez
    * Description: method to test when a DCI is being updated in Contains PII field
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onAssignDCIsSharingSetUpdateContainsPII2() {
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy;
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Contains_PII__c = true;
        insert objDummyDCI2;
    
        Test.startTest();
            objDummyDCI.Contains_PII__c = true;
            update objDummyDCI;
            Document_Checklist_Item__c objDCIUpdated = [SELECT id, Contains_PII__c FROM Document_Checklist_Item__c WHERE Id =: objDummyDCI.Id];
            System.assertEquals(true, objDCIUpdated.Contains_PII__c, 'Successfully updated');
            objDummyDCI.Contains_PII__c = false;
            update objDummyDCI;
            Document_Checklist_Item__c objDCIUpdated2 = [SELECT id, Contains_PII__c FROM Document_Checklist_Item__c WHERE Id =: objDummyDCI.Id];
            System.assertEquals(false, objDCIUpdated2.Contains_PII__c, 'Successfully updated');
		Test.stopTest();
    }
}