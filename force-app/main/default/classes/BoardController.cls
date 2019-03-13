public with sharing class BoardController {

    private static final BoardService service = new BoardService();

    @AuraEnabled(cacheable=true)
    public static String getInitData(String boardId) {
        return JSON.serialize(service.initBoardData(boardId));
    }

    @AuraEnabled
    public static String updateBoard(String boardId) {
        return JSON.serialize(service.initBoardData(boardId));
    }

    @AuraEnabled
    public static String updateIssue(String recordId, String status) {
        return JSON.serialize(Database.update(new Issue__c(Id = recordId, Status__c = status), false));
    }

    @AuraEnabled
    public static String upsertSortOrder(String boardId, String boardName, String issuesByColumns){
        String result = 'failed';
        if (String.isNotEmpty(boardId) && String.isNotEmpty(boardName) && String.isNotEmpty(issuesByColumns)) {
            service.updateSortOrder(boardId, boardName, issuesByColumns);
            result = 'enqueued';
        }
        return result;
    }

}
