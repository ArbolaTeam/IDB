/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* IDB_CloneTemplateWithItemsHandler class created for cloning Document Checklist Template with Items
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @modifiedBy     Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @maintainedBy   Vivek Kasireddy  <vivek.kasireddy@capgemini.com>
* @version        1.0
* @created        2020-10-28
* @modified       2020-10-28
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public class IDB_CloneTemplateWithItemsHandler{
    
    /**
* ───────────────────────────────────────────────────────────────────────────────────────────────┐
* cloneTemplateWithItems method created for cloning Template Items
* ────────────────────────────────────────────────────────────────────────────────────────────────
* @param    Map<Id,Id>
* @return   No Param
* ───────────────────────────────────────────────────────────────────────────────────────────────┘
*/
    public static void cloneTemplateWithItems(Map<Id,Id> templatesMap){
        if(!templatesMap.isEmpty()){
            String comma = ',';
            String clonableFields = '';
            List<Document_Checklist_Template_Item__c> newTemplateItems = new List<Document_Checklist_Template_Item__c>();
            List<Document_Checklist_Template_Item__c> oldTemplateItems = new List<Document_Checklist_Template_Item__c>();
            List<CloneFieldMaper__c> clonedFields = CloneFieldMaper__c.getall().values();
            for(CloneFieldMaper__c eachValue : clonedFields){
                clonableFields = clonableFields+eachValue.Field_API_Name__c+comma;
            }
            clonableFields = clonableFields.removeEnd(comma);
            Set<Id> templateIds = templatesMap.keyset();
            String dynamicQueryString = 'SELECT '+clonableFields+' FROM Document_Checklist_Template_Item__c WHERE Template__c IN : templateIds';
            system.debug('dynamicQueryString '+dynamicQueryString);
            oldTemplateItems = Database.query(dynamicQueryString);
            for(Document_Checklist_Template_Item__c eachItem : oldTemplateItems){
                Document_Checklist_Template_Item__c newItem = eachItem.clone(false, false, false, false);
                newItem.Template__c = templatesMap.get(eachItem.Template__c);
                newTemplateItems.add(newItem);
                
            }
            if(!newTemplateItems.isEmpty()){
                try{
                    Database.insert(newTemplateItems,true);
                }catch(Exception exp){
                    system.debug(exp);
                }
            }
        }
    }
}