({
    // Sets an empApi error handler on component initialization
    onInit : function(component, event, helper) {
        const empApi = component.find('empApi');
        empApi.setDebugFlag(false);
        empApi.onError($A.getCallback(error => {
            console.error('EMP API error: ', error);
        }));
        helper.subscribe(component, event, helper);
    }
})