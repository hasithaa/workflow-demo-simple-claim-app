import ballerina/sql;
import ballerina/workflow;

@workflow:Activity
function createClaim(string claimId, Claim claim) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`INSERT INTO claims (claim_id, employee, description, amount, status) VALUES (${claimId}, ${claim.employee}, ${claim.description}, ${claim.amount}, 'BILL_REQUIRED')`);
}

@workflow:Activity
function attachBill(string claimId, Bill billInfo) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`UPDATE claims SET bill_name = ${billInfo.fileName}, bill_url = ${billInfo.fileUrl}, status = 'IN_REVIEW' WHERE claim_id = ${claimId}`);
}

@workflow:Activity
function recordDecision(string claimId, string status, string remarks) returns error? {
    sql:ExecutionResult sqlExecutionresult = check claimsDb->execute(`UPDATE claims SET status = ${status}, comment = ${remarks} WHERE claim_id = ${claimId}`);
}
