import ballerina/log;
import ballerina/sql;
import ballerina/workflow;

@workflow:Activity
function createClaim(string claimId, Claim claim) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`INSERT INTO claims (claim_id, employee, description, amount, status) VALUES (${claimId}, ${claim.employee}, ${claim.description}, ${claim.amount}, 'BILL_REQUIRED')`);
}

@workflow:Activity
function attachBill(string claimId, Bill billInfo) returns error? {
    log:printInfo("Handling the attachment", claimId = claimId, fileName = billInfo.fileName);
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`UPDATE claims SET bill_name = ${billInfo.fileName}, bill_url = ${billInfo.fileUrl}, status = 'IN_REVIEW' WHERE claim_id = ${claimId}`);
}

@workflow:Activity
function approveAndPay(string claimId, string remarks) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`UPDATE claims SET status = 'APPROVED', comment = ${remarks} WHERE claim_id = ${claimId}`);
    log:printInfo("Claim approved and sent for payment", claimId = claimId);
}

@workflow:Activity
function notifyRejection(string claimId, string remarks) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`UPDATE claims SET status = 'REJECTED', comment = ${remarks} WHERE claim_id = ${claimId}`);
    log:printInfo("Claim rejected; the employee is notified", claimId = claimId);
}
