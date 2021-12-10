@IsTest
private class IDB_DocumentChecklist_CC_Test{
    @IsTest static void documentChecklistTest(){
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
        
        List<Id> newTemplateItemIdList = new List<Id>();
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
        newTemplateItemIdList.add(newTemplateItem.Id);
        
        Account newAcc = new Account();
        newAcc.RecordTypeId = IDB_Utility.getRecordTypeIdbyName('Account','Economic_Group');
        newAcc.Name = 'TestAccount';
        insert newAcc;
        
        Contact newCon = new Contact();
        newCon.RecordTypeId = IDB_Utility.getRecordTypeIdbyName('Contact','IndustriesIndividual');
        newCon.LastName = 'TestLastName';
        insert newCon;
        
        Opportunity newOpp = new Opportunity();
        newOpp.RecordTypeId = IDB_Utility.getRecordTypeIdbyName('Opportunity','WalletShareOpportunity');
        newOpp.Name = 'Test';
        newOpp.StageName = 'Initial Review';
        newOpp.AccountId = newAcc.Id;
        newOpp.Primary_Contact__c = newCon.Id;
        newOpp.CloseDate = Date.today();
        insert newOpp;
        
        Test.startTest();
        IDB_DocumentChecklist_CC.fetchDocumentChecklistTemplates();
        IDB_DocumentChecklist_CC.fetchDocumentChecklistTemplateItem(newTemplate.Id);
        IDB_DocumentChecklist_CC.createDocumentChecklistItems(newOpp.Id,newTemplateItemIdList);
        Test.stopTest();
    }
}