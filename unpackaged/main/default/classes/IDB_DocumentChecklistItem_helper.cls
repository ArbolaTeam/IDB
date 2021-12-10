/**********************************************************************************************
* Name          : IDB_DocumentChecklistItem_helper 
* Author        : Alejandro Ramirez
* Description   : Helper class for Trigger on Document Checklist Item
* Created Date  : 16/04/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 16/04/2021            | v1.0              | First Class version Version
Alejandro Ramirez       | 04/05/2021            | v1.1              | Adding logic for CP2-34 (Validate and stablish an order for DCI's according to their section they belong to)
Alejandro Ramirez       | 18/05/2021            | v1.2              | Adding logic for CP2-38 (IDB Invest Client alert when submitting Documents for approval)
Alejandro Ramirez       | 20/05/2021            | v1.3              | Adding logic for CP2-54 Approval/Rejection Reminder - IDB Invest User - each 15 days after submission
Alejandro Ramirez       | 24/05/2021            | v1.4              | Adding logic for CP2-57 IDB Client Primary Contact - Reminder Submit for Approval each 15 days
Alejandro Ramirez       | 07/06/2021            | v1.5              | Adding logic for CP2-39 Client and IDB Invest Users should be able to view PII documents based on role/profile
Alejandro Ramirez       | 07/12/2021            | v1.6              | Adding logic for CP2-46 IDB Invest Users/Clients: In application bell notifications
*********************************************************************************************/
public without sharing class IDB_DocumentChecklistItem_helper {

    List<Document_Checklist_Item__c> lstDCI = new List<Document_Checklist_Item__c>();
    List<Document_Checklist_item_Section_Acronym__mdt> lstDCISectionAcr = new List<Document_Checklist_item_Section_Acronym__mdt>();
    Set<String> setSections = new Set<String>();
    List<Document_Checklist_Item__c> lstDCIsToSetSubmittedDate = new List<Document_Checklist_Item__c>();

    /* Method Name: onBeforeUpdate
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on before update
    * Parameters: Document_Checklist_Item__c[] oldRecords, Document_Checklist_Item__c[] updatedRecords, Map<ID, Document_Checklist_Item__c> oldRecordsMap, Map<ID, Document_Checklist_Item__c> updatedRecordsMap
    * Returns: Void
    */
    public void onBeforeUpdate(Document_Checklist_Item__c[] oldRecords, Document_Checklist_Item__c[] updatedRecords, Map<ID, Document_Checklist_Item__c> oldRecordsMap, Map<ID, Document_Checklist_Item__c> updatedRecordsMap) {
        validateBeforeApproval(oldRecordsMap, updatedRecordsMap);
        validateBeforeSubmit(oldRecordsMap, updatedRecordsMap);
        updateSubmittedDate();
        validateBeforeRejectPublish(oldRecordsMap, updatedRecordsMap);
        validatePIItoAddRemoveSharingSets(oldRecordsMap, updatedRecordsMap);
	}

    /* Method Name: onAfterUpdate
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on after update COMMENTED UNTIL IS BEING IN USE
    * Parameters: Document_Checklist_Item__c[] oldRecords, Document_Checklist_Item__c[] updatedRecords, Map<ID, Document_Checklist_Item__c> oldRecordsMap, Map<ID, Document_Checklist_Item__c> updatedRecordsMap
    * Returns: Void
    */
    public void onAfterUpdate(Document_Checklist_Item__c[] oldRecords, Document_Checklist_Item__c[] updatedRecords, Map<ID, Document_Checklist_Item__c> oldRecordsMap, Map<ID, Document_Checklist_Item__c> updatedRecordsMap) {
        //sendSubmitterNotificationIfRejected(oldRecordsMap, updatedRecordsMap);
        setApproverSharingSetsOnUpd(oldRecordsMap, updatedRecordsMap);
    }

    /* Method Name: onBeforeInsert
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on before insert
    * Parameters: None
    * Returns: Void
    */
    public void onBeforeInsert(Document_Checklist_Item__c[] insertedRecords) {
        validateDCISections(insertedRecords);
        validateDCIsOwner(insertedRecords);
    }

    /* Method Name: onAfterInsert
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on after insert
    * Parameters: None
    * Returns: Void
    */
    public void onAfterInsert(Document_Checklist_Item__c[] insertedRecords) {
        assignDCIsSharingSet(insertedRecords);
        setApproverSharingSets(insertedRecords);
    }

    /****** METHODS TO BUILD LOGIC ******/

    /* Method Name: validateBeforeApproval
    * Author Name: Alejandro Ramirez
    * Description: Hits validation error when record is going to be approved and it's not having period values.
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void validateBeforeApproval(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        for(Id currentDCI : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currentDCI);
            if((objCurrDCI.Status__c != mapOldRecordsIn.get(objCurrDCI.id).Status__c) && objCurrDCI.Status__c == Label.IDB_DCI_Approved_status &&  objCurrDCI.Period__c == null) {
                objCurrDCI.addError(Label.IDB_Period_Error);
            }
        }
    }

    /* Method Name: validateDCISections
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set the order in identifier field based on section field from DCI
    * Parameters: Document_Checklist_Item__c[] insertedRecordsIn, Map<ID, Document_Checklist_Item__c> insertedRecordsMapIn
    * Returns: Void
    */
    private void validateDCISections(Document_Checklist_Item__c[] insertedRecordsIn) {
        Set<Id> setOpportunitiesId = getOppIds(insertedRecordsIn); // get the records inserted with opportunities related to them
        //System.debug('Opportunities::: ' + setOpportunitiesId);
        //System.debug('lstDCI::: ' + lstDCI.size());
        //system.debug('setSections::: ' + setSections);
        if(!setOpportunitiesId.isEmpty()) {
            List<Document_Checklist_Item__c> lstDCIExisting = [
                SELECT id, Opportunity__c, Section__c, Identifier__c 
                FROM Document_Checklist_Item__c 
                WHERE Opportunity__c IN: setOpportunitiesId AND Section__c IN: setSections AND Id NOT IN: lstDCI ORDER BY Section__c];
            //System.debug('lstDCIExisting.size()::: ' + lstDCIExisting.size());
            if(!lstDCIExisting.isEmpty()) {
                List<DCISectionsInOppsWrapper> lstDCISecsWrapper = getSectionsCountFromOpps(lstDCIExisting, setOpportunitiesId);
                setAcronym(setOpportunitiesId, true, lstDCISecsWrapper);
                //if so then this is the first DCI of N section inserted to one opportunity
            }else{
                setAcronym(setOpportunitiesId, false, null);
            }
        }
    }

    /* Method Name: validateBeforeSubmit
    * Author Name: Alejandro Ramirez
    * Description: Hits validation error when record is going to be submitted and it's not having files or if the files created were created by partner users, except for some conditions.
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void validateBeforeSubmit(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        Id rtDocumentsId = Schema.SObjectType.Document_Checklist_Item__c.getRecordTypeInfosByName().get(Label.IDB_Documents_RT).getRecordTypeId();
        Id rtHiperlynkId = Schema.SObjectType.Document_Checklist_Item__c.getRecordTypeInfosByName().get(Label.IDB_Hyperlink_RT).getRecordTypeId();
        List<Document_Checklist_Item__c> lstDCIsToEvaluateFiles = new List<Document_Checklist_Item__c>();
        Set<Id> setDCIsId = new Set<Id>();
        for(Id currDCIId : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currDCIId);
            if((objCurrDCI.Status__c != mapOldRecordsIn.get(objCurrDCI.id).Status__c) && objCurrDCI.Status__c == Label.IDB_DCI_Submitted_status && (objCurrDCI.RecordTypeId == rtDocumentsId || objCurrDCI.RecordTypeId == rtHiperlynkId)) {
                if(objCurrDCI.name != Label.IDB_Corporate_Name) {
                    lstDCIsToEvaluateFiles.add(objCurrDCI);
                    setDCIsId.add(objCurrDCI.id);
                }
            }else if((objCurrDCI.Status__c != mapOldRecordsIn.get(objCurrDCI.id).Status__c) && objCurrDCI.Status__c == Label.IDB_DCI_Submitted_status && (objCurrDCI.RecordTypeId != rtDocumentsId || objCurrDCI.RecordTypeId != rtHiperlynkId)) {
                //when DCIs are being submitted but are not Document or hyperlink record type
                //Add the DCIs to update Submitted Date and next reminder date. According to: CP2-54
                lstDCIsToSetSubmittedDate.add(objCurrDCI);
            }
        }
        if(!setDCIsId.isEmpty()) {
            List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: Label.IDB_Client_User_Profile OR Profile.Name =: Label.IDB_Client_User_Admin_Profile OR Profile.Name =: Label.IDB_System_Admin_Profile];
            List<ContentDocumentLink> lstDCIsFiles = [SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.CreatedById, ContentDocument.CreatedBy.Name, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN: setDCIsId];
            System.debug(lstDCIsFiles.size() + ' lstDCIsFiles::: ' + lstDCIsFiles);
            if(lstDCIsFiles.isEmpty() && lstDCIsToEvaluateFiles.size() == 1) {
                lstDCIsToEvaluateFiles[0].addError(Label.IDB_No_Files_Error);
            }else if(lstDCIsFiles.isEmpty() && lstDCIsToEvaluateFiles.size() >= 1) {
                for(Document_Checklist_Item__c objCurrDCI : lstDCIsToEvaluateFiles) {
                    objCurrDCI.addError(Label.IDB_No_Files_Error);
                }
            }else if(!lstDCIsFiles.isEmpty()) {
                for(Document_Checklist_Item__c objCurrDCI : lstDCIsToEvaluateFiles) {
                    boolean boolHasPartnerFile = false;
                    for(ContentDocumentLink objCurrCDLofDCI : lstDCIsFiles) {
                        if(objCurrDCI.Id == objCurrCDLofDCI.LinkedEntityId) {
                            for(User objCurrUser : lstUsers) {
                                if(objCurrUser.Id == objCurrCDLofDCI.ContentDocument.CreatedById) {
                                    boolHasPartnerFile = true;
                                    break;
                                }
                            }
                        }
                        if(boolHasPartnerFile) {
                            break;
                        }
                    }
                    if(!boolHasPartnerFile) {
                        objCurrDCI.addError(Label.IDB_No_Files_Error);
                    }else {
                        //Add the DCIs to update Submitted Date and next reminder date. According to: CP2-54
                        lstDCIsToSetSubmittedDate.add(objCurrDCI);
                    }
                }
            }
        }
    }

    /* Method Name: updateSubmittedDate
    * Author Name: Alejandro Ramirez
    * Description: Takes the subbmited DCIs in order to update the submitted date and the next reminder date.
    * Parameters: None
    * Returns: Void
    */
    private void updateSubmittedDate() {
        if(!lstDCIsToSetSubmittedDate.isEmpty()) {
            for(Document_Checklist_Item__c objCurrDCI : lstDCIsToSetSubmittedDate) {
                objCurrDCI.IDB_Submitted_Date__c = system.today();
                objCurrDCI.IDB_Next_Reminder_Date__c = system.today().addDays(15);
            }
        }
    }

    /* Method Name: validateBeforeRejectPublish
    * Author Name: Alejandro Ramirez
    * Description: 
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void validateBeforeRejectPublish(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        Id currUsrId = UserInfo.getUserId();
        List<String> lstAlternateTLRole = Label.IDB_Financial_Analyst_Alternate_Investment_Officer_Role.split(';');
        List<OpportunityTeamMember> lstCurrOTM = getOTM(currUsrId);
        for(Id currentDCI : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currentDCI);
            if(objCurrDCI.Status__c != mapOldRecordsIn.get(objCurrDCI.id).Status__c && (objCurrDCI.Status__c == Label.IDB_DCI_Published_Status || objCurrDCI.Status__c == Label.IDB_DCI_Rejected_Status)) {
                if(objCurrDCI.Status__c == Label.IDB_DCI_Published_Status && !lstCurrOTM.isEmpty()) {
                    if(lstCurrOTM[0].TeamMemberRole != Label.IDB_Team_Leader_Role && lstCurrOTM[0].TeamMemberRole != lstAlternateTLRole[0] && lstCurrOTM[0].TeamMemberRole != lstAlternateTLRole[1]) {
                        objCurrDCI.addError(Label.IDB_change_to_publish_error);
                        break;
                    }
                }
                objCurrDCI.IDB_Next_Reminder_to_PC_Date__c = system.today().addDays(15);
            }
        }
    }
    
    /* Method Name: validateDCIsOwner
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set the DCI owner if the DCI is private and the opportunity has First Team Lead
    * Parameters: Document_Checklist_Item__c[] insertedRecordsIn
    * Returns: Void
    */
    private void validateDCIsOwner(Document_Checklist_Item__c[] insertedRecordsIn) {
        List<Document_Checklist_Item__c> lstValidDCIs = new List<Document_Checklist_Item__c>();
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        //get DCIs which has opportunities
        for(Document_Checklist_Item__c objCurrDCI : insertedRecordsIn) {
            if(objCurrDCI.Opportunity__c != null) {
                lstValidDCIs.add(objCurrDCI);
            }
        }
        if(!lstValidDCIs.isEmpty()) {
            Set<Id> setOpportunitiesId = getSimpleOppIds(lstValidDCIs);
            List<OpportunityTeamMember> lstOTMfromDCIs = getOTMfromDCIs(setOpportunitiesId);
            if(!lstOTMfromDCIs.isEmpty()) {
                lstTeamLeads = getSpecificMembers(lstOTMfromDCIs, true, false, false);
                if(!lstTeamLeads.isEmpty()) {
                    //set as owner of the DCIs(All) the First Team Lead on the OppTeamMembers
                    setDCIsOwner(lstValidDCIs, lstTeamLeads);
                }
            }
        }
    }

    /* Method Name: assignDCIsSharingSet
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members related to the opportunity of the DCI
    * Parameters: Document_Checklist_Item__c[] insertedRecordsIn
    * Returns: Void
    */
    private void assignDCIsSharingSet(Document_Checklist_Item__c[] insertedRecordsIn) {
        List<Document_Checklist_Item__c> lstPublicDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstPrivateDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstValidDCIs = new List<Document_Checklist_Item__c>();
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstAlternateTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        //get DCIs which has opportunities
        for(Document_Checklist_Item__c objCurrDCI : insertedRecordsIn) {
            if(objCurrDCI.Opportunity__c != null) {
                lstValidDCIs.add(objCurrDCI);
            }
        }
        if(!lstValidDCIs.isEmpty()) {
            Set<Id> setOpportunitiesId = getSimpleOppIds(lstValidDCIs);
            for(Document_Checklist_Item__c objCurrDCI : lstValidDCIs) {
                if(objCurrDCI.Contains_PII__c) {
                    lstPrivateDCIs.add(objCurrDCI);
                }else{ 
                    lstPublicDCIs.add(objCurrDCI);
                }
            }
            List<OpportunityTeamMember> lstOTMfromDCIs = getOTMfromDCIs(setOpportunitiesId);
            if(!lstOTMfromDCIs.isEmpty()) {
                lstTeamLeads = getSpecificMembers(lstOTMfromDCIs, true, false, false);
                lstAlternateTeamLeads = getSpecificMembers(lstOTMfromDCIs, false, true, false);
                lstTeamMembers = getSpecificMembers(lstOTMfromDCIs, false, false, true);
                if(!lstPrivateDCIs.isEmpty()) {
                    if(!lstTeamLeads.isEmpty()) {
                        setSharingAccess(lstPrivateDCIs, lstTeamLeads, true, false);
                    }
                    if(!lstAlternateTeamLeads.isEmpty()) {
                        setSharingAccess(lstPrivateDCIs, lstAlternateTeamLeads, true, false);
                    }
                }
                if(!lstPublicDCIs.isEmpty()) {
                    if(!lstTeamMembers.isEmpty()) {
                        setSharingAccess(lstPublicDCIs, lstTeamMembers, false, false);
                    }
                    if(!lstTeamLeads.isEmpty()) {
                        setSharingAccess(lstPublicDCIs, lstTeamLeads, true, false);
                    }
                    if(!lstAlternateTeamLeads.isEmpty()) {
                        setSharingAccess(lstPublicDCIs, lstAlternateTeamLeads, true, false);
                    }
                }
            }
        }
    }

    /* Method Name: setApproverSharingSets
    * Author Name: Alejandro Ramirez
    * Description: Set approver sharing sets
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void setApproverSharingSets(Document_Checklist_Item__c[] insertedRecordsIn) {
        //when DCI is inserted the approver comes Null if is not set manually
        List<Document_Checklist_Item__c> lstValidDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstDCIsToGiveApproverAccess = new List<Document_Checklist_Item__c>();
        Set<id> setApproverIds = new Set<Id>();
        for(Document_Checklist_Item__c objCurrDCI : insertedRecordsIn) {
            //system.debug('setApproverSharingSets::: ' + objCurrDCI.IDB_Approver__c + ' ' + objCurrDCI.OwnerId);
            if(objCurrDCI.Opportunity__c != null && objCurrDCI.IDB_Approver__c != null && objCurrDCI.IDB_Approver__c != objCurrDCI.OwnerId) {
                lstValidDCIs.add(objCurrDCI);
                setApproverIds.add(objCurrDCI.IDB_Approver__c);
            }
        }
        if(!lstValidDCIs.isEmpty()) {
            Set<id> setDCIIds = getDCIsIds(lstValidDCIs);
            List<Document_Checklist_Item__Share> lstDCIsSharingAccess = getDCIsSharingAccess(setDCIIds, setApproverIds);
            for(Document_Checklist_Item__c objCurrDCI : lstValidDCIs) {
                boolean boolAlreadyShared = false;
                for(Document_Checklist_Item__Share objCurrDCISharing : lstDCIsSharingAccess) {
                    if(objCurrDCISharing.UserOrGroupId == objCurrDCI.IDB_Approver__c && objCurrDCISharing.ParentId == objCurrDCI.Id) {
                        boolAlreadyShared = true;
                        break;
                    }
                }
                if(!boolAlreadyShared) {
                    lstDCIsToGiveApproverAccess.add(objCurrDCI);
                }
            }
            if(!lstDCIsToGiveApproverAccess.isEmpty()) {
                setApproverSharingSet(lstDCIsToGiveApproverAccess);
            }
        }
    }

    /* Method Name: validatePIItoAddRemoveSharingSets
    * Author Name: Alejandro Ramirez
    * Description: evaluates if Contains PII is changed and applies/remove respective Sharing Sets
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void validatePIItoAddRemoveSharingSets(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        List<Document_Checklist_Item__c> lstDCIsToShare = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstDCIsToUnShare = new List<Document_Checklist_Item__c>();
        for(Id currentDCI : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currentDCI);
            if((objCurrDCI.Contains_PII__c != mapOldRecordsIn.get(objCurrDCI.id).Contains_PII__c) && objCurrDCI.Opportunity__c != null) {
                if(objCurrDCI.Contains_PII__c) {
                    lstDCIsToUnShare.add(objCurrDCI);
                }else{
                    lstDCIsToShare.add(objCurrDCI);
                }
            }
        }
        if(!lstDCIsToShare.isEmpty()) {
            assignDCIsSharingSetOnUpdate(lstDCIsToShare);
        }
        if(!lstDCIsToUnShare.isEmpty()) {
            removeDCIsSharingSetOnUpdade(lstDCIsToUnShare);
        }
    }

    /* Method Name: sendSubmitterNotificationIfRejected
    * Author Name: Alejandro Ramirez
    * Description: method to send a notification to submitters when DCI Approval is Rejected
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    /*private void sendSubmitterNotificationIfRejected(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        List<Document_Checklist_Item__c> lstDCIsRejected = new List<Document_Checklist_Item__c>();
        Set<id> setDCIsRejectedIds = new Set<Id>();
        List<ProcessInstance> lstMostRecentPTFromDCI = new List<ProcessInstance>();
        for(Id currentDCI : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currentDCI);
            if((objCurrDCI.Status__c != mapOldRecordsIn.get(objCurrDCI.id).Status__c) && objCurrDCI.Status__c == Label.IDB_DCI_Rejected_Status) {
                lstDCIsRejected.add(objCurrDCI);
                setDCIsRejectedIds.add(objCurrDCI.Id);
            }
        }
        if(!lstDCIsRejected.isEmpty()) {
            List<ProcessInstance> lstDCIsPIs = [
                SELECT Id, TargetObjectId, SubmittedById, SubmittedBy.Name, status, CompletedDate, LastModifiedDate, CreatedDate 
                FROM ProcessInstance 
                WHERE TargetObjectId IN : setDCIsRejectedIds ORDER BY createdDate DESC, TargetObjectId
            ];
            if(!lstDCIsPIs.isEmpty()) {
                for(Document_Checklist_Item__c objCurrDCI : lstDCIsRejected) {
                    for(ProcessInstance objCurrPI : lstDCIsPIs) {
                        if(objCurrDCI.Id == objCurrPI.TargetObjectId) {
                            lstMostRecentPTFromDCI.add(objCurrPI);
                            break;
                        }
                    }
                }
                CustomNotificationType objNotificationType = [
                    SELECT Id, DeveloperName 
                    FROM CustomNotificationType 
                    WHERE DeveloperName = 'IDB_DCI_rejected_Notification'];
                for(Document_Checklist_Item__c objCurrDCI : lstDCIsRejected) {
                    for(ProcessInstance objCurrPI : lstMostRecentPTFromDCI) {
                        if(objCurrDCI.Id == objCurrPI.TargetObjectId) {
                            //System.debug('objCurrPI.SubmittedBy.Name::: ' + objCurrPI.SubmittedBy.Name);
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            // Set the contents for the notification
                            notification.setTitle(Label.IDB_NotificationOnReject);
                            notification.setBody('Name: ' + objCurrDCI.Name);
                    
                            // Set the notification type and target
                            notification.setNotificationTypeId(objNotificationType.Id);
                            notification.setTargetId(objCurrPI.TargetObjectId);
                            try {
                                notification.send(new Set<String> {objCurrPI.SubmittedById});
                            }catch (Exception e) {
                                System.debug('Problem sending notification: ' + e.getMessage());
                            }
                            break;
                        }
                    }
                }
            }
        }
    }*/

    /* Method Name: setApproverSharingSetsOnUpd
    * Author Name: Alejandro Ramirez
    * Description: method to send a notification to submitters when DCI Approval is Rejected
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    private void setApproverSharingSetsOnUpd(Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn) {
        List<Document_Checklist_Item__c> lstValidDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstDCIsToGiveApproverAccess = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__Share> lstDCISharingToUpdate = new List<Document_Checklist_Item__Share>();
        Set<id> setApproverIds = new Set<Id>();
        for(Id currentDCI : mapNewRecordsIn.keySet()) {
            Document_Checklist_Item__c objCurrDCI = mapNewRecordsIn.get(currentDCI);
            if((objCurrDCI.IDB_Approver__c != mapOldRecordsIn.get(objCurrDCI.id).IDB_Approver__c) && objCurrDCI.Opportunity__c != null && objCurrDCI.IDB_Approver__c != null && objCurrDCI.IDB_Approver__c != objCurrDCI.OwnerId) {
                lstValidDCIs.add(objCurrDCI);
                setApproverIds.add(objCurrDCI.IDB_Approver__c);
            }
        }
        if(!lstValidDCIs.isEmpty()) {
            Set<id> setDCIIds = getDCIsIds(lstValidDCIs);
            List<Document_Checklist_Item__Share> lstDCIsSharingAccess = getDCIsSharingAccess(setDCIIds, setApproverIds);
            if(!lstDCIsSharingAccess.isEmpty()) {
                for(Document_Checklist_Item__c objCurrDCI : lstValidDCIs) {
                    boolean boolAlreadyShared = false;
                    for(Document_Checklist_Item__Share objCurrDCISharing : lstDCIsSharingAccess) {
                        if(objCurrDCISharing.UserOrGroupId == objCurrDCI.IDB_Approver__c && objCurrDCISharing.ParentId == objCurrDCI.Id && objCurrDCISharing.AccessLevel == 'Edit') {
                            boolAlreadyShared = true;
                            break;
                        }else if(objCurrDCISharing.UserOrGroupId == objCurrDCI.IDB_Approver__c && objCurrDCISharing.ParentId == objCurrDCI.Id && objCurrDCISharing.AccessLevel == 'Read') {
                            lstDCISharingToUpdate.add(objCurrDCISharing);
                        }
                    }
                    if(!boolAlreadyShared) {
                        lstDCIsToGiveApproverAccess.add(objCurrDCI);
                    }
                }
            }else{
                for(Document_Checklist_Item__c objCurrDCI : lstValidDCIs) {
                    lstDCIsToGiveApproverAccess.add(objCurrDCI);
                }
            }
            System.debug('lstDCIsToGiveApproverAccess::: ' + lstDCIsToGiveApproverAccess.size() + ' lstDCISharingToUpdate::: ' + lstDCISharingToUpdate.size());
            if(!lstDCIsToGiveApproverAccess.isEmpty()) {
                setApproverSharingSet(lstDCIsToGiveApproverAccess);
            }else if(!lstDCISharingToUpdate.isEmpty()) {
                reassignSharingAccess(lstDCISharingToUpdate);
            }
        }

    }

    /****** SECONDARY METHODS ******/

    /* Method Name: getOppIds
    * Author Name: Alejandro Ramirez
    * Description: method to get Opps Ids from the inserted DCIs
    * Parameters: List<Document_Checklist_Item__c> insertedRecordsIn
    * Returns: Set<Id>
    */
    private Set<Id> getOppIds(List<Document_Checklist_Item__c> insertedRecordsIn) {
        Set<Id> OppIdsToReturn = new Set<Id>();
        lstDCISectionAcr = [
            SELECT MasterLabel, Section__c, IDB_AdditionalSectionForSameAcronym__c, DeveloperName
            FROM Document_Checklist_item_Section_Acronym__mdt];
        //System.debug('Metadata Values::: ' + lstDCISectionAcr);
        for(Document_Checklist_Item__c objCurrDCI : insertedRecordsIn) {
            if(objCurrDCI.Opportunity__c != null) {
                OppIdsToReturn.add(objCurrDCI.Opportunity__c);
                lstDCI.add(objCurrDCI);
                for(Document_Checklist_item_Section_Acronym__mdt objCurrMtd : lstDCISectionAcr) {
                    if(objCurrMtd.IDB_AdditionalSectionForSameAcronym__c != null) {
                        List<String> lstAdditionalSections = objCurrMtd.IDB_AdditionalSectionForSameAcronym__c.split(';');
                        if(objCurrMtd.IDB_AdditionalSectionForSameAcronym__c.contains(objCurrDCI.Section__c) || objCurrDCI.Section__c == objCurrMtd.Section__c) {
                            setSections.add(objCurrMtd.Section__c);
                            for(String strAddSec : lstAdditionalSections) {
                                setSections.add(strAddSec);
                            }
                        }
                    }
                }
                setSections.add(objCurrDCI.Section__c);
            }
        }
        return OppIdsToReturn;
    }

    /* Method Name: getSectionsCountFromOpps
    * Author Name: Alejandro Ramirez
    * Description: method to get total count of each DCI section belonging to an opportunity already in the system
    * Parameters: List<Document_Checklist_Item__c> lstDCIExisting, Set<Id> setOpportunitiesId
    * Returns: List<DCISectionsInOppsWrapper>
    */
    private List<DCISectionsInOppsWrapper> getSectionsCountFromOpps(List<Document_Checklist_Item__c> lstDCIExisting, Set<Id> setOpportunitiesId) {
        List<DCISectionsInOppsWrapper> lstDCISecsWrapper = new List<DCISectionsInOppsWrapper>();
        for(String strCurrSection : setSections) {
            String strAddSect = '';
            for(Document_Checklist_item_Section_Acronym__mdt objCurrMtd : lstDCISectionAcr) {
                if(objCurrMtd.IDB_AdditionalSectionForSameAcronym__c != null) {
                    if(objCurrMtd.IDB_AdditionalSectionForSameAcronym__c.contains(strCurrSection) || objCurrMtd.Section__c == strCurrSection) {
                        strAddSect = objCurrMtd.IDB_AdditionalSectionForSameAcronym__c + ';' + objCurrMtd.Section__c;
                        break;
                    }
                }
            }
            //system.debug('strAddSect::: ' + strAddSect);
            for(Id currOppId : setOpportunitiesId) {
                DCISectionsInOppsWrapper objSectionWrapper = new DCISectionsInOppsWrapper();
                integer intCount = 0;
                for(Document_Checklist_Item__c objDCIExisting : lstDCIExisting) {
                    if((strCurrSection == objDCIExisting.section__c || strAddSect.contains(strCurrSection)) && objDCIExisting.Opportunity__c == currOppId) {
                        intCount++;
                    }
                }
                objSectionWrapper.oppId = currOppId;
                objSectionWrapper.strSection = strCurrSection;
                objSectionWrapper.intCount = intCount;
                lstDCISecsWrapper.add(objSectionWrapper);
            }
        }
        //System.debug('lstDCISecsWrapper::: ' + lstDCISecsWrapper);
        return lstDCISecsWrapper;
    }

    /* Method Name: setAcronym
    * Author Name: Alejandro Ramirez
    * Description: method to update DCI Identifiers accordingly
    * Parameters: Set<Id> setOppsIn, boolean areExistingDCIs
    * Returns: Void
    */
    private void setAcronym(Set<Id> setOppsIn, boolean areExistingDCIs, List<DCISectionsInOppsWrapper> lstDCISecsWrapperIn) {
        if(areExistingDCIs) {
            for(String strCurrSection : setSections) {
                for(Document_Checklist_item_Section_Acronym__mdt objCurrentMtd : lstDCISectionAcr) {
                    if(strCurrSection == objCurrentMtd.Section__c || (objCurrentMtd.IDB_AdditionalSectionForSameAcronym__c != null && objCurrentMtd.IDB_AdditionalSectionForSameAcronym__c.contains(strCurrSection))) {
                        for(Id currOppId : setOppsIn) {
                            integer intCount = 0;
                            //iterate through existing dciRecords
                            for(DCISectionsInOppsWrapper objCurrDCIWrapper : lstDCISecsWrapperIn) {
                                if(strCurrSection == objCurrDCIWrapper.strSection && objCurrDCIWrapper.oppId == currOppId) {
                                    intCount = objCurrDCIWrapper.intCount + 1;
                                    break;
                                }
                            }
                            //this loop starts to set the value to new Records
                            for(Document_Checklist_Item__c objCurrDCIIncoming : lstDCI) {
                                if(strCurrSection == objCurrDCIIncoming.Section__c && objCurrDCIIncoming.Opportunity__c == currOppId) {
                                    objCurrDCIIncoming.Identifier__c = objCurrentMtd.MasterLabel + '-' + intCount;
                                    intCount++;
                                }
                            }
                        }
                    }
                }
            }
        }else{
            for(String strCurrSection : setSections) {
                integer intCount = 1;
                for(Document_Checklist_item_Section_Acronym__mdt objCurrentMtd : lstDCISectionAcr) {
                    for(Document_Checklist_Item__c objCurrDCIIncoming : lstDCI) {
                        if((strCurrSection == objCurrentMtd.Section__c || (objCurrentMtd.IDB_AdditionalSectionForSameAcronym__c != null && objCurrentMtd.IDB_AdditionalSectionForSameAcronym__c.contains(strCurrSection))) && strCurrSection == objCurrDCIIncoming.section__c) {
                            objCurrDCIIncoming.Identifier__c = objCurrentMtd.MasterLabel + '-' + intCount;
                            intCount++;
                        }
                    }
                }
            }
        }
    }
    
    /* Method Name: assignDCIsSharingSetOnUpdate
    * Author Name: Alejandro Ramirez
    * Description: set back sharing set to team members on opportunities when DCI is updated to contains pii = false
    * Parameters: List<Document_Checklist_Item__c> lstIncomingPublicDCIs
    * Returns: Void
    */
    private void assignDCIsSharingSetOnUpdate(List<Document_Checklist_Item__c> lstIncomingPublicDCIs) {
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        Set<Id> setOpportunitiesId = getSimpleOppIds(lstIncomingPublicDCIs);
        List<OpportunityTeamMember> lstOTMfromDCIs = getOTMfromDCIs(setOpportunitiesId);
        if(!lstOTMfromDCIs.isEmpty()) {
            lstTeamMembers = getSpecificMembers(lstOTMfromDCIs, false, false, true);
            if(!lstTeamMembers.isEmpty()) {
                setSharingAccess(lstIncomingPublicDCIs, lstTeamMembers, false, false);
            }
        }
    }

    /* Method Name: removeDCIsSharingSetOnUpdade
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to remove sharing sets to team members related to the opportunity of the DCI
    * Parameters: List<Document_Checklist_Item__c> lstIncomingPrivateDCIs
    * Returns: Void
    */
    private void removeDCIsSharingSetOnUpdade(List<Document_Checklist_Item__c> lstIncomingPrivateDCIs) {
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        Set<id> setDCIIds = getDCIsIds(lstIncomingPrivateDCIs);
        Set<Id> setOpportunitiesId = getSimpleOppIds(lstIncomingPrivateDCIs);
        List<OpportunityTeamMember> lstOTMfromDCIs = getOTMfromDCIs(setOpportunitiesId);
        if(!lstOTMfromDCIs.isEmpty()) {
            lstTeamLeads = getSpecificMembers(lstOTMfromDCIs, true, false, false);
            lstTeamMembers = getSpecificMembers(lstOTMfromDCIs, false, false, true);
            if(!lstTeamLeads.isEmpty()) {
                //the Private updated DCI needs to have as owner the FTL. Give Write permissions is not needed because it already have it.
                setDCIsOwner(lstIncomingPrivateDCIs, lstTeamLeads);
            }
            if(!lstTeamMembers.isEmpty()) {
                //Read permissions on team members needs to be removed on the updated DCI private
                Set<id> setOTMsUserIds = getOTMsUserIds(lstTeamMembers);
                List<Document_Checklist_Item__Share> lstDCIsSharingAccess = getDCIsSharingAccess(setDCIIds, setOTMsUserIds);
                removeTeamMembersSharing(lstIncomingPrivateDCIs, lstTeamMembers, lstDCIsSharingAccess);
                /* Si el owner del DCI es un team member con N role distinto a Team Leader; aun asi prodra ver los DCIs owned by him VERIFICAR SI TAMBIEN SE DEBE ELIMINAR AUN ASI, SI si
                Descomentar las lineas de abajo y borrar el metodo  removeTeamMembersSharing*/
                /*if(!lstDCIsSharingAccess.isEmpty()) {      
                    try{
                        System.debug('lstDCIsSharingAccessToRemove.size()::: ' + lstDCIsSharingAccess.size());   
                        delete lstDCIsSharingAccess;
                    }catch(Exception objExc) {
                        System.debug('ErrorOnSharingInDCI::: ' + objExc.getMessage());
                    }
                }*/
            }
        }
    }

    /* Method Name: removeTeamMembersSharing
    * Author Name: Alejandro Ramirez
    * Description: method to remove sharing settings for team members
    * Parameters: List<Document_Checklist_Item__c> lstIncomingPrivateDCIs, List<OpportunityTeamMember> lstTeamMembers, List<Document_Checklist_Item__Share> lstDCIsSharingAccess
    * Returns: Void
    */
    private void removeTeamMembersSharing(List<Document_Checklist_Item__c> lstIncomingPrivateDCIs, List<OpportunityTeamMember> lstTeamMembers, List<Document_Checklist_Item__Share> lstDCIsSharingAccess) {
        List<Document_Checklist_Item__Share> lstSharingSetsToDelete = new List<Document_Checklist_Item__Share>();
        for(OpportunityTeamMember objCurrOppTeamMember : lstTeamMembers) {
            for(Document_Checklist_Item__c objCurrDCI : lstIncomingPrivateDCIs) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrDCI.Opportunity__c == objCurrOppTeamMember.OpportunityId && ((objCurrOppTeamMember.UserId != objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId) || (objCurrOppTeamMember.UserId == objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId))) {
                    for(Document_Checklist_Item__Share objCurrDCISharing : lstDCIsSharingAccess) {
                        if(objCurrDCI.IDB_Approver__c != objCurrOppTeamMember.UserId && objCurrDCISharing.UserOrGroupId == objCurrOppTeamMember.UserId && objCurrDCISharing.ParentId == objCurrDCI.Id) {
                            lstSharingSetsToDelete.add(objCurrDCISharing);
                        }
                    }
                }
            }
        }
        if(!lstSharingSetsToDelete.isEmpty()) {      
            try{
                System.debug('DCI_Helper_removeTeamMembersSharing::: ' + lstSharingSetsToDelete.size());   
                delete lstSharingSetsToDelete;
            }catch(Exception objExc) {
                System.debug('Error_removeTeamMembersSharing::: ' + objExc.getMessage());
            }
        }
    }

    /* Method Name: setDCIsOwner
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set DCI owner  when DCI has contains PII = true
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: Void
    */
    private void setDCIsOwner(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers) {
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrDCI.OwnerId != objCurrOTM.UserId && objCurrOTM.IDB_Is_First_Team_Lead__c) {
                        objCurrDCI.OwnerId = objCurrOTM.UserId;
                }
            }
        }
    }

    /* Method Name: getDCIsSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: method to get Sharing DCIs level from the Opportunity Team Members
    * Parameters: Set<Id> setDCIIds
    * Returns: Void
    */
    private List<Document_Checklist_Item__Share> getDCIsSharingAccess(Set<Id> setDCIIds, Set<Id> setOTMsUserIds) {
        List<Document_Checklist_Item__Share> lstSharingDCIs = [
            SELECT Id, RowCause, ParentId, UserOrGroupId, AccessLevel, UserOrGroup.Name 
            FROM Document_Checklist_Item__Share 
            WHERE ParentId IN : setDCIIds AND UserOrGroupId IN : setOTMsUserIds];
        return lstSharingDCIs;
    }

    /* Method Name: setSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: Void
    */
    private void setSharingAccess(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate) {
        List<Document_Checklist_Item__Share> lstNewSharingSettings = new List<Document_Checklist_Item__Share>();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrDCI.IDB_Approver__c != objCurrOTM.UserId && objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrDCI.OwnerId != objCurrOTM.UserId && !objCurrOTM.IDB_Is_First_Team_Lead__c) {
                    Document_Checklist_Item__Share objShareDCI = new Document_Checklist_Item__Share();
                    objShareDCI.ParentId = objCurrDCI.Id;
                    objShareDCI.UserOrGroupId = objCurrOTM.UserId;
                    if(!boolShareForTL && !boolAreDCIsPrivate) {
                        objShareDCI.AccessLevel = 'Read';
                    }else if(boolShareForTL && !boolAreDCIsPrivate) {
                        objShareDCI.AccessLevel = 'Edit';
                    }
                    // Set rowCause to 'manual' for manual sharing.
                    // This line can be omitted as 'manual' is the default value for sharing objects.
                    objShareDCI.RowCause = Schema.Document_Checklist_Item__Share.RowCause.Manual;
                    lstNewSharingSettings.add(objShareDCI);
                }
            }
        }
        if(!lstNewSharingSettings.isEmpty()) {
            // Insert the sharing record.
            System.debug('DCI_Helper_setSharingAccess::: ' + lstNewSharingSettings.size());            
            try{
                insert lstNewSharingSettings;
            }catch(Exception objExc) {
                System.debug('ErrorSetSharingAccessDCI::: ' + objExc.getMessage());
            }
        }
    }

    /* Method Name: setApproverSharingSet
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: Void
    */
    private void setApproverSharingSet(List<Document_Checklist_Item__c> lstIncomingDCIs) {
        List<Document_Checklist_Item__Share> lstNewSharingSettings = new List<Document_Checklist_Item__Share>();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            Document_Checklist_Item__Share objShareDCI = new Document_Checklist_Item__Share();
            objShareDCI.ParentId = objCurrDCI.Id;
            objShareDCI.UserOrGroupId = objCurrDCI.IDB_Approver__c;
            objShareDCI.AccessLevel = 'Edit';
            // Set rowCause to 'manual' for manual sharing.
            // This line can be omitted as 'manual' is the default value for sharing objects.
            objShareDCI.RowCause = Schema.Document_Checklist_Item__Share.RowCause.Manual;
            lstNewSharingSettings.add(objShareDCI);
        }
        if(!lstNewSharingSettings.isEmpty()) {           
            try{
                System.debug('DCI_Helper_setApproverSharingSet::: ' + lstNewSharingSettings.size());
                insert lstNewSharingSettings;
            }catch(Exception objExc) {
                System.debug('Error_DCI_Helper_setApproverSharingSet::: ' + objExc.getMessage());
            }
        }
    }

    /* Method Name: reassignSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to re-Assign sharing sets to approvers accordingly
    * Parameters: List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess
    * Returns: Void
    */
    private void reassignSharingAccess(List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess) {
        //List<Document_Checklist_Item__c> objDCItoUpdate = new List<Document_Checklist_Item__c>();
        if(!lstIncomingDCIsSharingAccess.isEmpty()) {
            for(Document_Checklist_Item__Share objCurrDCISharingSet : lstIncomingDCIsSharingAccess) {
                objCurrDCISharingSet.AccessLevel = 'Edit';
                // Set rowCause to 'manual' for manual sharing.
                // This line can be omitted as 'manual' is the default value for sharing objects.
                //objCurrDCISharingSet.RowCause = Schema.Document_Checklist_Item__Share.RowCause.Manual;
            } 
            try{
                System.debug('DCI_Helper_reassignSharingAccess::: ' + lstIncomingDCIsSharingAccess.size());  
                update lstIncomingDCIsSharingAccess;
            }catch(Exception objExc) {
                System.debug('ErrorOnUpdateSharingSet::: ' + objExc.getMessage());
            }
        }
    }

    /* Method Name: getOTMsUserIds
    * Author Name: Alejandro Ramirez
    * Description: method to get OTM Ids from DCIs
    * Parameters: Set<Id> setOpportunitiesIdIn
    * Returns: List<OpportunityTeamMember>
    */
    private Set<Id> getOTMsUserIds(List<OpportunityTeamMember> lstOTMIn) {
        Set<Id> setOTMsIdsToReturn = new Set<Id>();
        for(OpportunityTeamMember objCurrentOTM : lstOTMIn) {
            setOTMsIdsToReturn.add(objCurrentOTM.UserId);
        }
        return setOTMsIdsToReturn;
    }

    /* Method Name: getSpecificMembers
    * Author Name: Alejandro Ramirez
    * Description: method to get members based on their Opportunity Member role
    * Parameters: List<OpportunityTeamMember>
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getSpecificMembers(List<OpportunityTeamMember> lstIncomingOTMs, boolean boolReturnTL, boolean boolReturnAlternateTL, boolean boolReturnTM) {
        List<OpportunityTeamMember> lstOTMToReturn = new List<OpportunityTeamMember>();
        List<String> lstAlternateTLRole = Label.IDB_Financial_Analyst_Alternate_Investment_Officer_Role.split(';');
        for(OpportunityTeamMember objCurrentOTM : lstIncomingOTMs) {
            if(boolReturnTL && objCurrentOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                    lstOTMToReturn.add(objCurrentOTM);
            }
            if(boolReturnAlternateTL && (objCurrentOTM.TeamMemberRole == lstAlternateTLRole[0] || objCurrentOTM.TeamMemberRole == lstAlternateTLRole[1])) {
                    lstOTMToReturn.add(objCurrentOTM);
            }
            if(boolReturnTM && objCurrentOTM.TeamMemberRole != lstAlternateTLRole[0] && objCurrentOTM.TeamMemberRole != lstAlternateTLRole[1] && objCurrentOTM.TeamMemberRole != Label.IDB_Team_Leader_Role) {
                lstOTMToReturn.add(objCurrentOTM);
            }
        }
        return lstOTMToReturn;
    }

    /* Method Name: getOTMfromDCIs
    * Author Name: Alejandro Ramirez
    * Description: method to get opportunity team members from the opportunity related to the DCI
    * Parameters: Set<Id> setOpportunitiesIdIn
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getOTMfromDCIs(Set<Id> setOpportunitiesIdIn) {
        List<OpportunityTeamMember> lstOTMtoReturn = [
            SELECT Id, OpportunityId, UserId, Name, Title, TeamMemberRole, OpportunityAccessLevel, IDB_Is_First_Team_Lead__c 
            FROM OpportunityTeamMember 
            WHERE OpportunityId IN: setOpportunitiesIdIn];
        return lstOTMtoReturn;
    }

    /* Method Name: getOTM
    * Author Name: Alejandro Ramirez
    * Description: method to get opportunity team member related to the DCI
    * Parameters: Id currentUserId
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getOTM(Id currentUserId) {
        List<OpportunityTeamMember> lstOTMtoReturn = new List<OpportunityTeamMember>();
        lstOTMtoReturn = [
            SELECT Id, OpportunityId, UserId, Name, Title, TeamMemberRole, OpportunityAccessLevel, IDB_Is_First_Team_Lead__c 
            FROM OpportunityTeamMember 
            WHERE UserId =: currentUserId LIMIT 1];
        return lstOTMtoReturn;
    }

    /* Method Name: getSimpleOppIds
    * Author Name: Alejandro Ramirez
    * Description: method to get Opps Ids from DCIs in a simplest way
    * Parameters: List<Document_Checklist_Item__c> lstDCIsIn
    * Returns: Set<Id> setOppIdsToReturn
    */
    private Set<Id> getSimpleOppIds(List<Document_Checklist_Item__c> lstDCIsIn) {
        Set<Id> setOppIdsToReturn = new Set<Id>();
        for(Document_Checklist_Item__c objCurrentDCI : lstDCIsIn) {
            setOppIdsToReturn.add(objCurrentDCI.Opportunity__c);
        }
        return setOppIdsToReturn;
    }

    /* Method Name: getDCIsIds
    * Author Name: Alejandro Ramirez
    * Description: method to get DCI Ids from DCIs
    * Parameters: Set<Id> setOpportunitiesIdIn
    * Returns: List<OpportunityTeamMember>
    */
    private Set<Id> getDCIsIds(List<Document_Checklist_Item__c> lstDCIsIn) {
        Set<Id> setDCIsIdsToReturn = new Set<Id>();
        for(Document_Checklist_Item__c objCurrentDCI : lstDCIsIn) {
            setDCIsIdsToReturn.add(objCurrentDCI.Id);
        }
        return setDCIsIdsToReturn;
    }

    /***********************************
	Class       : DCISectionsInOppsWrapper
	Author      : Alejandro Ramirez
	Date        : 04/05/2021
    Description : Class used to define the count number of DCIs by opp
    *************************************/
    public class DCISectionsInOppsWrapper{
        public Id oppId {get;set;}
        public String strSection {get;set;}
        public Integer intCount {get;set;}
    }
}