import ballerina/workflow;

@workflow:Workflow
function processClaim(workflow:Context ctx, Claim input, ProcessClaimData data) returns json|error {
    () _ = check ctx->callActivity(createClaim, {claimId: check ctx.getWorkflowId(), claim: input});
    Bill bill = check wait data.bill;
    () _ = check ctx->callActivity(attachBill, {claimId: check ctx.getWorkflowId(), billInfo: bill});
    Decision decision = check ctx->awaitHumanTask("approveClaim", userRoles = "MANAGER", taskInput = {claimId: check ctx.getWorkflowId(), employee: input.employee, description: input.description, amount: input.amount, billName: bill.fileName, billUrl: bill.fileUrl}, title = "Approve expense claim");
    if decision.approved {
        () _ = check ctx->callActivity(recordDecision, {claimId: check ctx.getWorkflowId(), status: "APPROVED", remarks: decision.comment});
    } else {
        () _ = check ctx->callActivity(recordDecision, {claimId: check ctx.getWorkflowId(), status: "REJECTED", remarks: decision.comment});
    }
}
