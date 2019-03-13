public inherited sharing class BoardService {

    @TestVisible
    private static final String TEST_BOARD_ID = 'TEST_BOARD_ID';

    public BoardService() {}

    public Board initBoardData(String boardId) {
        Map<String, Column> columnByName = new Map<String, Column>();
        Board result = initBoard(boardId, columnByName);
        Map<Id, Issue__c> issueById = getIssueById(boardId);
        //Source of truth
        Map<String, Set<Id>> issueIdsByStatus = issueIdsByStatus(issueById);
        //Try to reorder if settings exist
        String mdBoardId = System.Test.isRunningTest() ? TEST_BOARD_ID : boardId;
        List<Issue_Sort_Order__mdt> issueOrderSettings = [
            SELECT Issue_Ids__c
            FROM Issue_Sort_Order__mdt 
            WHERE DeveloperName = :mdBoardId
        ];
        if (issueOrderSettings.isEmpty()) {
            fillBoardDataFallback(issueIdsByStatus, columnByName, issueById, result);
        } else {
            Map<String, List<Id>> issueIdsByColumns;
            try {
                issueIdsByColumns = (Map<String, List<Id>>) JSON.deserialize(issueOrderSettings.get(0).Issue_Ids__c, Map<String, List<Id>>.class);
            } catch (JSONException e) {
                issueIdsByColumns = new Map<String, List<Id>>();
                System.debug('Unexpected json in Issue_Sort_Order__mdt record: ' + e);
            }
            if (issueIdsByColumns == null || issueIdsByColumns.isEmpty()) {
                // use issues from database if settings are not exist or malformed
                fillBoardDataFallback(issueIdsByStatus, columnByName, issueById, result);
                System.debug('fallback Result 1: ' + result);
                return result;
            } else {
                //try to sort by settings data
                fillBoardData(issueIdsByColumns, issueIdsByStatus, columnByName, issueById, result);
            }
        }
        System.debug('Result : ' + result);
        return result;
    }

    public void updateSortOrder(String boardId, String boardName, String issuesByColumns) {
        new CustomMetadataService().getBuilder()
                .setType(Issue_Sort_Order__mdt.SObjectType)
                .setName(boardId)
                .setLabel(boardName)
                .setDescription('Board Name: ' + boardName + ', Board Id: ' + boardId)
                .setFieldEntry(Issue_Sort_Order__mdt.Board_Id__c, boardId)
                .setFieldEntry(Issue_Sort_Order__mdt.Issue_Ids__c, issuesByColumns)
                .setFieldEntry(Issue_Sort_Order__mdt.LastModifiedDate__c, Datetime.now())
                .buildAndEnqueueRecordCreating(new BoardUpdateCallback(
                        new EventBusService().add(new Board_Updated__e(Board_Id__c = boardId))
                ));
    }

    private Board initBoard(String boardId, Map<String, Column> columnByName) {
        Board result = new Board();
        for (Board__c board : [SELECT Id, Name, Available_Statuses__c FROM Board__c WHERE Id = :boardId]) {
            for (String status : board.Available_Statuses__c.split(';')) {
                Column col = new Column( status, status.toUpperCase(), new List<Card>());
                result.columns.add( col );
                columnByName.put(status, col);
            }
            result.record = board;
        }
        return result;
    }

    private Map<Id, Issue__c> getIssueById(String boardId) {
        return new Map<Id, Issue__c>([
            SELECT Id
                , Name
                , Number__c
                , Description__c
                , Status__c
                , RecordTypeId
            FROM Issue__c
            WHERE Board__c = :boardId
        ]);
    }

    private Map<String, Set<Id>> issueIdsByStatus(Map<Id, Issue__c> issueById) {
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();
        for (Issue__c issue : issueById.values()) {
            Set<Id> issueIds = result.get(issue.Status__c);
            if (issueIds == null) {
                issueIds = new Set<Id>{issue.Id};
            } else {
                issueIds.add(issue.Id);
            }
            result.put(issue.Status__c, issueIds);
        }
        return result;
    }

    private void fillBoardData(Map<String, List<Id>> issueIdsByColumns, Map<String, Set<Id>> issueIdsByStatus, Map<String, Column> columnByName, Map<Id, Issue__c> issueById, Board result) {
        System.debug('fillBoardData:\nissueIdsByColumns:'+ issueIdsByColumns + '\nissueIdsByStatus:' + issueIdsByStatus + '\ncolumnByName:' + columnByName + '\nissueById:' + issueById + '\nresult:' + result);
        for (String colName : issueIdsByColumns.keySet()) {
            Column col = columnByName.get(colName);
            Set<Id> dbIssues = issueIdsByStatus.get(colName);
            List<Id> mdIssues = issueIdsByColumns.get(colName);
            if (col != null && mdIssues != null && dbIssues != null && dbIssues.size() == mdIssues.size()) {
                for (Id issueId : mdIssues) {
                    Issue__c issue = issueById.get(issueId);
                    // if settings data is different from Issues database records use the last one as source of truth
                    if (issue == null || issue.Status__c != colName) {
                        fillBoardDataFallback(issueIdsByStatus, columnByName, issueById, result);
                        System.debug('Fallback Result 3: ' + result);
                        return;
                    }
                    Card card = new Card(issue.Number__c + ': ' + issue.Name, issue.Description__c, issue.Id);
                    col.cards.add(card);
                    System.debug('Column: ' + col);
                    result.cards.add(card);
                }
            } else {
                // use fallback if settings has no cards but database has  
                fillBoardDataFallback(issueIdsByStatus, columnByName, issueById, result);
                System.debug('Fallback Result 2: ' + result);
                return;
            }
            
        }
    }

    private void fillBoardDataFallback(Map<String, Set<Id>> issueIdsByStatus, Map<String, Column> columnByName, Map<Id, Issue__c> issueById, Board result) {
        for (String status : issueIdsByStatus.keySet()) {
            Column col = columnByName.get(status);
            if (col != null) {
                for (Id issueId : issueIdsByStatus.get(status)) {
                    Issue__c issue = issueById.get(issueId);
                    Card card = new Card(issue.Number__c + ': ' + issue.Name, issue.Description__c, issue.Id);
                    col.cards.add(card);
                    result.cards.add(card);
                }
            }
            
        }
    }

    @TestVisible
    private class BoardUpdateCallback implements Metadata.DeployCallback {

        private final EventBusService bus;

        public BoardUpdateCallback(EventBusService bus) {
            this.bus = bus;
        }

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                if (!this.bus.isPoolEmpty()) {
                    this.bus.publish();
                }
                System.debug('messages:' + result.details.componentSuccesses);
            }
            System.debug('>> BOARD DEPLOY CALLBACK:'
                    + '\n:status:\t\t\t' + result.status
                    + '\n:modified date:\t' + result.completedDate
                    + '\n:modified by:\t\t' + result.createdByName
                    + '\n:error message:\t' + result.errorMessage
                    + '\n:error status code:' + result.errorStatusCode
                    + '\n:' + result.details
            );
        }
    }


    public class Board {
        public Board() {
            this.columns = new List<Column>();
            this.cards = new List<Card>();
        }
        public List<Column> columns { get; set; }
        public List<Card> cards { get; set; }
        public Board__c record { get; set; }
    }
    
    public class Column {
        public Column(String name, String label, List<Card> cards) {
            this.name = name;
            this.label = label;
            this.cards = cards;
            this.dropzone = 'slds-box';
            this.dropzoneReorder = 'slds-hide';
        }
        public String name { get; set; }
        public String label { get; set; }
        public List<Card> cards { get; set; }
        public String dropzone { get; set; }
        public String dropzoneReorder { get; set; }
    }

    public class Card {
        public Card(String title, String body, String id) {
            this.title = title;
            this.body = body;
            this.id = id;
        }
        public String title { get; set; }
        public String body { get; set; }
        public String id { get; set; }
    }
}
