/**********************************************************************************************
* Name          : IDB_SendDCIsActivityReminderToPC_test 
* Author        : Alejandro Ramirez
* Description   : Test class for IDB_SendDCIsActivityReminderToPC_batch
* Created Date  : 24/05/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 24/05/2021            | v1.0              | First Class version Version
*********************************************************************************************/
@isTest
public class IDB_SendDCIsActivityReminderToPC_test {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    /* Method Name: makeData
    * Author Name: Alejandro Ramirez
    * Description: Method to generate dummy data
    * Parameters: None
    * Returns: NONE
    */
    @TestSetup
    private static void makeData() {
        /*Create account, create contact, create opportunity*/
        Account objAccount = IDB_DataGenerator.createAccount(true);
        Contact objContact = IDB_DataGenerator.createContact(false, objAccount.id);
        objContact.email = 'testdummy@test.com';
        insert objContact;
        IDB_DataGenerator.createOpportunity(true, objContact.id);
    }

    /* Method Name: testSendApprovalDCIReminderBatch
    * Author Name: Alejandro Ramirez
    * Description: Method to test IDB_SendApprovalDCIReminder_batch.
    * Parameters: None
    * Returns: NONE
    */
    @isTest
    private static void testDCIsActivityReminderBatch() {
        Opportunity objDummyOpportunity = [SELECT id, Name, StageName, CloseDate FROM Opportunity WHERE Name LIKE '%Dummy%' LIMIT 1];
        System.assertNotEquals(null, objDummyOpportunity);
        Document_Checklist_Item__c objDummyDCI = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
		objDummyDCI.Status__c = 'Published';
        objDummyDCI.IDB_Next_Reminder_Date__c = System.today();
        objDummyDCI.IDB_Submitted_Date__c = System.today();
        insert objDummyDCI;
        Document_Checklist_Item__c objDummyDCI2 = IDB_DataGenerator.createDocumentChecklistItem(false, objDummyOpportunity.Id);
        objDummyDCI2.Name = 'Dummy Insurance Policy 2';
        objDummyDCI2.Status__c = 'Rejected';
        objDummyDCI2.IDB_Next_Reminder_Date__c = System.today();
        objDummyDCI2.IDB_Submitted_Date__c = System.today();
        objDummyDCI2.IDB_Next_Reminder_to_PC_Date__c = System.today();
        insert objDummyDCI2;
        
        Test.startTest();
            IDB_SendDCIsActivityReminderToPC_batch objSendDCIsActivityReminderBatch = new IDB_SendDCIsActivityReminderToPC_batch();
            Database.executeBatch(objSendDCIsActivityReminderBatch);
		Test.stopTest();
        System.AssertEquals(
           database.countquery('SELECT COUNT()'
              +' FROM Document_Checklist_Item__c WHERE Opportunity__c = \'' + objDummyOpportunity.Id + '\''),
           2); 
	}
}