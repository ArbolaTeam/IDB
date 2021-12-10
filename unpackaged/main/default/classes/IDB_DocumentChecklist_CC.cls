/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* IDB_DocumentChecklist_CC class created for creating Document Checklist Items on Opportunity
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @modifiedBy     Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @maintainedBy   Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @version        1.0
* @created        2020-10-23
* @modified       2021-01-06
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public with sharing class IDB_DocumentChecklist_CC{
    
    /**
* ───────────────────────────────────────────────────────────────────────────────────────────────┐
* fetchDocumentChecklistTemplates method created for fetching Published Document Checklist Template records
* ────────────────────────────────────────────────────────────────────────────────────────────────
* @param    NO PARAM
* @return   List<Document_Checklist_Template__c>
* ───────────────────────────────────────────────────────────────────────────────────────────────┘
*/
    @AuraEnabled
    public static List<Document_Checklist_Template__c> fetchDocumentChecklistTemplates(){
        List<Document_Checklist_Template__c> dctRecords = new List<Document_Checklist_Template__c>();
        dctRecords =    [SELECT Id,Name,Template_Name__c
                         FROM Document_Checklist_Template__c
                         WHERE Status__c =: System.label.Published_Status
                         WITH SECURITY_ENFORCED
                         ORDER BY Name
                        ];
        return dctRecords;
    }
    
    /**
* ───────────────────────────────────────────────────────────────────────────────────────────────┐
* fetchDocumentChecklistTemplateItem method created for fetching Document Checklist Template Item records
* ────────────────────────────────────────────────────────────────────────────────────────────────
* @param    String
* @return   List<Document_Checklist_Template_Item__c>
* ───────────────────────────────────────────────────────────────────────────────────────────────┘
*/
    
    @AuraEnabled
    public static Map<String,List<Document_Checklist_Template_Item__c>> fetchDocumentChecklistTemplateItem(String templateId){
        List<Document_Checklist_Template_Item__c> dctiRecords = new List<Document_Checklist_Template_Item__c>();
        Map<String,List<Document_Checklist_Template_Item__c>> sectionGroupMap = new Map<String,List<Document_Checklist_Template_Item__c>>();
        if(String.isNotBlank(templateId)){
            dctiRecords =   [SELECT Id,Name,Description__c,Section__c
                             FROM Document_Checklist_Template_Item__c
                             WHERE Template__c =: templateId
                             WITH SECURITY_ENFORCED
                             ORDER BY Section__c
                            ];
            
            for(Document_Checklist_Template_Item__c eachDCTI : dctiRecords){
                List<Document_Checklist_Template_Item__c> dcti = new List<Document_Checklist_Template_Item__c>();
                dcti.add(eachDCTI);
                if(sectionGroupMap.containsKey(eachDCTI.Section__c)){
                    dcti.addAll(sectionGroupMap.get(eachDCTI.Section__c));
                    sectionGroupMap.put(eachDCTI.Section__c,dcti);
                }else{
                    sectionGroupMap.put(eachDCTI.Section__c,dcti);
                }
            }
        }
        return sectionGroupMap;
    }
    
    /**
* ───────────────────────────────────────────────────────────────────────────────────────────────┐
* createDocumentChecklistItems method created for creating Document Checklist Item records
* ────────────────────────────────────────────────────────────────────────────────────────────────
* @param    String
* @param    List<String>
* @return   VOID
* ───────────────────────────────────────────────────────────────────────────────────────────────┘
*/
    
    @AuraEnabled
    public static void createDocumentChecklistItems(String opportunityId, List<String> documentChecklistTemplateItemIds){
        List<Document_Checklist_Template_Item__c> dctiRecords = new List<Document_Checklist_Template_Item__c> ();
        if(String.isNotBlank(opportunityId) && !documentChecklistTemplateItemIds.isEmpty()){
            dctiRecords =    [SELECT Id, Name, RecordTypeId, Contains_PII__c,ListName__c, Function__c, Activity__c, Record_Access_Classification_IIC__c,ATI_Exception__c,Document_Type__c, Instructions__c, IDB_Link__c, Description__c, IDB_Survey__c, Template__c, Section__c, IDB_Subsection__c,IDB_Team_Role__c,IDB_EzShare_Number_Ext__c
                              FROM Document_Checklist_Template_Item__c
                              WHERE Id IN : documentChecklistTemplateItemIds
                              WITH SECURITY_ENFORCED
                              ORDER BY Name
                             ];
            
            String jsonData = JSON.serialize(dctiRecords);
            System.debug('JsonData-' + jsonData);
        }
        List<Document_Checklist_Item__c> dciRecords = new List<Document_Checklist_Item__c>();
        if(!dctiRecords.isEmpty()){
            for(Document_Checklist_Template_Item__c eachDCTIRecord : dctiRecords){
                Document_Checklist_Item__c dciRecord = new Document_Checklist_Item__c();
                dciRecord.RecordTypeId = IDB_Utility.getRecordTypeIdbyName(System.label.DocumentChecklistItem,IDB_Utility.getRecordTypeNameById(System.label.DocumentChecklistTemplateItem,eachDCTIRecord.RecordTypeId));
                dciRecord.Name = eachDCTIRecord.Name;
                dciRecord.Contains_PII__c = eachDCTIRecord.Contains_PII__c;
                dciRecord.Instructions__c = eachDCTIRecord.Instructions__c;
                dciRecord.IDB_Link__c = eachDCTIRecord.IDB_Link__c;
                dciRecord.Description__c = eachDCTIRecord.Description__c;
                dciRecord.Opportunity__c = opportunityId;
                dciRecord.Status__c = System.label.New_Status;
                dciRecord.IDB_Survey__c = eachDCTIRecord.IDB_Survey__c;
                dciRecord.Section__c = eachDCTIRecord.Section__c;
                dciRecord.IDB_Subsection__c = eachDCTIRecord.IDB_Subsection__c;
                dciRecord.IDB_Team_Role__c = eachDCTIRecord.IDB_Team_Role__c;
                dciRecord.IDB_EzShare_Number_Ext__c = eachDCTIRecord.IDB_EzShare_Number_Ext__c;
                dciRecord.List_Name__c = eachDCTIRecord.ListName__c;
                dciRecord.Function__c = eachDCTIRecord.Function__c;
                dciRecord.Activity__c = eachDCTIRecord.Activity__c;
                dciRecord.Record_Access_Classification_IIC__c = eachDCTIRecord.Record_Access_Classification_IIC__c;
                dciRecord.ATI_Exception__c = eachDCTIRecord.ATI_Exception__c;
                dciRecord.Document_Type__c = eachDCTIRecord.Document_Type__c;                                
                dciRecords.add(dciRecord);
            }
        }
        if(!dciRecords.isEmpty()){
            try{
                Database.insert(dciRecords,true);
            }catch(Exception exp){
                system.debug('exp = '+exp);
            }   
        }
    }
    
    
}