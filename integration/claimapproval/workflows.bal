import ballerina/workflow;

@workflow:Workflow
function processClaim(workflow:Context ctx, Claim input, ProcessClaimData data) returns json|error {
    string workflowId = check ctx.getWorkflowId();
    () _ = check ctx->callActivity(createClaim, {claimId: workflowId, claim: input});
    Bill bill = check wait data.bill;
    () _ = check ctx->callActivity(attachBill, {claimId: workflowId, billInfo: bill});
    Decision decision = check ctx->awaitHumanTask("approveClaim", userRoles = "MANAGER", taskInput = {claimId: workflowId, employee: input.employee, description: input.description, amount: input.amount, billName: bill.fileName, billUrl: bill.fileUrl}, title = "Approve expense claim");
    if decision.approved {
        () _ = check ctx->callActivity(approveAndPay, {claimId: workflowId, remarks: decision.comment});
    } else {
        () _ = check ctx->callActivity(notifyRejection, {claimId: workflowId, remarks: decision.comment});
    }
}
