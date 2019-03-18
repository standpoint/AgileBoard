public with sharing class IssueTriggerHandler extends SObjectDomain {
    
    private final BoardService boardService;

    public IssueTriggerHandler() {
        this.boardService = new BoardService();
    }

    public override void onAfterInsert() {
        this.boardService.updateSortOrder(this.records);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        this.boardService.updateSortOrder(this.records);
    }
}
