import ballerina/workflow;

@workflow:Workflow
function processClaim(workflow:Context ctx, Claim input, ProcessClaimData data) returns json|error {
    () _ = check ctx->callActivity(createClaim, {claim: input});
    Bill bill = check wait data.bill;
    () _ = check ctx->callActivity(attachBill, {claimId: input.claimId, billInfo: bill});
    Decision decision = check ctx->awaitHumanTask("approveClaim", userRoles = "MANAGER", taskInput = {claimId: input.claimId, employee: input.employee, description: input.description, amount: input.amount, billName: bill.fileName, billUrl: bill.fileUrl}, title = "Approve expense claim");
    if decision.approved {
        () _ = check ctx->callActivity(recordDecision, {claimId: input.claimId, status: "APPROVED", remarks: decision.comment});
    } else {
        () _ = check ctx->callActivity(recordDecision, {claimId: input.claimId, status: "REJECTED", remarks: decision.comment});
    }
}
