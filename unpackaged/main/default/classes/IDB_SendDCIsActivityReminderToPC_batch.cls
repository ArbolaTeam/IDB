/**********************************************************************************************
* Name          : IDB_SendDCIsActivityReminderToPC_batch 
* Author        : Alejandro Ramirez
* Description   : Batch class to send email notification reminder to Primary Contacs of the Opportunity whos DCIs has been for 15 days in Rejected or Published state so that the client take actions on it.
* Created Date  : 21/05/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 21/05/2021            | v1.0              | First Class version Version
*********************************************************************************************/
global class IDB_SendDCIsActivityReminderToPC_batch implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        Datetime dtToday = System.now();
        Integer intDay = dtToday.day();
        integer intMonth = dtToday.month();
        integer intYear = dtToday.year();
        String strQuery = 'SELECT Id, name, Status__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Primary_Contact__c, Opportunity__r.Primary_Contact__r.Email, Opportunity__r.Primary_Contact__r.name, IDB_Transaction_Id_of_Maestro__c, IDB_Next_Reminder_to_PC_Date__c FROM Document_Checklist_Item__c WHERE Opportunity__c != null AND DAY_IN_MONTH(IDB_Next_Reminder_to_PC_Date__c) = ' + intDay + ' AND CALENDAR_MONTH(IDB_Next_Reminder_to_PC_Date__c) = ' + intMonth + ' AND CALENDAR_YEAR(IDB_Next_Reminder_to_PC_Date__c) = ' + intYear + ' AND (Status__c = \'Rejected\' OR Status__c = \'Published\')';
        System.debug('strQuery::: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Document_Checklist_Item__c> lstDCIs) {
        Set<Id> setOppIds = new Set<Id>();
        // process each batch of records
        if(!lstDCIs.isEmpty()) {
            //System.debug(lstDCIs.size() + ' lstDCIs::: ' + lstDCIs);
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            for(Document_Checklist_Item__c objCurrDCI : lstDCIs) {
                setOppIds.add(objCurrDCI.Opportunity__c);
                objCurrDCI.IDB_Next_Reminder_to_PC_Date__c = system.today().addDays(15);
            }
            Map<Id, List<Document_Checklist_Item__c>> mapDCIsFromOpps = getDCIsFromOpps(setOppIds, lstDCIs);
            system.debug(mapDCIsFromOpps.size() + ' mapDCIsFromOpps::: ' + mapDCIsFromOpps);
            for(Id CurrOppId : setOppIds) {
                List<Document_Checklist_Item__c> lstDCIsFromCurrOpp = mapDCIsFromOpps.get(CurrOppId);
                String strRecordlink = URL.getOrgDomainUrl().toExternalForm() + '/' + CurrOppId;
                if(lstDCIsFromCurrOpp[0].Opportunity__r.Primary_Contact__c != null) {
                    List<String> lstApproverEmail = new List<String>{lstDCIsFromCurrOpp[0].Opportunity__r.Primary_Contact__r.Email};
                    lstMails.add(prepareEmail(lstApproverEmail, lstDCIsFromCurrOpp[0].Opportunity__r.Primary_Contact__r.Name, lstDCIsFromCurrOpp[0].Opportunity__r.Name, strRecordlink, lstDCIsFromCurrOpp));
                }
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

    /* Method Name: getDCIsFromOpps
    * Author Name: Alejandro Ramirez
    * Description: Method to prepare each OpportunityId with it's DCIs
    * Parameters: Set<Id> setOppIds, List<Document_Checklist_Item__c> lstDCIs
    * Returns: Map<Id,List<Document_Checklist_Item__c>>
    */
    private Map<Id,List<Document_Checklist_Item__c>> getDCIsFromOpps(Set<Id> setOppIds, List<Document_Checklist_Item__c> lstDCIs) {
        Map<Id, List<Document_Checklist_Item__c>> mapDCIsFromOppsToRet = new Map<Id, List<Document_Checklist_Item__c>>();
        for(Id CurrOppId : setOppIds) {
            List<Document_Checklist_Item__c> lstCurrDCIsFromOpp = new List<Document_Checklist_Item__c>();
            for(Document_Checklist_Item__c objCurrDCI : lstDCIs) {
                if(objCurrDCI.Opportunity__c == CurrOppId) {
                    lstCurrDCIsFromOpp.add(objCurrDCI);
                }
            }
            mapDCIsFromOppsToRet.put(CurrOppId, lstCurrDCIsFromOpp);
        }
        return mapDCIsFromOppsToRet;
    }

    /* Method Name: prepareEmail
    * Author Name: Alejandro Ramirez
    * Description: Method to prepare each single email for each Opportunity with DCIs
    * Parameters: List<String> List<String> lstApproverEmail, String strPrimaryContactName, String strOppName, String strRecordlink, List<Document_Checklist_Item__c> lstDCIsFromCurrOpp
    * Returns: Messaging.SingleEmailMessage
    */
    private Messaging.SingleEmailMessage prepareEmail(List<String> lstApproverEmail, String strPrimaryContactName, String strOppName, String strRecordlink, List<Document_Checklist_Item__c> lstDCIsFromCurrOpp) {
        Messaging.SingleEmailMessage objSingleMail = new Messaging.SingleEmailMessage();         
        objSingleMail.setSaveAsActivity(false);
        objSingleMail.setToAddresses(lstApproverEmail);
        objSingleMail.setSubject('Catch up activity reminder');
        objSingleMail.setHtmlBody(generateBody(strPrimaryContactName, strOppName, strRecordlink, lstDCIsFromCurrOpp));
        return objSingleMail;
    }

    /* Method Name: generateBody
    * Author Name: Alejandro Ramirez
    * Description: Method to go generate email body
    * Parameters: NONE
    * Returns: String
    */
    private String generateBody(String strPrimaryContactName, String strOppName, String strRecordlink, List<Document_Checklist_Item__c> lstDCIsFromCurrOpp) {
        List<IDB_Email_Structure__mdt> lstDCISectionAcr = [
            SELECT DeveloperName, MasterLabel, IDB_Body__c, IDB_Footer__c, IDB_Header__c
            FROM IDB_Email_Structure__mdt];
        String strbody = '';
        strbody += lstDCISectionAcr[0].IDB_Header__c;
        strbody += '<tbody style="background-color: #FFFFFF;">';
		strbody += '<tr> <td colspan="12" height="40"></td> </tr>';
		strbody += '<tr id="x_topInfoH"> <td height="40"></td> <td colspan="10" style="font-size:14px; color:#666666; line-height:23px">';
		strbody += '<div class=""> Dear <strong>' + strPrimaryContactName + '</strong> this is a friendly reminder to let you know that the following Opportunity: <strong>' + strOppName + '</strong>';
        strbody += ' has the next documents that needs to be reviewed:<br/><br/>';
        strbody += '<table style = "border-collapse: collapse; width: 100%;" border = "1"><tr><th>Name</th><th>Transaction Id</th><th>Status</th></tr>';
        for(Document_Checklist_Item__c objCurrDCI : lstDCIsFromCurrOpp) {
            strbody += '<tr> <td style = "text-align: left;">' + objCurrDCI.name + '</td><td style = "text-align: left;"> ' + objCurrDCI.IDB_Transaction_Id_of_Maestro__c + '</td><td style = "text-align: left;">' + objCurrDCI.Status__c + '</td> </tr>';
        }
        strbody += '</table>';
        strbody += '<br/><br/>';
        strbody += 'Please click this <a href = "' + strRecordlink + '">link to go to the Opportunity.</a> <br/><br/>';
		strbody += 'Kindly ignore this email If you have already taken actions. <br/><br/> Thank you, <br/><br/> IDB Invest </div> <br/> </td> <td height="40"></td> </tr> </tbody>';
        strbody += lstDCISectionAcr[0].IDB_Footer__c;
        return strbody;
    }
}