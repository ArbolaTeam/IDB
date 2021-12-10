/**********************************************************************************************
* Name          : IDB_SendApprovalDCIReminder_batch 
* Author        : Alejandro Ramirez
* Description   : Batch class to send email notification reminder to users who has not approve/reject a submitted DCI record
* Created Date  : 20/05/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 20/05/2021            | v1.0              | First Class version Version
*********************************************************************************************/
global class IDB_SendApprovalDCIReminder_batch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        Datetime dtToday = System.now();
        Integer intDay = dtToday.day();
        integer intMonth = dtToday.month();
        integer intYear = dtToday.year();
        String strQuery = 'SELECT Id, name, IDB_Approver__c, IDB_Approver__r.Email, IDB_Approver__r.Name, Opportunity__r.Name, IDB_Transaction_Id_of_Maestro__c, IDB_Submitted_Date__c, IDB_Next_Reminder_Date__c FROM Document_Checklist_Item__c WHERE Status__c = \'Submitted\' AND DAY_IN_MONTH(IDB_Next_Reminder_Date__c) = ' + intDay + ' AND CALENDAR_MONTH(IDB_Next_Reminder_Date__c) = ' + intMonth + ' AND CALENDAR_YEAR(IDB_Next_Reminder_Date__c) = ' + intYear;
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Document_Checklist_Item__c> lstDCIs) {
        // process each batch of records
        if(!lstDCIs.isEmpty()) {
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            for(Document_Checklist_Item__c objCurrDCI : lstDCIs) {
                List<String> lstApproverEmail = new List<String>{objCurrDCI.IDB_Approver__r.Email};
                String strRecordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+objCurrDCI.Id;
                lstMails.add(prepareEmail(lstApproverEmail, objCurrDCI.IDB_Approver__r.Name, objCurrDCI.Name, objCurrDCI.Opportunity__r.Name, objCurrDCI.IDB_Transaction_Id_of_Maestro__c, strRecordlink));
                objCurrDCI.IDB_Next_Reminder_Date__c = system.today().addDays(15);
            }
            Messaging.sendEmail(lstMails);
            try{
                update lstDCIs;
            }catch(Exception objExc) {
                System.debug('The next error has occurred::: ' + objExc.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

    /* Method Name: prepareEmail
    * Author Name: Alejandro Ramirez
    * Description: Method to prepare each single email for each DCI
    * Parameters: List<String> lstApproverEmail, String strApproverName, String strDCIName, String strOppName, String strTransactionId, String strRecordlink
    * Returns: Messaging.SingleEmailMessage
    */
    public Messaging.SingleEmailMessage prepareEmail(List<String> lstApproverEmail, String strApproverName, String strDCIName, String strOppName, String strTransactionId, String strRecordlink) {
        Messaging.SingleEmailMessage objSingleMail = new Messaging.SingleEmailMessage();         
        objSingleMail.setSaveAsActivity(false);
        objSingleMail.setToAddresses(lstApproverEmail);
        objSingleMail.setSubject('Friendly Reminder To Approve/Reject');
        objSingleMail.setHtmlBody(generateBody(strApproverName, strDCIName, strOppName, strTransactionId, strRecordlink));
        return objSingleMail;
    }

    /* Method Name: generateBody
    * Author Name: Alejandro Ramirez
    * Description: Method to go generate email body
    * Parameters: String strApproverName, String strDCIName, String strOppName, String strTransactionId, String strRecordlink
    * Returns: String
    */
    private String generateBody(String strApproverName, String strDCIName, String strOppName, String strTransactionId, String strRecordlink) {
        List<IDB_Email_Structure__mdt> lstDCISectionAcr = [
            SELECT DeveloperName, MasterLabel, IDB_Body__c, IDB_Footer__c, IDB_Header__c
            FROM IDB_Email_Structure__mdt];
        String strTransactionAux = (strTransactionId != null && strTransactionId != '')? strTransactionId : '';
        String strbody = '';
        strbody += lstDCISectionAcr[0].IDB_Header__c;
        strbody += '<tbody style="background-color: #FFFFFF;">';
		strbody += '<tr> <td colspan="12" height="40"></td> </tr>';
		strbody += '<tr id="x_topInfoH"> <td height="40"></td> <td colspan="10" style="font-size:14px; color:#666666; line-height:23px">';
		strbody += '<div class=""> Dear <strong>' + strApproverName + '</strong> this is a friendly reminder to take actions by approve/reject the next Document submission: <br/><br/>';
        strbody += 'Name: <strong>' + strDCIName + '</strong><br/>';
        strbody += 'Opportunity: <strong>' + strOppName + '</strong><br/>';
        strbody += 'Transaction Id: <strong>' + strTransactionAux + '</strong><br/><br/>';
        strbody += 'Please click this <a href = "' + strRecordlink + '">link to approve or reject this record</a>. <br/>';
		strbody += 'Kindly ignore this email If you have already taken actions. <br/><br/> Thank you, <br/><br/> IDB Invest </div> <br/> </td> <td height="40"></td> </tr> </tbody>';
        strbody += lstDCISectionAcr[0].IDB_Footer__c;
        return strbody;
    }
}