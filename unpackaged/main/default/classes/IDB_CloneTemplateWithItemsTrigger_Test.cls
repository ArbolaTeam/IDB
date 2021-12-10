@IsTest
private class IDB_CloneTemplateWithItemsTrigger_Test {
    @testSetup
    static void setup(){
        Document_Checklist_Template__c newTemplate = new Document_Checklist_Template__c();
        newTemplate.Template_Name__c = 'TestTemplate';
        newTemplate.Phase__c = 'Structuring';
        newTemplate.Product__c = 'Project Finance Loan';
        newTemplate.Product_Family_Asset_Class__c = 'Loan';
        newTemplate.Product_Type__c = 'Loan';
        newTemplate.Sector__c = 'Agribusiness';
        newTemplate.Segment__c = 'Corporates';
        newTemplate.Status__c = 'Draft';
        insert newTemplate;
        
        Document_Checklist_Template_Item__c newTemplateItem = new Document_Checklist_Template_Item__c();
        newTemplateItem.RecordTypeId = IDB_Utility.getRecordTypeIdbyName('Document_Checklist_Template_Item__c','IDB_Documents');
        newTemplateItem.Contains_PII__c = true;
        newTemplateItem.Instructions__c = 'TestInstruction';
        newTemplateItem.IDB_Link__c = 'www.idb.org';
        newTemplateItem.Description__c = 'TestTemplateItem';
        newTemplateItem.Template__c = newTemplate.Id;
        newTemplateItem.Section__c = 'Initial Review';
        newTemplateItem.IDB_Team_Role__c = 'Team Leader';
        newTemplateItem.IDB_EzShare_Number_Ext__c = 'AA11';
        insert newTemplateItem;
        
        CloneFieldMaper__c cfm = new CloneFieldMaper__c();
        cfm.Name = 'Template';
        cfm.Field_API_Name__c = 'Template__c';
        insert cfm;
    }
    
    @IsTest static void cloneTemplateWithItemsTest(){
        Document_Checklist_Template__c newTemplate = [SELECT Id 
                                                      FROM Document_Checklist_Template__c 
                                                     ];
        List<Document_Checklist_Template__c> newTemplateList = new List<Document_Checklist_Template__c>();
        Test.startTest();
        newTemplateList.add(newTemplate.clone(false, false, false, false));
        IDB_CloneTemplateWithItemsHelper.afterInsert(newTemplateList);
        Test.stopTest();
    }
}