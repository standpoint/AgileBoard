({
    // Invokes the subscribe method on the empApi component
    subscribe : function(component, event, helper) {
        const empApi = component.find('empApi');
        // const channel = component.find('channel').get('v.value');
        const channel = '/event/Board_Updated__e';
        const replayId = -1;
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            console.log('Received event ', JSON.stringify(eventReceived));
            if (eventReceived && eventReceived.data && eventReceived.data.payload) {
                let payload = eventReceived.data.payload;
                let currentUserId = $A.get('$SObjectType.CurrentUser.Id');
                if (payload.Board_Id__c && (payload.IsAnonymous__c || payload.CreatedById !== currentUserId)) {
                    let message = eventReceived.data.payload.Board_Id__c;
                    let pubsub = component.find('pubsub');
                    pubsub.fireEvent('boardUpdated', message);
                }
            } 
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            console.log('Subscribed to channel ', subscription.channel);
            // Save subscription to unsubscribe later
            component.set('v.subscription', subscription);
        });
    },

    // Invokes the unsubscribe method on the empApi component
    unsubscribe : function(component, event, helper) {
        const empApi = component.find('empApi');
        const subscription = component.get('v.subscription');
        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
            // Confirm that we have unsubscribed from the event channel
            console.log('Unsubscribed from channel '+ unsubscribed.subscription);
            component.set('v.subscription', null);
        }));
    }
})
