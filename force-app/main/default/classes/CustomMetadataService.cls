public inherited sharing class CustomMetadataService {
    
    @TestVisible
    private static final String STUB_JOB_ID = Test.isRunningTest() ? TestDataFactory.getFakeId('AsyncApexJob', 1) : null;

    private final EventBusService eventBusService;
    private final Metadata.DeployContainer deployContainer;
    private Metadata.CustomMetadata customMetadata;

    public CustomMetadataBuilder getBuilder() {
        return new CustomMetadataBuilder();
    }

    public class CustomMetadataBuilder {
        private SObjectType cmType;
        private String cmName;
        private String cmLabel;
        private String cmDescription;
        private Map<SObjectField, Object> cmFieldValuesMap;

        private CustomMetadataBuilder() {
            this.cmFieldValuesMap = new Map<SObjectField, Object>();
        }

        public CustomMetadataBuilder setType(SObjectType cmType) {
            this.cmType = cmType;
            return this;
        }

        public CustomMetadataBuilder setName(String cmName) {
            this.cmName = cmName;
            return this;
        }

        public CustomMetadataBuilder setLabel(String cmLabel) {
            this.cmLabel = cmLabel;
            return this;
        }

        public CustomMetadataBuilder setDescription(String cmDescription) {
            this.cmDescription = cmDescription;
            return this;
        }

        public CustomMetadataBuilder setFieldEntry(SObjectField field, Object value) {
            this.cmFieldValuesMap.put(field, value);
            return this;
        }

        public Metadata.CustomMetadata build() {
            return new CustomMetadataService(this.cmType, this.cmName, this.cmLabel, this.cmDescription, this.cmFieldValuesMap).customMetadata;
        }

        public Id buildAndEnqueueRecordCreating() {
            return buildAndEnqueueRecordCreating(null);
        }

        public Id buildAndEnqueueRecordCreating(Metadata.DeployCallback callback) {
            return new CustomMetadataService(this.cmType, this.cmName, this.cmLabel, this.cmDescription, this.cmFieldValuesMap).createRecord(callback);
        }
    }


    public CustomMetadataService() {
        this.deployContainer = new Metadata.DeployContainer();
        this.eventBusService = new EventBusService();
    }

    public CustomMetadataService(SObjectType cmType, String cmName, String cmLabel, String cmDescription, Map<SObjectField, Object> valueByFieldMap) {
        this();
        this.customMetadata = this.buildRecord(cmType, cmName, cmLabel, cmDescription, valueByFieldMap);
    }

    public Id createRecord() {
        return this.createRecord(null);
    }

    public Id createRecord(Metadata.DeployCallback callback) {
        this.deployContainer.addMetadata(this.customMetadata);
        if (callback == null) {
            callback = new DefaultDeployCallback();
        }
        return Test.isRunningTest() ? STUB_JOB_ID : Metadata.Operations.enqueueDeployment(this.deployContainer, callback);
    }

    private Metadata.CustomMetadata buildRecord(SObjectType cmType, String cmName, String cmLabel, String cmDescription, Map<SObjectField, Object> valueByFieldMap) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        if (String.isNotEmpty(cmName) && cmType != null) {
            customMetadata.fullName = String.valueOf(cmType) + '.' + cmName;
            customMetadata.label = cmLabel;
            customMetadata.description = cmDescription;
            if (valueByFieldMap != null && !valueByFieldMap.isEmpty()) {
                for (SObjectField field : valueByFieldMap.keySet()) {
                    Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                    customField.field = String.valueOf(field);
                    System.debug('>>> field+value:' + customField.field + ':' + valueByFieldMap.get(field));
                    customField.value = valueByFieldMap.get(field);
                    customMetadata.values.add(customField);
                }
            }
        }
        return customMetadata;
    }

    @TestVisible
    private class DefaultDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            System.debug('>> DEFAULT DEPLOY CALLBACK: (status, completed date, created by name, error)'
                    + '\n:status:\t\t\t' + result.status
                    + '\n:modified date:\t' + result.completedDate
                    + '\n:modified by:\t\t' + result.createdByName
                    + '\n:error message:\t' + result.errorMessage
                    + '\n:error status code:' + result.errorStatusCode
                    + '\n:' + result.details
            );
        }
    }
}
