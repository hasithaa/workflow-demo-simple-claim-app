import ballerina/http;
import ballerina/sql;
import ballerina/workflow;
import ballerina/workflow.management.rest as _;

listener http:Listener httpDefaultListener = http:getDefaultListener();

service /claims on httpDefaultListener {
    resource function post .(@http:Payload Claim payload) returns json|error {
        do {
            string claimId = check workflow:run(processClaim, payload);
            return claimId;
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    resource function post [string claimId]/bill(@http:Payload Bill payload) returns json|error {
        do {
            check workflow:sendData(processClaim, claimId, "bill", payload);
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    resource function get .(@http:Query string employee) returns json|error {
        do {
            stream<record {|anydata...;|}, sql:Error?> claims = claimsDb->query(`SELECT claim_id AS claimId, employee, description, amount, status, bill_name AS billName, bill_url AS billUrl, comment, DATE_FORMAT(submitted_at, '%Y-%m-%dT%H:%i:%sZ') AS submittedAt, DATE_FORMAT(updated_at, '%Y-%m-%dT%H:%i:%sZ') AS updatedAt FROM claims WHERE employee = ${employee} ORDER BY submitted_at DESC`);
            record {|anydata...;|}[] rows = check from var row in claims
                select row;
            return rows.toJson();
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

}
