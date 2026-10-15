import ballerina/http;
import ballerina/jwt;
import ballerina/sql;
import ballerina/workflow;
import ballerina/workflow.management.rest as _;

listener http:Listener httpDefaultListener = http:getDefaultListener();

// Every call carries the signed-in user's access token from Thunder; the employee is taken from it.
@http:ServiceConfig {
    auth: [{jwtValidatorConfig: {issuer: jwtIssuer, signatureConfig: {jwksConfig: {url: jwksUrl}}}}]
}
service /claims on httpDefaultListener {
    resource function post .(@http:Header string? authorization, @http:Payload Claim payload) returns json|error {
        do {
            Claim claim = {employee: check employeeOf(authorization), description: payload.description, amount: payload.amount};
            string claimId = check workflow:run(processClaim, claim);
            return claimId;
        } on fail error err {
            return error("unhandled error", err);
        }
    }

    resource function post [string claimId]/bill(@http:Payload Bill payload) returns json|error {
        do {
            check workflow:sendData(processClaim, claimId, "bill", payload);
        } on fail error err {
            return error("unhandled error", err);
        }
    }

    resource function get .(@http:Header string? authorization) returns json|error {
        do {
            string employee = check employeeOf(authorization);
            stream<record {|anydata...;|}, sql:Error?> claims = claimsDb->query(`SELECT claim_id AS claimId, employee, description, amount, status, bill_name AS billName, bill_url AS billUrl, comment, DATE_FORMAT(submitted_at, '%Y-%m-%dT%H:%i:%sZ') AS submittedAt, DATE_FORMAT(updated_at, '%Y-%m-%dT%H:%i:%sZ') AS updatedAt FROM claims WHERE employee = ${employee} ORDER BY submitted_at DESC`);
            record {|anydata...;|}[] rows = check from var row in claims
                select row;
            return rows.toJson();
        } on fail error err {
            return error("unhandled error", err);
        }
    }
}

// The signed-in user's email, from the token the service has already validated.
function employeeOf(string? authorization) returns string|error {
    string bearer = authorization ?: "";
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(bearer.substring(bearer.startsWith("Bearer ") ? 7 : 0));
    return (payload["username"] ?: payload.sub ?: "").toString();
}
