public virtual with sharing class SObjectDomain {

    public List<SObject> records { get; set; }

    public Schema.DescribeSObjectResult sObjectDescribe {
        get {
            if(sObjectDescribe == null){
                if(records != null && !records.isEmpty()){
                    sObjectDescribe = records[0].getSObjectType().getDescribe();
                }
            }
            return sObjectDescribe;
        }
        private set;
    }
    
    public SObjectDomain() {}

    public SObjectDomain(List<sObject> records) {
        this.records = records;
    }
	
    public virtual void onBeforeInsert() { }
    
    public virtual void onBeforeUpdate(Map<Id,SObject> existingRecords) { }
	
    public virtual void onBeforeDelete() { }

    public virtual void onAfterInsert() { }
	
    public virtual void onAfterUpdate(Map<Id,SObject> existingRecords) { }
    
    public virtual void onAfterDelete() { }
    
    public virtual void onAfterUnDelete() { }

    
    public void handleBeforeInsert() {
        onBeforeInsert();
    }
    
    public void handleBeforeUpdate(Map<Id,SObject> existingRecords) {
        onBeforeUpdate(existingRecords);
    }
    
    public void handleBeforeDelete() {
        onBeforeDelete();
    }
    
    public void handleAfterInsert() {
        onAfterInsert();
    }

    public void handleAfterUpdate(Map<Id,SObject> existingRecords) {
        onAfterUpdate(existingRecords);
    }
    
    public void handleAfterDelete() {
        onAfterDelete();
    }
    
    public void handleAfterUnDelete() {
        onAfterUnDelete();
    }
	
    public static void triggerHandler(System.Type domainClass) {

        triggerHandler(
            domainClass
            , Trigger.isBefore
            , Trigger.isAfter
            , Trigger.isInsert
            , Trigger.isUpdate
            , Trigger.isDelete
            , Trigger.isUnDelete
            , Trigger.new
            , Trigger.oldMap
        );

    }
    
    @TestVisible
    private static void triggerHandler(System.Type domainClass, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete, List<SObject> newRecords, Map<Id, SObject> oldRecordsMap) {
        if(isBefore)
        {
            if(isInsert) {
                initDomain(domainClass,newRecords).handleBeforeInsert();
            }
            else if(isUpdate) {
                initDomain(domainClass,newRecords).handleBeforeUpdate(oldRecordsMap);
            }
            else if(isDelete) {
                initDomain(domainClass,oldRecordsMap.values()).handleBeforeDelete();
            }
        }
        else
        {
            if(isInsert) {
                initDomain(domainClass,newRecords).handleAfterInsert();
            }
            else if(isUpdate) {
                initDomain(domainClass,newRecords).handleAfterUpdate(oldRecordsMap);
            }
            else if(isDelete) {
                initDomain(domainClass,oldRecordsMap.values()).handleAfterDelete();
            }
            else if(isUnDelete) {
                initDomain(domainClass,newRecords).handleAfterUnDelete();
            }
        }
    }
    
    private static sObjectDomain initDomain(System.Type domainClass, List<sObject> records){
        sObjectDomain dom = (sObjectDomain) domainClass.newInstance();
        dom.records = records;
        if(dom == null){
            throw new DomainException('Illegal domain class: '+ String.valueOf(domainClass) + ' passed');
        }
        return dom;
    }

    public class DomainException extends Exception {}
}