public inherited sharing class EventBusService {

    private final List<SObject> pool;
    
    public EventBusService() {
        this.pool = new List<SObject>();
    }

    public EventBusService add(SObject e) {
        this.pool.add(e);
        return this;
    }

    public void publish() {
        List<Database.SaveResult> results = EventBus.publish(this.pool);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('>> EventBusService: Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('>> EventBusService:  Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }       
        }
    }

    public Boolean isPoolEmpty() {
        return this.pool.isEmpty();
    }
}
