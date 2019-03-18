trigger IssueTrigger on Issue__c (after insert, after update) {
    SObjectDomain.triggerHandler(IssueTriggerHandler.class);
}