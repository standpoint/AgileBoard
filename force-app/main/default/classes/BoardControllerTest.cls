@IsTest
private class BoardControllerTest {

    private static final Integer ISSUES_NUMBER = 5;
    private static final String KANBAN_BOARD = 'Kanban';
    private static final String SCRUM_BOARD = 'Scrum';
    private static final String ISSUE_INIT_STATUS = 'Todo';
    private static final String ISSUE_NEXT_STATUS = 'In progress';
    private static final String BOARD_AVAILABLE_STATUSES = ISSUE_INIT_STATUS + ';' + ISSUE_NEXT_STATUS;
    
    @TestSetup
    private static void init() {
        TestDataFactory tdf = new TestDataFactory();
        List<Board__c> boards = new List<Board__c>{ new Board__c(Name = KANBAN_BOARD, Available_Statuses__c = BOARD_AVAILABLE_STATUSES), new Board__c(Name = SCRUM_BOARD) };
        insert boards;
        for (Board__c b : boards) {
            tdf.createRecords(ISSUES_NUMBER, Issue__c.SObjectType, new Map<String, Object>{
                'Name' => 'Issue'
                , 'Description__c' => 'Issue details'
                , 'Board__c' => b.Id
                , 'Status__c' => ISSUE_INIT_STATUS
            });
        }
    }

    @IsTest
    private static void getInitDataTest1() {
        Board__c b = [SELECT Id, Name FROM Board__c WHERE Name = :KANBAN_BOARD];
        String result = BoardController.getInitData(b.Id);
        BoardService.Board board = (BoardService.Board) JSON.deserialize(result, BoardService.Board.class);
        System.assertEquals(KANBAN_BOARD, board.record.Name);
        System.assertEquals(ISSUES_NUMBER, board.cards.size());
    }

    @IsTest
    private static void getInitDataTest2() {
        Board__c b = [SELECT Id, Name FROM Board__c WHERE Name = :KANBAN_BOARD];
        List<Issue__c> issues = [SELECT Id, Status__c FROM Issue__c WHERE Board__c = :b.Id];
        for (Issue__c iss : issues) {
            iss.Status__c = ISSUE_NEXT_STATUS;
        }
        update issues;
        String result = BoardController.getInitData(b.Id);
        BoardService.Board board = (BoardService.Board) JSON.deserialize(result, BoardService.Board.class);
        System.assertEquals(KANBAN_BOARD, board.record.Name);
        System.assertEquals(ISSUES_NUMBER, board.cards.size());
    }

    @IsTest
    private static void updateBoardTest() {
        Board__c b = [SELECT Id, Name FROM Board__c WHERE Name = :KANBAN_BOARD];
        String result = BoardController.updateBoard(b.Id);
        System.assertNotEquals(null, result);
    }

    @IsTest
    private static void updateIssueTest() {
        Issue__c iss = [SELECT Id, Status__c FROM Issue__c LIMIT 1];
        BoardController.updateIssue(iss.Id, ISSUE_NEXT_STATUS);
        Issue__c issUpd = [SELECT Status__c FROM Issue__c WHERE Id = :iss.Id];
        System.assertEquals(ISSUE_NEXT_STATUS, issUpd.Status__c);
    }

    @IsTest
    private static void upsertSortOrderTest() {
        Board__c b = [SELECT Id, Name FROM Board__c WHERE Name = :KANBAN_BOARD];
        String result = BoardController.upsertSortOrder(b.Id, b.Name, '{}');
        System.assertEquals('enqueued', result);
    }
}
