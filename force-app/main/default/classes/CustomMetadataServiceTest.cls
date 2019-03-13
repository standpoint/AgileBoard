@IsTest
private class CustomMetadataServiceTest {

    @IsTest
    private static void buildCustomMetadataRecordTest() {
        SObjectType type = Issue_Sort_Order__mdt.SObjectType;
        String name = 'Test name';
        String label = 'Test label';
        String description = 'Test description';
        SObjectField fieldType = Issue_Sort_Order__mdt.LastModifiedDate__c;
        Datetime fieldValue = Datetime.now();
        Metadata.CustomMetadata result = new CustomMetadataService().getBuilder()
                .setType(type)
                .setName(name)
                .setLabel(label)
                .setDescription(description)
                .setFieldEntry(fieldType, fieldValue)
                .build();
        System.assertEquals(label, result.label);
        System.assertEquals(description, result.description);
    }

    @IsTest
    private static void buildAndEnqueueCustomMetadataRecordCreatingTest() {
        SObjectType type = Issue_Sort_Order__mdt.SObjectType;
        String name = 'Test name';
        String label = 'Test label';
        String description = 'Test description';
        SObjectField fieldType = Issue_Sort_Order__mdt.LastModifiedDate__c;
        Datetime fieldValue = Datetime.now();
        Id result = new CustomMetadataService().getBuilder()
                .setType(type)
                .setName(name)
                .setLabel(label)
                .setDescription(description)
                .setFieldEntry(fieldType, fieldValue)
                .buildAndEnqueueRecordCreating();
        System.assertEquals(result, CustomMetadataService.STUB_JOB_ID);
    }

    @IsTest
    private static void constructCustomMetadataServiceAndCreateRecordTest() {
        SObjectType type = Issue_Sort_Order__mdt.SObjectType;
        String name = 'Test name';
        String label = 'Test label';
        String description = 'Test description';
        SObjectField fieldType = Issue_Sort_Order__mdt.LastModifiedDate__c;
        Datetime fieldValue = Datetime.now();
        CustomMetadataService cmService = new CustomMetadataService(type, name, label, description, new Map<SObjectField, Object>{
                Issue_Sort_Order__mdt.LastModifiedDate__c => Datetime.now()
        });
        Id result = cmService.createRecord();
        System.assertEquals(result, CustomMetadataService.STUB_JOB_ID);
    }
}