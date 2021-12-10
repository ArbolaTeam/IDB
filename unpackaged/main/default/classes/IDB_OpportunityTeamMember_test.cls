/**********************************************************************************************
* Name          : IDB_OpportunityTeamMember_test 
* Author        : Alejandro Ramirez
* Description   : Test class for IDB_OpportunityTeamMember_handler
* Created Date  : 10/06/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 16/04/2021            | v1.0              | First Class version Version
*********************************************************************************************/
@isTest
public with sharing class IDB_OpportunityTeamMember_test {
    
    @TestSetup
    private static void makeData() {
        /*Create account, create contact, create opportunity*/
        Account objAccount = IDB_DataGenerator.createAccount(true);
        Contact objContact = IDB_DataGenerator.createContact(true, objAccount.id);
        IDB_DataGenerator.createOpportunity(true, objContact.id);
    }
    
    /* Method Name: onCreateTeamMemberA
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member is going to be created in the opportunity without DCIs and without team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberA() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        Test.startTest();
            OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            insert objOTMdummy;
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onCreateTeamMemberB
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Leader is going to be created in the opportunity without DCIs and without team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberB() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        Test.startTest();
            OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onCreateTeamMemberC
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Leader is going to be created in the opportunity without DCIs and with team members(No leaders) already existing
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberC() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        System.assertNotEquals(null, objDummyUser);
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy;
        Test.startTest();
            OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy2.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onCreateTeamMemberD
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Leader is going to be created in the opportunity without DCIs and with team members(leaders) already existing
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberD() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        System.assertNotEquals(null, objDummyUser);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        Test.startTest();
            OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy2.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onCreateTeamMemberE
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Leader is going to be created in the opportunity with DCIs(with Contains DCII = false) and with team members(leaders) already existing
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberE() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        System.assertNotEquals(null, objDummyUser);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        Test.startTest();
            OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy2.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onCreateTeamMemberF
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Leader is going to be created in the opportunity with DCIs(with Contains DCII = false) and without team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onCreateTeamMemberF() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        System.assertNotEquals(null, objDummyUser2);
        Test.startTest();
            OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
            OpportunityTeamMember objOTMResult = [SELECT Id FROM OpportunityTeamMember WHERE Id =: objOTMdummy2.Id];
            System.assertNotEquals(null, objOTMResult);
		Test.stopTest();
    }

    /* Method Name: onUpdateTeamMemberA
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM without DCIs and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onUpdateTeamMemberA() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
		Test.stopTest();
    }

    /* Method Name: onUpdateTeamMemberB
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM without DCIs and with existing 
    *              team members(No Leaders)
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onUpdateTeamMemberB() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser2.Id);
        objOTMdummy2.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy2;
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
		Test.stopTest();
    }

    /* Method Name: onUpdateTeamMemberC
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM without DCIs and with existing 
    *              team members(Leaders)
    * Parameters: None
    * Returns: NONE
    *//*
    @isTest
    private static void onUpdateTeamMemberC() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
		Test.stopTest();
    }*/

    /* Method Name: onUpdateTeamMemberD
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM with DCIs(contains PII = false)
    *           and with existing team members(No Leaders)
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onUpdateTeamMemberD() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser2.Id);
        objOTMdummy2.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy2;
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
		Test.stopTest();
    }

    /* Method Name: onUpdateTeamMemberE
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM with DCIs(contains PII = false)
    *              and with existing team members(Leaders). This method also updates roles viceversa to have more code coverage
    * Parameters: None
    * Returns: NONE
    *//*
    @isTest
    private static void onUpdateTeamMemberE() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Investment Officer';
            update objOTMdummy2;
            System.assertEquals('Investment Officer', objOTMdummy2.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Team Leader';
            update objOTMdummy2;
            System.assertEquals('Team Leader', objOTMdummy2.TeamMemberRole);
		Test.stopTest();
    }*/

    /* Method Name: onUpdateTeamMemberF
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM with DCIs(contains PII = true)
    *           and with existing team members(No Leaders). This method also updates roles viceversa to have more code coverage
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onUpdateTeamMemberF() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser2.Id);
        objOTMdummy2.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy2;
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Investment Officer';
            update objOTMdummy2;
            System.assertEquals('Investment Officer', objOTMdummy2.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Team Leader';
            update objOTMdummy2;
            System.assertEquals('Team Leader', objOTMdummy2.TeamMemberRole);
		Test.stopTest();
    }

    /* Method Name: onUpdateTeamMemberG
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM with DCIs(contains PII = true)
    *              and with existing team members(Leaders). This method also updates roles viceversa to have more code coverage
    * Parameters: None
    * Returns: NONE
    *//*
    @isTest
    private static void onUpdateTeamMemberG() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
    
        Test.startTest();
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Investment Officer';
            update objOTMdummy;
            System.assertEquals('Investment Officer', objOTMdummy.TeamMemberRole);
            objOTMdummy.TeamMemberRole = 'Team Leader';
            update objOTMdummy;
            System.assertEquals('Team Leader', objOTMdummy.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Investment Officer';
            update objOTMdummy2;
            System.assertEquals('Investment Officer', objOTMdummy2.TeamMemberRole);
            objOTMdummy2.TeamMemberRole = 'Team Leader';
            update objOTMdummy2;
            System.assertEquals('Team Leader', objOTMdummy2.TeamMemberRole);
		Test.stopTest();
    }*/

    /* Method Name: onUpdateTeamMemberH
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(leader) is going to be updated of role in the OTM with DCIs(contains PII = true)
    *              and with existing team members(Leaders). This method also updates roles viceversa to have more code coverage
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onUpdateTeamMemberH() {
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.IDB_Is_First_Team_Lead__c = true;
        insert objOTMdummy;
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser2.Id);
        objOTMdummy2.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy2;
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        objDummyDCI.OwnerId = objOTMdummy.UserId;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
    
        Test.startTest();
            objOTMdummy2.TeamMemberRole = 'Team Leader';
            update objOTMdummy2;
            System.assertEquals('Team Leader', objOTMdummy2.TeamMemberRole);
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberA
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(Leader) is going to be deleted in the opportunity without DCIs and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberA() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
            
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberB
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(No Leader) is going to be deleted in the opportunity without DCIs and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberB() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy;
    
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberC
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(Leader) is going to be deleted in the opportunity with DCIs and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberC() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
            
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberD
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(No Leader) is going to be deleted in the opportunity with DCIs and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberD() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy;
    
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberE
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(Leader) is going to be deleted in the opportunity with DCIs(Contains PII = true) and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberE() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
            
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberF
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(No Leader) is going to be deleted in the opportunity with DCIs(Contains PII = true) and without existing team members
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberF() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(false, objDummyOpportunity.Id, objDummyUser.Id);
        objOTMdummy.TeamMemberRole = 'Investment Officer';
        insert objOTMdummy;
    
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberG
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(Leader) is going to be deleted in the opportunity with DCIs(Contains PII = true)
    *              and with existing team members. This method also plays with different actions to have more code coverage
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberG() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        objDummyDCI.Contains_PII__c = true;
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);

        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    /* Method Name: onDeleteTeamMemberH
    * Author Name: Alejandro Ramirez
    * Description: method to test when a Team Member(Leader) is going to be deleted in the opportunity with DCIs(Contains PII = true)
    *              and with existing team members. This method also plays with different actions to have more code coverage
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void onDeleteTeamMemberH() {
        //Users for TeamMembers
        User objDummyUser = IDB_DataGenerator.createDummyUser(true);
        System.assertNotEquals(null, objDummyUser);
        User objDummyUser2 = IDB_DataGenerator.createCustomDummyUser(true, '2');
        //Opportunity
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        //DCIs for the opportunity
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI.Status__c = 'New';
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'New';
        insert objDummyDCI2;
        //it comes as a team leader
        OpportunityTeamMember objOTMdummy = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser.Id);
        objDummyDCI.Contains_PII__c = true;
        objDummyDCI.OwnerId = objOTMdummy.UserId;
        update objDummyDCI;
        OpportunityTeamMember objOTMdummy2 = IDB_DataGenerator.createOpportunityTeamMember(true, objDummyOpportunity.Id, objDummyUser2.Id);
        objOTMdummy2.IDB_Is_First_Team_Lead__c = false;
        update objOTMdummy2;
        Test.startTest();
            delete objOTMdummy;
            List<OpportunityTeamMember> objOTMResult = [SELECT id FROM OpportunityTeamMember WHERE Id =: objOTMdummy.id];
            System.assertEquals(0, objOTMResult.size());
		Test.stopTest();
    }

    
}