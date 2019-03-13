@IsTest
private class BoardServiceTest {
    
    @IsTest
    private static void testBoardUpdateCallback() {
        Board__c b = new Board__c();
        insert b;
        Metadata.DeployCallback callback = new BoardService.BoardUpdateCallback(
            new EventBusService().add(new Board_Updated__e(Board_Id__c = b.Id))
        );
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;
        result.details = new Metadata.DeployDetails();
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        callback.handleResult(result, context);
    }
}
