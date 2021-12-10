/**********************************************************************************************
* Name          : IDB_OpportunityTeamMember_handler 
* Author        : Alejandro Ramirez
* Description   : Helper class for Trigger on Opportunity Team Member
* Created Date  : 02/06/2021
* Modification Log:
--------------------------------------------------------------------------------------------------------------
LastModifiedBy          | LastModifiedDate      | Modification Id   | Change description
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Alejandro Ramirez       | 02/06/2021            | v1.0              | First Class version Version
*********************************************************************************************/
public with sharing class IDB_OpportunityTeamMember_handler {

    /* Method Name: onBeforeUpdate
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on before update
    * Parameters: OpportunityTeamMember[] oldRecords, OpportunityTeamMember[] updatedRecords, Map<ID, OpportunityTeamMember> oldRecordsMap, Map<ID, OpportunityTeamMember> updatedRecordsMap
    * Returns: Void
    */
    public void onBeforeUpdate(OpportunityTeamMember[] oldRecords, OpportunityTeamMember[] updatedRecords, Map<ID, OpportunityTeamMember> oldRecordsMap, Map<ID, OpportunityTeamMember> updatedRecordsMap) {
        System.debug('OnBeforeUpdateOTM::: ');
        //validateFirstTeamLeadUpdated(oldRecordsMap, updatedRecordsMap);
	}

    /* Method Name: onAfterUpdate
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on after update COMMENTED UNTIL IS BEING IN USE
    * Parameters: None
    * Returns: Void
    */
    public void onAfterUpdate(OpportunityTeamMember[] oldRecords, OpportunityTeamMember[] updatedRecords, Map<ID, OpportunityTeamMember> oldRecordsMap, Map<ID, OpportunityTeamMember> updatedRecordsMap) {
        //Call Methods for logic
        //reassignDCISharingSets(oldRecordsMap, updatedRecordsMap);
    }

    /* Method Name: onBeforeInsert
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on before insert COMMENTED UNTIL IS BEING IN USE
    * Parameters: None
    * Returns: Void
    */
    public void onBeforeInsert(OpportunityTeamMember[] insertedRecords) {
        validateFirstTeamLead(insertedRecords);
    }

    /* Method Name: onAfterInsert
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on after insert
    * Parameters: None
    * Returns: Void
    */
    public void onAfterInsert(OpportunityTeamMember[] insertedRecords) {
        assignDCIsSharingSet(insertedRecords);
    }

    /* Method Name: onBeforeDelete
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on before delete
    * Parameters: OpportunityTeamMember[] oldRecords, Map<ID, OpportunityTeamMember> oldRecordsMap
    * Returns: Void
    */
    public void onBeforeDelete(OpportunityTeamMember[] oldRecords, Map<ID, OpportunityTeamMember> oldRecordsMap) {
        //System.debug('OnBeforeDeleteOTM::: ');
    }

    /* Method Name: onAfterDelete
    * Author Name: Alejandro Ramirez
    * Description: Method triggered on after delete
    * Parameters: None
    * Returns: Void
    */
    public void onAfterDelete(OpportunityTeamMember[] oldRecords, Map<ID, OpportunityTeamMember> oldRecordsMap) {
        //System.debug('OnAfterDeleteOTM::: ');
        removeDCIsSharingSet(oldRecords);
    }

    /****** METHODS TO BUILD LOGIC ******/

    /* Method Name: validateFirstTeamLead
    * Author Name: Alejandro Ramirez
    * Description: method used to set first team Lead if necessary
    * Parameters: OpportunityTeamMember[] insertedRecordsIn
    * Returns: Void
    */
    private void validateFirstTeamLead(OpportunityTeamMember[] insertedRecordsIn) {
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstExistingTeamLeads = new List<OpportunityTeamMember>();
        Set<Id> setTeamLeadsId = new Set<Id>();
        for(OpportunityTeamMember objCurrOTM : insertedRecordsIn) {
            if(objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                lstTeamLeads.add(objCurrOTM);
                setTeamLeadsId.add(objCurrOTM.Id);
            }
        }
        if(!lstTeamLeads.isEmpty()) {
            //set first Team lead if required
            //before set permissions; it must verify if incoming team leads are the first TL on the OppTM so that permissions can be assigned correctly
            Set<Id> setTeamLeadOppsIds = getOppIds(lstTeamLeads);
            lstExistingTeamLeads = getExistingTeamLeads(setTeamLeadOppsIds, setTeamLeadsId);
            List<OpportunityTeamMember> lstLastOppTeamLeaders = getLastRecordOnEachOpp(setTeamLeadOppsIds, lstTeamLeads);
            if(!lstExistingTeamLeads.isEmpty()) {
                for(OpportunityTeamMember objCurrFirstOppTL: lstLastOppTeamLeaders) {
                    if(!searchForExistingPrimaryTL(objCurrFirstOppTL, lstExistingTeamLeads)) {
                        setFirstTeamLead(null, objCurrFirstOppTL, false);
                    }
                }
            }else{
                //Each incoming TL is set as the first TL because the OTM doesnt have any TL
                setFirstTeamLead(lstLastOppTeamLeaders, null, true);
            }
        }
    }

    /* Method Name: validateFirstTeamLeadUpdated
    * Author Name: Alejandro Ramirez
    * Description: method used to set first team Lead if necessary when team role is updated
    * Parameters: Map<ID, OpportunityTeamMember> mapOldRecordsIn, Map<ID, OpportunityTeamMember> mapNewRecordsIn
    * Returns: Void
    */
    /*private void validateFirstTeamLeadUpdated(Map<ID, OpportunityTeamMember> mapOldRecordsIn, Map<ID, OpportunityTeamMember> mapNewRecordsIn) {
        List<OpportunityTeamMember> lstIncomingOTM = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstExistingTeamLeads = new List<OpportunityTeamMember>();
        Set<Id> setAllOTMsIds = new Set<Id>();
        for(Id currentOTMid : mapNewRecordsIn.keySet()) {
            OpportunityTeamMember objCurrentOTM = mapNewRecordsIn.get(currentOTMid);
            if((objCurrentOTM.TeamMemberRole != mapOldRecordsIn.get(objCurrentOTM.id).TeamMemberRole) && objCurrentOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                //when a team member is changed from N role to Team Leader
                lstTeamLeads.add(objCurrentOTM);
                setAllOTMsIds.add(objCurrentOTM.Id);
            }else if((objCurrentOTM.TeamMemberRole != mapOldRecordsIn.get(objCurrentOTM.id).TeamMemberRole) && objCurrentOTM.TeamMemberRole != Label.IDB_Team_Leader_Role) {
                //when a Team leader is changed from Team Leader to N role
                lstTeamMembers.add(objCurrentOTM);
                setAllOTMsIds.add(objCurrentOTM.Id);
            }
            lstIncomingOTM.add(objCurrentOTM);
        }
        Set<Id> setAllOppsIds = getOppIds(lstIncomingOTM);
        lstExistingTeamLeads = getExistingTeamLeads(setAllOppsIds, setAllOTMsIds);
        if(!lstTeamLeads.isEmpty()) {
            //set first Team lead if required
            List<OpportunityTeamMember> lstFirstOppTeamLeaders = getLastRecordOnEachOpp(setAllOppsIds, lstTeamLeads);
            if(!lstExistingTeamLeads.isEmpty()) {
                for(OpportunityTeamMember objCurrFirstOppTL: lstFirstOppTeamLeaders) {
                    if(!searchForExistingPrimaryTL(objCurrFirstOppTL, lstExistingTeamLeads)) {
                        setFirstTeamLead(null, objCurrFirstOppTL, false);
                    }
                }
            }else{
                //Each incoming TL is set as the first TL because the OTM doesnt have any TL
                setFirstTeamLead(lstFirstOppTeamLeaders, null, true);
            }
        }
        if(!lstTeamMembers.isEmpty()) {
            if(!lstExistingTeamLeads.isEmpty()) {
                Set<Id> setExistingFTLOppIds = new Set<Id>();
                List<OpportunityTeamMember> lstExistingPrimaryTL = getSpecificTeamLeads(lstExistingTeamLeads, true, false);
                List<OpportunityTeamMember> lstExistingNoPrimaryTL = getSpecificTeamLeads(lstExistingTeamLeads, false, false);
                if(!lstExistingPrimaryTL.isEmpty()) {
                    setExistingFTLOppIds = getOppIds(lstExistingPrimaryTL);
                }
                if(!lstExistingNoPrimaryTL.isEmpty()) {
                    List<OpportunityTeamMember> lstLastOppTeamLeaders = getLastRecordOnEachOpp(setAllOppsIds, lstExistingNoPrimaryTL);
                    Set<Id> setLastTMOppsIds = getOppIds(lstLastOppTeamLeaders);
                    List<OpportunityTeamMember> lstExistingOTLtoUpdate = new List<OpportunityTeamMember>();
                    //System.debug('lstExistingNoPrimaryTL::: ' + lstExistingNoPrimaryTL.size());
                    if(!setExistingFTLOppIds.isEmpty()) {
                        Set<Id> setOppNeedingForFTLIds = new Set<Id>();
                        for(Id currTMOppId : setLastTMOppsIds) {
                            boolean boolDoesntNeedsFTL = false;
                            for(Id currFTLOppId : setExistingFTLOppIds) {
                                if(currTMOppId == currFTLOppId) {
                                    boolDoesntNeedsFTL = true;
                                }
                            }
                            if(!boolDoesntNeedsFTL) {
                                setOppNeedingForFTLIds.add(currTMOppId);
                            }
                        }
                        if(!setOppNeedingForFTLIds.isEmpty()) {
                            for(Id currOppId : setOppNeedingForFTLIds) {
                                for(OpportunityTeamMember objLastCurrOTMExisting : lstLastOppTeamLeaders) {
                                    if(objLastCurrOTMExisting.OpportunityId == currOppId) {
                                        lstExistingOTLtoUpdate.add(objLastCurrOTMExisting);
                                    }
                                }
                            }
                        }
                        if(!lstExistingOTLtoUpdate.isEmpty()) {
                            setFirstTeamLead(lstExistingOTLtoUpdate, null, true);
                            try{
                                update lstExistingOTLtoUpdate;
                            }catch(Exception objExc) {
                                System.debug('ErrorOnUpdateExistingTL::: ' + objExc.getMessage());
                            }
                        }
                    }else{
                        System.debug('lstLastOppTeamLeaders::: ' + lstLastOppTeamLeaders.size());
                        setFirstTeamLead(lstLastOppTeamLeaders, null, true);
                        try{
                            update lstLastOppTeamLeaders;
                        }catch(Exception objExc) {
                            System.debug('ErrorOnUpdateExistingTL::: ' + objExc.getMessage());
                        }
                    }
                }
                removeFirstTeamLead(lstTeamMembers, null, true);
            }else{
                //Each incoming TL is removed as the first TL because the OTM doesnt have any FTL
                removeFirstTeamLead(lstTeamMembers, null, true);
            }
        }
    }*/

    /* Method Name: assignDCIsSharingSet
    * Author Name: Alejandro Ramirez
    * Description: method used to assing View/Edit sharing settings under DCIs related to the opportunity of the opportunity team member
    * Parameters: OpportunityTeamMember[] insertedRecordsIn
    * Returns: Void
    */
    private void assignDCIsSharingSet(OpportunityTeamMember[] insertedRecordsIn) {
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstAlternateTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        List<Document_Checklist_Item__c> lstPublicDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstPrivateDCIs = new List<Document_Checklist_Item__c>();
        List<String> lstAlternateTLRole = Label.IDB_Financial_Analyst_Alternate_Investment_Officer_Role.split(';');
        List<HelperOTMWrapper> lstOTMHelper = new List<HelperOTMWrapper>();
        for(OpportunityTeamMember objCurrOTM : insertedRecordsIn) {
            if(objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                lstTeamLeads.add(objCurrOTM);
            }else if(objCurrOTM.TeamMemberRole == lstAlternateTLRole[0] || objCurrOTM.TeamMemberRole == lstAlternateTLRole[1]) {
                lstAlternateTeamLeads.add(objCurrOTM);
            }else if(objCurrOTM.TeamMemberRole != lstAlternateTLRole[0] && objCurrOTM.TeamMemberRole != lstAlternateTLRole[1] && objCurrOTM.TeamMemberRole != Label.IDB_Team_Leader_Role) {
                lstTeamMembers.add(objCurrOTM);
            }
        }
        Set<Id> setOpportunitiesId = getOppIds(insertedRecordsIn);
        List<Document_Checklist_Item__c> lstAllDCIs = getAllDCIs(setOpportunitiesId);
        if(!lstAllDCIs.isEmpty()) {
            lstPublicDCIs = getSpecificDCIs(lstAllDCIs, true);
            lstPrivateDCIs = getSpecificDCIs(lstAllDCIs, false);     
            
            if(!lstPublicDCIs.isEmpty()) {
                if(!lstTeamLeads.isEmpty()) {
                    List<OpportunityTeamMember> lstFirstTeamLeads = getSpecificTeamLeads(lstTeamLeads, true, false);
                    List<OpportunityTeamMember> lstSimpleTeamLeads = getSpecificTeamLeads(lstTeamLeads, false, false);
                    if(!lstFirstTeamLeads.isEmpty()) {
                        lstOTMHelper.add(setDCIsOwner(lstPublicDCIs, lstFirstTeamLeads));
                    }
                    if(!lstSimpleTeamLeads.isEmpty()) {
                        lstOTMHelper.add(setSharingAccessOnInsert(lstPublicDCIs, lstSimpleTeamLeads, true, false));
                    }
                }
                if(!lstAlternateTeamLeads.isEmpty()) {
                    lstOTMHelper.add(setSharingAccessOnInsert(lstPublicDCIs, lstAlternateTeamLeads, true, false));
                }
                if(!lstTeamMembers.isEmpty()) {
                    lstOTMHelper.add(setSharingAccessOnInsert(lstPublicDCIs, lstTeamMembers, false, false));
                }
            }
            if(!lstPrivateDCIs.isEmpty()) {
                if(!lstTeamLeads.isEmpty()) {
                    List<OpportunityTeamMember> lstFirstTeamLeads = getSpecificTeamLeads(lstTeamLeads, true, false);
                    List<OpportunityTeamMember> lstSimpleTeamLeads = getSpecificTeamLeads(lstTeamLeads, false, false);
                    if(!lstFirstTeamLeads.isEmpty()) {
                        lstOTMHelper.add(setDCIsOwner(lstPrivateDCIs, lstFirstTeamLeads));
                    }
                    if(!lstSimpleTeamLeads.isEmpty()) {
                        lstOTMHelper.add(setSharingAccessOnInsert(lstPrivateDCIs, lstSimpleTeamLeads, true, true));
                    }
                }
                if(!lstAlternateTeamLeads.isEmpty()) {
                    lstOTMHelper.add(setSharingAccessOnInsert(lstPrivateDCIs, lstAlternateTeamLeads, true, false));
                }
            }
            doDMLStatements(lstOTMHelper);
        }
    }

    /* Method Name: removeDCIsSharingSet
    * Author Name: Alejandro Ramirez
    * Description: removes DCI Sharing Sets acordingly
    * Parameters: List<OpportunityTeamMember> lstOldRecordsIn
    * Returns: Void
    */
    private void removeDCIsSharingSet(List<OpportunityTeamMember> lstOldRecordsIn) {
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        List<Document_Checklist_Item__c> lstPublicDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstPrivateDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstDCIsForNewApprover = new List<Document_Checklist_Item__c>();
        List<OpportunityTeamMember> lstFirstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstSimpleTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstAllExistingTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstAllExistingOppTeamMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstFirstExistingTeamLeads = new List<OpportunityTeamMember> ();
        List<OpportunityTeamMember> lstLastOppExistingTeamLeaders = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstNewFirstTLtoSet = new List<OpportunityTeamMember> ();
        List<HelperOTMWrapper> lstOTMHelper = new List<HelperOTMWrapper>();
        Set<Id> setTeamLeadsId = new Set<Id>();
        Set<Id> setAllOppIds = new Set<Id>();
        for(OpportunityTeamMember objCurrOTM : lstOldRecordsIn) {
            if(objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                lstTeamLeads.add(objCurrOTM);
                setTeamLeadsId.add(objCurrOTM.Id);
            }else{
                lstTeamMembers.add(objCurrOTM);
            }
        }
        setAllOppIds = getOppIds(lstOldRecordsIn);
        List<Document_Checklist_Item__c> lstAllDCIs = getAllDCIs(setAllOppIds);
        //brings in a query ALL EXISTING TEAM MEMBERS from the Opp where the Team lead is being deleted
        lstAllExistingOppTeamMembers = getExistingOppTeamMembers(setAllOppIds, getMembersIds(lstOldRecordsIn));
        if(!lstAllExistingOppTeamMembers.isEmpty()) {
            lstAllExistingTeamLeads = getSpecificTeamLeads(lstAllExistingOppTeamMembers, false, true);
        }
        if(!lstTeamLeads.isEmpty()) {
            //PREPARE SPECIFIC LISTS
            lstFirstTeamLeads = getSpecificTeamLeads(lstTeamLeads, true, false);
            lstSimpleTeamLeads = getSpecificTeamLeads(lstTeamLeads, false, false);
        }
        if(!lstAllExistingTeamLeads.isEmpty()) {
            //below lines are to get extisting non FIRST team lead
            //brings team leads(Non first) if exists for each opp
            List<OpportunityTeamMember> lstNonFirstExistingTeamLeads = getSpecificTeamLeads(lstAllExistingTeamLeads, false, false);
            lstFirstExistingTeamLeads = getSpecificTeamLeads(lstAllExistingTeamLeads, true, false);
            if(!lstNonFirstExistingTeamLeads.isEmpty()) {
                //brings the Opp Id of each existing Team Leader
                Set<Id> setNonFirstExistingTeamLeadsIds = getOppIds(lstNonFirstExistingTeamLeads);
                //brings the last existing Non first Team Lead of each Opp, this list must have one Team Lead(Non first) per Opportunity
                lstLastOppExistingTeamLeaders = getLastRecordOnEachOpp(setNonFirstExistingTeamLeadsIds, lstNonFirstExistingTeamLeads);
                //PREPARE NEW FIRST TEAM LEAD IF REQUIRED
                if(!lstFirstTeamLeads.isEmpty() && !lstLastOppExistingTeamLeaders.isEmpty()) {
                    for(OpportunityTeamMember objCurrOTL : lstFirstTeamLeads) {
                        for(OpportunityTeamMember objCurrOTLExisting : lstLastOppExistingTeamLeaders) {
                            if(objCurrOTL.OpportunityId == objCurrOTLExisting.OpportunityId) {
                                lstNewFirstTLtoSet.add(objCurrOTLExisting);
                            }
                        }
                    }
                    if(!lstNewFirstTLtoSet.isEmpty()) {
                        setFirstTeamLead(lstNewFirstTLtoSet, null, true);
                        lstOTMHelper.add(new HelperOTMWrapper(true, lstNewFirstTLtoSet));
                    }
                }
            }
        }
        
        if(!lstAllDCIs.isEmpty()) {
            boolean boolUpdateDCIs = false;
            lstPublicDCIs = getSpecificDCIs(lstAllDCIs, true);
            lstPrivateDCIs = getSpecificDCIs(lstAllDCIs, false);
            Set<id> setDCIIds = getDCIsIds(lstAllDCIs);

            //PREPARE NEW DCIs OWNER IF FIRST TEAM LEAD WAS REMOVED
            if(!lstNewFirstTLtoSet.isEmpty()) {
                setDCIsOwnerOnDel(lstAllDCIs, lstNewFirstTLtoSet);
                boolUpdateDCIs = true;
            }
            //RE-ASSIGN THE APPROVER TO THE FIRST TEAM LEADER IF THE TEAM MEMBER THAT WAS THE APPROVER WAS REMOVED
            for(OpportunityTeamMember objCurrOTM : lstOldRecordsIn) {
                for(Document_Checklist_Item__c objCurrDCI : lstAllDCIs) {
                    if(objCurrOTM.UserId == objCurrDCI.IDB_Approver__c) {
                        lstDCIsForNewApprover.add(objCurrDCI);
                    }
                }
            }
            if(!lstFirstExistingTeamLeads.isEmpty() || !lstNewFirstTLtoSet.isEmpty()) {
                List<OpportunityTeamMember> lstAllOTL = new List<OpportunityTeamMember>();
                if(!lstFirstExistingTeamLeads.isEmpty()) {
                    for(OpportunityTeamMember objCurrOTL : lstFirstExistingTeamLeads) {
                        lstAllOTL.add(objCurrOTL);
                    }
                }
                if(!lstNewFirstTLtoSet.isEmpty()) {
                    for(OpportunityTeamMember objCurrOTL : lstNewFirstTLtoSet) {
                        lstAllOTL.add(objCurrOTL);
                    }
                }
                if(!lstDCIsForNewApprover.isEmpty() && !lstAllOTL.isEmpty()) {
                    for(OpportunityTeamMember objCurrOTL : lstAllOTL) {
                        for(Document_Checklist_Item__c objCurrDCI : lstDCIsForNewApprover) {
                            if(objCurrDCI.Opportunity__c == objCurrOTL.OpportunityId) {
                                for(Document_Checklist_Item__c objCurrDCIAll : lstAllDCIs) {
                                    if(objCurrDCIAll.Id == objCurrDCI.Id) {
                                        objCurrDCIAll.IDB_Approver__c = objCurrOTL.UserId;
                                        boolUpdateDCIs = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(boolUpdateDCIs) {
                HelperOTMWrapper objWrapper = new HelperOTMWrapper();
                objWrapper.boolForDCIs = true;
                objWrapper.lstDCIs = lstAllDCIs;
                lstOTMHelper.add(objWrapper);
            }
            doDMLStatements(lstOTMHelper);
            lstOTMHelper = new List<HelperOTMWrapper>();
            //System.debug('lstOTMHelperOnDeleteAndReassign::: ' + lstOTMHelper.size());
            List<Document_Checklist_Item__Share> lstDCIsSharingAccess = getDCIsSharingAccess(setDCIIds);

            //Brings back the sharing access if the existing team members lost their access
            if(!lstPublicDCIs.isEmpty()) {
                if(!lstAllExistingOppTeamMembers.isEmpty() && !lstNewFirstTLtoSet.isEmpty()) {
                    lstOTMHelper.add(setSharingAccessOnDelete(lstPublicDCIs, lstAllExistingOppTeamMembers, lstNewFirstTLtoSet));
                }
            }
            if(!lstPrivateDCIs.isEmpty()) {
                if(!lstAllExistingOppTeamMembers.isEmpty() && !lstNewFirstTLtoSet.isEmpty()) {
                    lstOTMHelper.add(setSharingAccessOnDelete(lstPrivateDCIs, lstAllExistingOppTeamMembers, lstNewFirstTLtoSet));
                }
            }
            //System.debug('lstOTMHelperOnDeleteAndReassignAfter::: ' + lstOTMHelper.size());
            doDMLStatements(lstOTMHelper);

            if(!lstPublicDCIs.isEmpty()) {
                if(!lstTeamLeads.isEmpty()) {
                    //permissions on public DCIs are removed for the deleted Team Leaders
                    removeSharingAccess(lstPublicDCIs, lstDCIsSharingAccess, lstTeamLeads);
                }
                if(!lstTeamMembers.isEmpty()) {
                    removeSharingAccess(lstPublicDCIs, lstDCIsSharingAccess, lstTeamMembers);
                }
            }
            if(!lstPrivateDCIs.isEmpty()) {
                //Set<id> setPrivateDCIIds = getDCIsIds(lstPrivateDCIs);
                //List<Document_Checklist_Item__Share> lstPrivateDCIsSharingAccess = getDCIsSharingAccess(setPrivateDCIIds);
                if(!lstTeamLeads.isEmpty()) {
                    removeSharingAccess(lstPrivateDCIs, lstDCIsSharingAccess, lstTeamLeads);
                }
            }
        }
    }

    /* Method Name: reassignDCISharingSets
    * Author Name: Alejandro Ramirez
    * Description: If team Lead Is updated to another role and it was already owner of DCIs then it reassigns the owner to the corresponding users
    * Parameters: Map<ID, Document_Checklist_Item__c> mapOldRecordsIn, Map<ID, Document_Checklist_Item__c> mapNewRecordsIn
    * Returns: Void
    */
    /*private void reassignDCISharingSets(Map<ID, OpportunityTeamMember> mapOldRecordsIn, Map<ID, OpportunityTeamMember> mapNewRecordsIn) {
        //it has the list of the updated team members to team leads
        List<OpportunityTeamMember> lstIncomingOTM = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamLeads = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstAllExistingTeamLeads = new List<OpportunityTeamMember>();
        List<Document_Checklist_Item__c> lstPublicDCIs = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__c> lstPrivateDCIs = new List<Document_Checklist_Item__c>();
        Set<Id> setAllOTMsIds = new Set<Id>();
        for(Id currentOTMid : mapNewRecordsIn.keySet()) {
            OpportunityTeamMember objCurrentOTM = mapNewRecordsIn.get(currentOTMid);
            if((objCurrentOTM.TeamMemberRole != mapOldRecordsIn.get(objCurrentOTM.id).TeamMemberRole) && objCurrentOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                //when a team member is changed from N role to Team Leader
                lstTeamLeads.add(objCurrentOTM);
                setAllOTMsIds.add(objCurrentOTM.Id);
            }else if((objCurrentOTM.TeamMemberRole != mapOldRecordsIn.get(objCurrentOTM.id).TeamMemberRole) && objCurrentOTM.TeamMemberRole != Label.IDB_Team_Leader_Role) {
                //when a Team member is changed from Team Leader to N role
                lstTeamMembers.add(objCurrentOTM);
                setAllOTMsIds.add(objCurrentOTM.Id);
            }
            lstIncomingOTM.add(objCurrentOTM);
        }
        //Takes the Opp Ids where ALL New Team Leads are comming*****
        Set<Id> setAllOppsIds = getOppIds(lstIncomingOTM);
        //brings in a QUERY all existing Team Leads from the Opp where the Team lead is being updated*****
        lstAllExistingTeamLeads = getExistingTeamLeads(setAllOppsIds, setAllOTMsIds);
        //Brings DCIs of All updated Opportunity records
        List<Document_Checklist_Item__c> lstAllDCIs = getAllDCIs(setAllOppsIds);

        if(!lstAllDCIs.isEmpty()) {
            lstPublicDCIs = getSpecificDCIs(lstAllDCIs, true);
            lstPrivateDCIs = getSpecificDCIs(lstAllDCIs, false);
            Set<id> setAllDCIsIds = getDCIsIds(lstAllDCIs);
            //Brings sharing access of all DCIs related to the OTMs*****
            List<Document_Checklist_Item__Share> lstAllDCIsSharingAccess = getDCIsSharingAccess(setAllDCIsIds);
            System.debug('lstAllDCIsSharingAccess::: ' + lstAllDCIsSharingAccess.size());    
            
            if(!lstPublicDCIs.isEmpty()) {
                if(!lstTeamMembers.isEmpty()) {
                    //As it was TL they had Write permissions, but now they are TM so they must have Read permissions under public DCIs
                    //se deben remover los permisos que tenian anteriormente y volver a insertar nuevos
                    System.debug('public DCIS + TM::: ');
                    removeSharingAccess(lstPublicDCIs, lstAllDCIsSharingAccess, lstTeamMembers);
                    setSharingAccess(lstPublicDCIs, lstTeamMembers, false, false);
                    //reassignSharingAccess(lstPublicDCIs, lstAllDCIsSharingAccess, lstTeamMembers, true, true);
                }
                if(!lstTeamLeads.isEmpty()) {
                    ////As it was TM they had Read permissions, but now they are TL so they must have Write permissions under public DCIs
                    System.debug('public DCIS + TL::: ');
                    removeSharingAccess(lstPublicDCIs, lstAllDCIsSharingAccess, lstTeamLeads);
                    setSharingAccess(lstPublicDCIs, lstTeamLeads, true, false);
                    //reassignSharingAccess(lstPublicDCIs, lstAllDCIsSharingAccess, lstTeamLeads, true, false);
                }
            }
            if(!lstPrivateDCIs.isEmpty()) {
                //before update permissions; it must verify if still exists the first team lead on the OppTM so that permissions can be removed correctly
                boolean boolUpdatePrivateDCIs = false;
                List<OpportunityTeamMember> lstUpdatedNoFirstTeamLeads = getSpecificTeamLeads(lstTeamLeads, false, false);
                if(!lstUpdatedNoFirstTeamLeads.isEmpty()) {
                    //Creates read permissions under Private DCIs because they dont have any permmision under it
                    setSharingAccess(lstPrivateDCIs, lstUpdatedNoFirstTeamLeads, true, true);
                }
                if(!lstAllExistingTeamLeads.isEmpty()) {
                    //searches from Existing Team Leads and brings team leads(FIRST) if exists for each opp
                    List<OpportunityTeamMember> lstFirstExistingTeamLeads = getSpecificTeamLeads(lstAllExistingTeamLeads, true, false);
                    //searches from updated Team Leads and brings team leads(FIRST) if exists for each opp
                    List<OpportunityTeamMember> lstFirstUpdatedTeamLeads = getSpecificTeamLeads(lstTeamLeads, true, false);
                    //needs to search for each opp if First Team Leader is there on updated records or existing ones
                    if(!lstTeamLeads.isEmpty()) {
                        System.debug('private DCIS + TL + Existing TL::: ');
                        List<OpportunityTeamMember> lstFirstTeamLeadsForOwners = new List<OpportunityTeamMember>();
                        for(Id currOppId : setAllOppsIds) {
                            boolean boolHasFTL = false;
                            //assuming that it will be only one First team lead per opportunity
                            if(!lstFirstExistingTeamLeads.isEmpty()) {
                                for(OpportunityTeamMember objCurrExistingOTL : lstFirstExistingTeamLeads) {
                                    if(currOppId == objCurrExistingOTL.OpportunityId) {
                                        lstFirstTeamLeadsForOwners.add(objCurrExistingOTL);
                                        boolHasFTL = true;
                                        break;
                                    }
                                }
                            }
                            if(!lstFirstUpdatedTeamLeads.isEmpty() && !boolHasFTL) {
                                for(OpportunityTeamMember objCurrUpdatedOTL : lstFirstUpdatedTeamLeads) {
                                    if(currOppId == objCurrUpdatedOTL.OpportunityId) {
                                        lstFirstTeamLeadsForOwners.add(objCurrUpdatedOTL);
                                        break;
                                    }
                                }
                            }
                        }
                        if(!lstFirstTeamLeadsForOwners.isEmpty()) {
                            reassignDCIsOwner(lstPrivateDCIs, lstFirstTeamLeadsForOwners, true, null, false);
                            boolUpdatePrivateDCIs = true;
                        }
                        
                        reassignSharingAccess(lstPrivateDCIs, lstAllDCIsSharingAccess, lstTeamLeads, false, false);
                    }
                    if(!lstTeamMembers.isEmpty()) {
                        //System.debug('It comes here only::: ');
                        if(!lstFirstExistingTeamLeads.isEmpty()) {
                            System.debug('It comes here only_reassignDCIsOwner::: ');
                            reassignDCIsOwner(lstPrivateDCIs, lstFirstExistingTeamLeads, true, null, false);
                            try{
                                //System.debug('Update private DCIs::: ' + lstPrivateDCIs.size());
                                update lstPrivateDCIs;
                            }catch(Exception objExc) {
                                System.debug('ErrorUpdatingPrivateDCIs::: ' + objExc.getMessage());
                            }
                        }
                        removeSharingAccess(lstPrivateDCIs, lstAllDCIsSharingAccess, lstTeamMembers);
                    }
                }else{
                    if(!lstTeamLeads.isEmpty()) {
                        //if some of the TL updated comes as First Team Leader then existing private DCIs must have as owner the new First TL updated
                        //brings team leads(FIRST)
                        List<OpportunityTeamMember> lstFirstNewTeamLeads = getSpecificTeamLeads(lstTeamLeads, true, false);
                        System.debug('private DCIS + !TL::: ');
                        if(!lstFirstNewTeamLeads.isEmpty()) {
                            reassignDCIsOwner(lstPrivateDCIs, lstFirstNewTeamLeads, true, null, false);
                            boolUpdatePrivateDCIs = true;
                        }
                        //removeSharingAccess(lstPrivateDCIs, lstAllDCIsSharingAccess, lstTeamLeads);
                        //setSharingAccess(lstPrivateDCIs, lstTeamLeads, true, true);
                        reassignSharingAccess(lstPrivateDCIs, lstAllDCIsSharingAccess, lstTeamLeads, false, false);
                    }

                    if(!lstTeamMembers.isEmpty() && lstTeamLeads.isEmpty()) {
                        //when only TL were updated to TM
                        System.debug('private DCIS + !TM TL::: ');
                        reassignDCIsOwner(lstPrivateDCIs, null, false, null, false);
                        boolUpdatePrivateDCIs = true;
                        //It doesnt excecute anything else because as it was the owner of private records, salesforce automatically deletes sharing access when the owner changes
                    }
                    if(!lstTeamMembers.isEmpty() && !lstTeamLeads.isEmpty()) {
                        //when only TL were updated to TM of all Opps
                        System.debug('private DCIS + !TM !TL::: ');
                        //removeSharingAccess(lstPrivateDCIs, lstAllDCIsSharingAccess, lstTeamMembers);
                    }
                }
                if(boolUpdatePrivateDCIs) {
                    try{
                        System.debug('Update private DCIs::: ' + lstPrivateDCIs.size());
                        update lstPrivateDCIs;
                    }catch(Exception objExc) {
                        System.debug('ErrorUpdatingPrivateDCIs::: ' + objExc.getMessage());
                    }
                }
            }
        }
    }*/

    /****** SECONDARY METHODS ******/

    /* Method Name: getOppIds
    * Author Name: Alejandro Ramirez
    * Description: method to get Opps Ids from the inserted Opportunity Team Members
    * Parameters: List<OpportunityTeamMember> insertedRecordsIn
    * Returns: Set<Id>
    */
    private Set<Id> getOppIds(List<OpportunityTeamMember> lstRecordsIn) {
        Set<Id> oppIdsToReturn = new Set<Id>();
        for(OpportunityTeamMember objCurrOppTeamMember : lstRecordsIn) {
            oppIdsToReturn.add(objCurrOppTeamMember.OpportunityId);
        }
        return oppIdsToReturn;
    }

    /* Method Name: getMembersIds
    * Author Name: Alejandro Ramirez
    * Description: method to get User Ids from theOpportunity Team Members
    * Parameters: List<OpportunityTeamMember> insertedRecordsIn
    * Returns: Set<Id>
    */
    private Set<Id> getMembersIds(List<OpportunityTeamMember> lstRecordsIn) {
        Set<Id> memberIdsToReturn = new Set<Id>();
        for(OpportunityTeamMember objCurrOppTeamMember : lstRecordsIn) {
            memberIdsToReturn.add(objCurrOppTeamMember.UserId);
        }
        return memberIdsToReturn;
    }

    /* Method Name: getAllDCIs
    * Author Name: Alejandro Ramirez
    * Description: method to get DCIs from the inserted Opportunity Team Members
    * Parameters: Set<Id> setOpportunitiesId
    * Returns: Void
    */
    private List<Document_Checklist_Item__c> getAllDCIs(Set<Id> setOpportunitiesId) {
        List<Document_Checklist_Item__c> lstDCIToReturn = new List<Document_Checklist_Item__c>();
        lstDCIToReturn = [
            SELECT id, OwnerId, Opportunity__c, Section__c, Identifier__c, IDB_Approver__c, CreatedById, CreatedBy.Name, Contains_PII__c 
            FROM Document_Checklist_Item__c 
            WHERE Opportunity__c IN: setOpportunitiesId];
        return lstDCIToReturn;
    }

    /* Method Name: getSpecificDCIs
    * Author Name: Alejandro Ramirez
    * Description: method to get specific DCIs depending on the parameters
    * Parameters: Set<Id> setOpportunitiesId
    * Returns: Void
    */
    private List<Document_Checklist_Item__c> getSpecificDCIs(List<Document_Checklist_Item__c> lstIncomingDCIs, boolean boolGetPublics) {
        List<Document_Checklist_Item__c> lstDCIToReturn = new List<Document_Checklist_Item__c>();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            if(boolGetPublics) {
                if(!objCurrDCI.Contains_PII__c) {
                    lstDCIToReturn.add(objCurrDCI);
                }
            }else{
                if(objCurrDCI.Contains_PII__c) {
                    lstDCIToReturn.add(objCurrDCI);
                }
            }
        }
        return lstDCIToReturn;
    }

    /* Method Name: setSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate
    * Returns: void
    */
    /*private void setSharingAccess(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate) {
        List<Document_Checklist_Item__Share> lstNewSharingSettings = new List<Document_Checklist_Item__Share>();
        List<Document_Checklist_Item__c> objDCItoUpdate = new List<Document_Checklist_Item__c>();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrDCI.OwnerId != objCurrOTM.UserId) {
                    Document_Checklist_Item__Share objShareDCI = new Document_Checklist_Item__Share();
                    objShareDCI.ParentId = objCurrDCI.Id;
                    objShareDCI.UserOrGroupId = objCurrOTM.UserId;
                    if(!boolShareForTL && !boolAreDCIsPrivate) {
                        objShareDCI.AccessLevel = 'Read';
                    }else if(boolShareForTL && boolAreDCIsPrivate) {
                        objShareDCI.AccessLevel = 'Edit';
                        if(objCurrOTM.IDB_Is_First_Team_Lead__c) {
                            objCurrDCI.OwnerId = objCurrOTM.UserId;
                            objCurrDCI.IDB_Approver__c = objCurrOTM.UserId;
                            objDCItoUpdate.add(objCurrDCI);
                        }
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
        if(!objDCItoUpdate.isEmpty()) {
            try {
                System.debug('objDCItoUpdate::: ');
                update objDCItoUpdate;
            }catch(Exception objExc) {
                System.debug('ErrorOnSharingAccess::: ' + objExc.getMessage());
            }
        }
        if(!lstNewSharingSettings.isEmpty()) {
            // Insert the sharing record.
            System.debug('lstNewSharingSettings.size()::: ' + lstNewSharingSettings.size());            
            try{
                insert lstNewSharingSettings;
            }catch(Exception objExc) {
                System.debug('ErrorOnSharingInDCI::: ' + objExc.getMessage());
            }
        }
    }*/

    /* Method Name: setSharingAccessOnInsert
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate
    * Returns: HelperOTMWrapper
    */
    private HelperOTMWrapper setSharingAccessOnInsert(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate) {
        List<Document_Checklist_Item__Share> lstNewSharingSettings = new List<Document_Checklist_Item__Share>();
        HelperOTMWrapper objWrapperToReturn = new HelperOTMWrapper();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrDCI.OwnerId != objCurrOTM.UserId) {
                    Document_Checklist_Item__Share objShareDCI = new Document_Checklist_Item__Share();
                    objShareDCI.ParentId = objCurrDCI.Id;
                    objShareDCI.UserOrGroupId = objCurrOTM.UserId;
                    if(!boolShareForTL && !boolAreDCIsPrivate) {
                        objShareDCI.AccessLevel = 'Read';
                    }else if((boolShareForTL && !boolAreDCIsPrivate) || (boolShareForTL && boolAreDCIsPrivate)) {
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
            objWrapperToReturn.lstSharingSettings = lstNewSharingSettings;
            objWrapperToReturn.boolForDCIsSharing = true;
            objWrapperToReturn.boolForDCIs = false;
        }
        return objWrapperToReturn;
    }

    /* Method Name: setSharingAccessOnDelete
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, boolean boolShareForTL, boolean boolAreDCIsPrivate
    * Returns: HelperOTMWrapper
    */
    private HelperOTMWrapper setSharingAccessOnDelete(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers, List<OpportunityTeamMember> lstNewFirstTLtoSet) {
        List<Document_Checklist_Item__Share> lstNewSharingSettings = new List<Document_Checklist_Item__Share>();
        HelperOTMWrapper objWrapperToReturn = new HelperOTMWrapper();
        List<String> lstAlternateTLRole = Label.IDB_Financial_Analyst_Alternate_Investment_Officer_Role.split(';');
        for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
            for(OpportunityTeamMember objCurrFirstTL : lstNewFirstTLtoSet) {
                if(objCurrOTM.UserId != objCurrFirstTL.UserId && objCurrOTM.OpportunityId == objCurrFirstTL.OpportunityId) {
                    for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
                        if(objCurrDCI.Opportunity__c == objCurrOTM.OpportunityId) {
                            Document_Checklist_Item__Share objShareDCI = new Document_Checklist_Item__Share();
                            objShareDCI.ParentId = objCurrDCI.Id;
                            objShareDCI.UserOrGroupId = objCurrOTM.UserId;
                            if(objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role || objCurrOTM.TeamMemberRole == lstAlternateTLRole[0] || objCurrOTM.TeamMemberRole == lstAlternateTLRole[1] || (objCurrOTM.TeamMemberRole != Label.IDB_Team_Leader_Role && objCurrOTM.UserId == objCurrDCI.IDB_Approver__c)) {
                                objShareDCI.AccessLevel = 'Edit';
                            }else if(objCurrOTM.TeamMemberRole != Label.IDB_Team_Leader_Role && objCurrOTM.UserId != objCurrDCI.IDB_Approver__c && !objCurrDCI.Contains_PII__c) {
                                objShareDCI.AccessLevel = 'Read';
                            }
                            // Set rowCause to 'manual' for manual sharing.
                            // This line can be omitted as 'manual' is the default value for sharing objects.
                            objShareDCI.RowCause = Schema.Document_Checklist_Item__Share.RowCause.Manual;
                            //if access level comes null it means the team member is not a team leader, neiter is approver of a private DCI therefore this kind of user must not be having permissions under that private DCI
                            if(objShareDCI.AccessLevel != null) {
                                lstNewSharingSettings.add(objShareDCI);
                            }
                        }
                    }
                }
            }
        }
        if(!lstNewSharingSettings.isEmpty()) {
            objWrapperToReturn.lstSharingSettings = lstNewSharingSettings;
            objWrapperToReturn.boolForDCIsSharing = true;
        }
        return objWrapperToReturn;
    }

    /* Method Name: getExistingTeamLeads
    * Author Name: Alejandro Ramirez
    * Description: method to get existing team members with Team Lead as role from specific Opps
    * Parameters: Set<Id> setOpportunitiesIdIn, set<Id> setIncomingOTM
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getExistingTeamLeads(Set<Id> setOpportunitiesIdIn, set<Id> setIncomingOTM) {
        List<OpportunityTeamMember> lstOTMToReturn = new List<OpportunityTeamMember>();
        lstOTMToReturn = [
            SELECT Id, OpportunityId, UserId, Name, Title, TeamMemberRole, OpportunityAccessLevel, IDB_Is_First_Team_Lead__c, Email_Address__c, Phone_Number__c
            FROM OpportunityTeamMember
            WHERE OpportunityId IN : setOpportunitiesIdIn AND TeamMemberRole =: Label.IDB_Team_Leader_Role AND Id NOT IN : setIncomingOTM];
        return lstOTMToReturn;
    }

    /* Method Name: getExistingOppTeamMembers
    * Author Name: Alejandro Ramirez
    * Description: method to get existing team members
    * Parameters: Set<Id> setOpportunitiesIdIn, set<Id> setIncomingOTM
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getExistingOppTeamMembers(Set<Id> setOpportunitiesIdIn, set<Id> setIncomingOTM) {
        List<OpportunityTeamMember> lstOTMToReturn = new List<OpportunityTeamMember>();
        lstOTMToReturn = [
            SELECT Id, OpportunityId, UserId, Name, Title, TeamMemberRole, OpportunityAccessLevel, IDB_Is_First_Team_Lead__c, Email_Address__c, Phone_Number__c
            FROM OpportunityTeamMember
            WHERE OpportunityId IN : setOpportunitiesIdIn AND Id NOT IN : setIncomingOTM];
        return lstOTMToReturn;
    }

    /* Method Name: getLastRecordOnEachOpp
    * Author Name: Alejandro Ramirez
    * Description: method to get the last record for each opp
    * Parameters: List<OpportunityTeamMember> lstOTMtoValidate, List<OpportunityTeamMember> lstExistingTeamLeads
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getLastRecordOnEachOpp(Set<Id> setOpportunitiesId, List<OpportunityTeamMember> lstIncomingOTM) {
        List<OpportunityTeamMember> lstOTMtoReturn = new List<OpportunityTeamMember>();
        for(Id currOppId : setOpportunitiesId) {
            OpportunityTeamMember objOTMToUpdate = new OpportunityTeamMember();
            for(OpportunityTeamMember objCurrOTM : lstIncomingOTM) {
                if(currOppId == objCurrOTM.OpportunityId) {
                    objOTMToUpdate = objCurrOTM;
                }
            }
            lstOTMtoReturn.add(objOTMToUpdate);
        }
        return lstOTMtoReturn;
    }

    /* Method Name: setFirstTeamLead
    * Author Name: Alejandro Ramirez
    * Description: Set the incoming opportunity team member as first team lead
    * Parameters: List<OpportunityTeamMember> lstIncomingOTM
    * Returns: Void
    */
    private void setFirstTeamLead(List<OpportunityTeamMember> lstIncomingOTM, OpportunityTeamMember objIncomingOTM, boolean boolSetFromList) {
        if(boolSetFromList) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingOTM) {
                objCurrOTM.IDB_Is_First_Team_Lead__c = true;
            }
        }else{
            objIncomingOTM.IDB_Is_First_Team_Lead__c = true;
        }
    }

    /* Method Name: removeFirstTeamLead
    * Author Name: Alejandro Ramirez
    * Description: set the incoming opportunity team member as no first team lead if it was before
    * Parameters: List<OpportunityTeamMember> lstIncomingOTM
    * Returns: Void
    */
    private void removeFirstTeamLead(List<OpportunityTeamMember> lstIncomingOTM, OpportunityTeamMember objIncomingOTM, boolean boolRemoveFromList) {
        if(boolRemoveFromList) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingOTM) {
                objCurrOTM.IDB_Is_First_Team_Lead__c = false;
            }
        }else{
            objIncomingOTM.IDB_Is_First_Team_Lead__c = false;
        }
    }

    /* Method Name: searchForExistingPrimaryTL
    * Author Name: Alejandro Ramirez
    * Description: Search for existing primary team lead
    * Parameters: OpportunityTeamMember objFirstIncomingOppTeamLeader, List<OpportunityTeamMember> lstExistingTeamLeads
    * Returns: boolean boolHasAlreadyTL
    */
    private boolean searchForExistingPrimaryTL(OpportunityTeamMember objFirstIncomingOppTeamLeader, List<OpportunityTeamMember> lstExistingTeamLeads) {
        boolean boolHasAlreadyTL = false;
        for(OpportunityTeamMember objCurrExistingTL : lstExistingTeamLeads) {
            if(objFirstIncomingOppTeamLeader.OpportunityId == objCurrExistingTL.OpportunityId && objCurrExistingTL.IDB_Is_First_Team_Lead__c == true) {
                boolHasAlreadyTL = true;
            }
        }
        return boolHasAlreadyTL;
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

    /* Method Name: getSpecificTeamLeads
    * Author Name: Alejandro Ramirez
    * Description: Method to return team leaders accordingly the parameters
    * Parameters: List<OpportunityTeamMember> lstIncomingOTM, boolean boolGetFirstTeamLeaders
    * Returns: List<OpportunityTeamMember>
    */
    private List<OpportunityTeamMember> getSpecificTeamLeads(List<OpportunityTeamMember> lstIncomingOTM, boolean boolGetFirstTeamLeaders, boolean boolGetAllTeamLeaders) {
        List<OpportunityTeamMember> lstOTMtoReturn = new List<OpportunityTeamMember>();
        for(OpportunityTeamMember objCurrOTM : lstIncomingOTM) {
            if(!boolGetAllTeamLeaders && boolGetFirstTeamLeaders && objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role && objCurrOTM.IDB_Is_First_Team_Lead__c) {
                lstOTMtoReturn.add(objCurrOTM);
            }else if(!boolGetAllTeamLeaders && !boolGetFirstTeamLeaders && objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role && !objCurrOTM.IDB_Is_First_Team_Lead__c) {
                lstOTMtoReturn.add(objCurrOTM);
            }else if(boolGetAllTeamLeaders && objCurrOTM.TeamMemberRole == Label.IDB_Team_Leader_Role) {
                lstOTMtoReturn.add(objCurrOTM);
            }
        }
        return lstOTMtoReturn;
    }

    /* Method Name: removeSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: Method to remove sharing access to team members/Leaders
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess, List<OpportunityTeamMember> lstIncomingOTM
    * Returns: Void
    */
    private void removeSharingAccess(List<Document_Checklist_Item__c> lstIncomingDCIs, List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess, List<OpportunityTeamMember> lstIncomingOTM) {
        List<Document_Checklist_Item__Share> lstSharingSetsToDelete = new List<Document_Checklist_Item__Share>();
        System.debug('lstIncomingDCIsSharingAccess.size()::: ' + lstIncomingDCIsSharingAccess.size());
        if(lstIncomingDCIsSharingAccess != null || !lstIncomingDCIsSharingAccess.isEmpty()) {
            for(Document_Checklist_Item__Share objCurrDCISharing : lstIncomingDCIsSharingAccess) {
                for(OpportunityTeamMember objCurrOppTeamMember : lstIncomingOTM) {
                    for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
                        if(objCurrDCISharing.UserOrGroupId == objCurrOppTeamMember.UserId && objCurrDCISharing.ParentId == objCurrDCI.Id &&
                        objCurrDCI.IDB_Approver__c != objCurrOppTeamMember.UserId && objCurrOppTeamMember.OpportunityId == objCurrDCI.Opportunity__c && 
                        ((objCurrOppTeamMember.UserId != objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId) || 
                        (objCurrOppTeamMember.UserId == objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId))) {
                            lstSharingSetsToDelete.add(objCurrDCISharing);
                        }
                    }
                }
            }

            /*for(OpportunityTeamMember objCurrOppTeamMember : lstIncomingOTM) {
                for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
                    for(Document_Checklist_Item__Share objCurrDCISharing : lstIncomingDCIsSharingAccess) {
                        //Searches for DCIs that were not created by the deleted OTM
                        if(objCurrDCI.IDB_Approver__c != objCurrOppTeamMember.UserId && objCurrOppTeamMember.OpportunityId == objCurrDCI.Opportunity__c && ((objCurrOppTeamMember.UserId != objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId) || (objCurrOppTeamMember.UserId == objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId))) {
                            if(objCurrDCISharing.UserOrGroupId == objCurrOppTeamMember.UserId && objCurrDCISharing.ParentId == objCurrDCI.Id) {
                                lstSharingSetsToDelete.add(objCurrDCISharing);
                            }
                        }
                    }
                }
            }*/
            if(!lstSharingSetsToDelete.isEmpty()) {
                System.debug('removeSharingAccess::: ' + lstSharingSetsToDelete.size());   
                try{
                    delete lstSharingSetsToDelete;
                }catch(Exception objExc) {
                    System.debug('ErrorOnRemoveSharingAccess::: ' + objExc.getMessage());
                }
            }
        }
    }

    /* Method Name: reassignDCIsOwner
    * Author Name: Alejandro Ramirez
    * Description: it reassigns the owner to the corresponding users acordingly
    * Parameters: List<OpportunityTeamMember> lstOldRecordsIn
    * Returns: Void
    */
    private void reassignDCIsOwner(List<Document_Checklist_Item__c> lstPrivateDCIs, List<OpportunityTeamMember> lstIncomingOTM, boolean boolExistsTeamLeaders, Set<Id> setOppsToSetOwnerAsApprover, boolean boolOppsForApproverOwner) {
        if(!boolExistsTeamLeaders && !boolOppsForApproverOwner) {
            for(Document_Checklist_Item__c objCurrDCI : lstPrivateDCIs) {
                objCurrDCI.OwnerId = objCurrDCI.IDB_Approver__c;
            }
        }
        if(boolExistsTeamLeaders && !boolOppsForApproverOwner) {
            for(Document_Checklist_Item__c objCurrDCI : lstPrivateDCIs) {
                for(OpportunityTeamMember objCurrOTM : lstIncomingOTM) {
                    if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c) {
                        objCurrDCI.OwnerId = objCurrOTM.UserId;
                        objCurrDCI.IDB_Approver__c = objCurrOTM.UserId;
                    }
                }
            }
        }
        if(!boolExistsTeamLeaders && boolOppsForApproverOwner) {
            for(Document_Checklist_Item__c objCurrDCI : lstPrivateDCIs) {
                for(Id currOppId : setOppsToSetOwnerAsApprover) {
                    if(currOppId == objCurrDCI.Opportunity__c) {
                        objCurrDCI.OwnerId = objCurrDCI.IDB_Approver__c;
                    }
                }
            }
        }
    }

    /* Method Name: reassignSharingAccess
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to re-Assign sharing sets to team members accordingly
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess, List<OpportunityTeamMember> lstIncomingOTM, boolean boolAreDCIsPublic, boolean boolAreTeamMembers
    * Returns: Void
    */
    private void reassignSharingAccess(List<Document_Checklist_Item__c> lstIncomingDCIs, List<Document_Checklist_Item__Share> lstIncomingDCIsSharingAccess, List<OpportunityTeamMember> lstIncomingOTM, boolean boolAreDCIsPublic, boolean boolAreTeamMembers) {
        List<Document_Checklist_Item__Share> lstSharingSetsToUpdate = new List<Document_Checklist_Item__Share>();
        //List<Document_Checklist_Item__c> objDCItoUpdate = new List<Document_Checklist_Item__c>();
        if(!lstIncomingDCIsSharingAccess.isEmpty()) {
            for(OpportunityTeamMember objCurrOppTeamMember : lstIncomingOTM) {
                for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
                    for(Document_Checklist_Item__Share objCurrDCISharing : lstIncomingDCIsSharingAccess) {
                        //Searches for DCIs that were not created by the deleted OTM
                        if(objCurrOppTeamMember.OpportunityId == objCurrDCI.Opportunity__c && ((objCurrOppTeamMember.UserId != objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId) || (objCurrOppTeamMember.UserId == objCurrDCI.CreatedById && objCurrOppTeamMember.UserId != objCurrDCI.OwnerId))) {
                            /*if(objCurrOppTeamMember.IDB_Is_First_Team_Lead__c) {
                                objCurrDCI.OwnerId = objCurrOppTeamMember.UserId;
                                objDCItoUpdate.add(objCurrDCI);
                            }*/
                            if(objCurrDCISharing.UserOrGroupId == objCurrOppTeamMember.UserId && objCurrDCISharing.ParentId == objCurrDCI.Id) {
                                lstSharingSetsToUpdate.add(objCurrDCISharing);
                            }
                        }
                    }
                }
            }
            if(!lstSharingSetsToUpdate.isEmpty()) {
                for(Document_Checklist_Item__Share objCurrDCISharingSet : lstSharingSetsToUpdate) {
                    if(boolAreDCIsPublic && boolAreTeamMembers) {
                        objCurrDCISharingSet.AccessLevel = 'Read';
                    }else if(boolAreDCIsPublic && !boolAreTeamMembers) {
                        objCurrDCISharingSet.AccessLevel = 'Edit';
                    }else if(!boolAreDCIsPublic && !boolAreTeamMembers) {
                        objCurrDCISharingSet.AccessLevel = 'Edit';
                    }else if(!boolAreDCIsPublic && boolAreTeamMembers) {
                        objCurrDCISharingSet.AccessLevel = 'Read';
                    }
                    // Set rowCause to 'manual' for manual sharing.
                    // This line can be omitted as 'manual' is the default value for sharing objects.
                    //objCurrDCISharingSet.RowCause = Schema.Document_Checklist_Item__Share.RowCause.Manual;
                }
                
                System.debug('updateSharingAccess::: ' + lstSharingSetsToUpdate.size());   
                try{
                    update lstSharingSetsToUpdate;
                }catch(Exception objExc) {
                    System.debug('ErrorOnUpdateSharingSet::: ' + objExc.getMessage());
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
    private List<Document_Checklist_Item__Share> getDCIsSharingAccess(Set<Id> setDCIIds) {
        List<Document_Checklist_Item__Share> lstSharingDCIs = [
            SELECT Id, RowCause, ParentId, UserOrGroupId, AccessLevel 
            FROM Document_Checklist_Item__Share 
            WHERE ParentId IN : setDCIIds];
        return lstSharingDCIs;
    }

    /* Method Name: setDCIsOwner
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set DCI owner  when DCI has contains PII = true
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: List<Document_Checklist_Item__c>
    */
    private HelperOTMWrapper setDCIsOwner(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers) {
        HelperOTMWrapper objWrapperToReturn = new HelperOTMWrapper();
        List<Document_Checklist_Item__c> lstDCIsToUpdate = new List<Document_Checklist_Item__c>();
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrOTM.IDB_Is_First_Team_Lead__c) {
                    if(objCurrDCI.OwnerId != objCurrOTM.UserId) {
                        objCurrDCI.OwnerId = objCurrOTM.UserId;
                        lstDCIsToUpdate.add(objCurrDCI);
                    }
                }
            }
        }
        objWrapperToReturn.boolForDCIs = true;
        objWrapperToReturn.boolForDCIsSharing = false;
        objWrapperToReturn.lstDCIs = lstDCIsToUpdate;
        return objWrapperToReturn;
    }

    /* Method Name: setDCIsOwnerOnDel
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set DCI owner  when DCI has contains PII = true
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: List<Document_Checklist_Item__c>
    */
    private void setDCIsOwnerOnDel(List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers) {
        for(Document_Checklist_Item__c objCurrDCI : lstIncomingDCIs) {
            for(OpportunityTeamMember objCurrOTM : lstIncomingTeamMembers) {
                //in the below condition; DCI records owned by the same OppTeamMember are ommited because it has already permissions to them
                if(objCurrOTM.OpportunityId == objCurrDCI.Opportunity__c && objCurrOTM.IDB_Is_First_Team_Lead__c) {
                    if(objCurrDCI.OwnerId != objCurrOTM.UserId) {
                        objCurrDCI.OwnerId = objCurrOTM.UserId;
                    }
                }
            }
        }
    }

    /* Method Name: doDMLStatements
    * Author Name: Alejandro Ramirez
    * Description: method which has the logic to set DCI owner  when DCI has contains PII = true
    * Parameters: List<Document_Checklist_Item__c> lstIncomingDCIs, List<OpportunityTeamMember> lstIncomingTeamMembers
    * Returns: List<Document_Checklist_Item__c>
    */
    private void doDMLStatements(List<HelperOTMWrapper> lstHelperOTMWrapperIn) {
        List<Document_Checklist_Item__c> lstDCIsToUpdate = new List<Document_Checklist_Item__c>();
        List<Document_Checklist_Item__Share> lstSharingDCIsToInsert = new List<Document_Checklist_Item__Share>();
        List<OpportunityTeamMember> lstOTMsToUpdate = new List<OpportunityTeamMember>();
        System.debug('OnDMLStatements::: ' + lstHelperOTMWrapperIn.size());
        for(HelperOTMWrapper objCurrWrapper : lstHelperOTMWrapperIn) {
            //System.debug('OnDMLStatements::: ' + objCurrWrapper);
            if(objCurrWrapper.boolForDCIs != null) {
                if(objCurrWrapper.boolForDCIs && !objCurrWrapper.lstDCIs.isEmpty()) {
                    for(Document_Checklist_Item__c objCurrDCI : objCurrWrapper.lstDCIs) {
                        lstDCIsToUpdate.add(objCurrDCI);
                    }
                }
            }
            if(objCurrWrapper.boolForDCIsSharing != null) {
                if(objCurrWrapper.boolForDCIsSharing && !objCurrWrapper.lstSharingSettings.isEmpty()) {
                    for(Document_Checklist_Item__Share objCurrDCIShare : objCurrWrapper.lstSharingSettings) {
                        lstSharingDCIsToInsert.add(objCurrDCIShare);
                    }
                }
            }
            if(objCurrWrapper.boolForOTMs != null) {
                if(objCurrWrapper.boolForOTMs && !objCurrWrapper.lstOTMs.isEmpty()) {
                    for(OpportunityTeamMember objCurrOTM : objCurrWrapper.lstOTMs) {
                        lstOTMsToUpdate.add(objCurrOTM);
                    }
                }
            }
        }
        if(!lstOTMsToUpdate.isEmpty()) {
            try{
                //System.debug('OTM_Handler_doDMLStatementsOTMsUpd::: ' + lstOTMsToUpdate.size());
                update lstOTMsToUpdate;
            }catch(Exception objExc) {
                System.debug('OTM_Handler_ErrordoDMLStatementsOTMsUpd::: ' + objExc.getMessage());
            }
        }
        if(!lstDCIsToUpdate.isEmpty()) {
            try{
                //System.debug('OTM_Handler_doDMLStatementsDCI::: ' + lstDCIsToUpdate.size());
                update lstDCIsToUpdate;
            }catch(Exception objExc) {
                System.debug('OTM_Handler_ErrordoDMLStatementsDCI::: ' + objExc.getMessage());
            }
        }
        if(!lstSharingDCIsToInsert.isEmpty()) {
            try{
                //System.debug('OTM_Handler_doDMLStatementsDCISharing::: ' + lstSharingDCIsToInsert.size());
                insert lstSharingDCIsToInsert;
            }catch(Exception objExc) {
                System.debug('OTM_Handler_ErrordoDMLStatementsDCISharing::: ' + objExc.getMessage());
            }
        }
    }

    /***********************************
	Class       : HelperOTMWrapper
	Author      : Alejandro Ramirez
	Date        : 04/05/2021
    Description : Class used to define the count number of DCIs by opp
    *************************************/
    public class HelperOTMWrapper {
        public boolean boolForDCIs {get;set;}
        public boolean boolForDCIsSharing {get;set;}
        public boolean boolForOTMs {get;set;}
        public List<Document_Checklist_Item__c> lstDCIs {get;set;}
        public List<Document_Checklist_Item__Share> lstSharingSettings {get;set;}
        public List<OpportunityTeamMember> lstOTMs {get;set;}

        public HelperOTMWrapper() {
        }

        public HelperOTMWrapper(boolean boolForOTMs, List<OpportunityTeamMember> lstOTMs) {
            this.boolForOTMs = boolForOTMs;
            this.lstOTMs = lstOTMs;
        }

    }
}