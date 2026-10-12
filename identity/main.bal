// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org).
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// A simple username and password sign-in service for the demo apps, not an identity provider. The gateway (nginx)
// asks GET /session on every API call and forwards the signed-in user to the claims integration and the Workflow
// Management API.

import ballerina/crypto;
import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbUser = "identity";
configurable string dbPassword = "identity";
configurable string dbName = "identity";
configurable int port = 9095;
configurable SeedUser[] users = [];

const SESSION_COOKIE = "claim_session";

# A user as configured; the password is hashed before it is stored.
type SeedUser record {|
    string username;
    string password;
    string name;
    string title;
    string roles;
|};

# A signed-in user, as the apps see it.
type User record {|
    string username;
    string name;
    string title;
    string roles;
|};

type Credentials record {|
    string username;
    string password;
|};

type StoredUser record {|
    *User;
    string password_hash;
|};

final mysql:Client db = check new (dbHost, dbUser, dbPassword, dbName, dbPort);

// Sessions live in memory: restarting the service signs everyone out, which suits a demo.
isolated map<User & readonly> sessions = {};

function init() returns error? {
    foreach SeedUser u in users {
        string hash = check crypto:hashBcrypt(u.password);
        _ = check db->execute(`INSERT INTO users (username, password_hash, name, title, roles)
            VALUES (${u.username}, ${hash}, ${u.name}, ${u.title}, ${u.roles})
            ON DUPLICATE KEY UPDATE password_hash = ${hash}, name = ${u.name}, title = ${u.title}, roles = ${u.roles}`);
    }
    log:printInfo("Users ready", count = users.length());
}

service / on new http:Listener(port) {

    resource function post login(http:Request request, @http:Payload Credentials credentials)
            returns http:Response|http:Unauthorized|error {
        StoredUser|error stored = db->queryRow(`SELECT username, name, title, roles, password_hash FROM users
            WHERE username = ${credentials.username}`);
        if stored is error || !check crypto:verifyBcrypt(credentials.password, stored.password_hash) {
            return http:UNAUTHORIZED;
        }
        User & readonly user = {username: stored.username, name: stored.name, title: stored.title, roles: stored.roles};
        string token = uuid:createType4AsString();
        lock {
            sessions[token] = user;
        }
        http:Response response = new;
        response.setJsonPayload(user);
        response.addHeader("Set-Cookie", sessionCookie(request, token));
        return response;
    }

    resource function post logout(http:Request request) returns http:Response {
        string? token = sessionToken(request);
        if token is string {
            lock {
                _ = sessions.removeIfHasKey(token);
            }
        }
        http:Response response = new;
        response.addHeader("Set-Cookie", sessionCookie(request, "", expire = true));
        return response;
    }

    // The signed-in user, for the apps' top bar.
    resource function get me(http:Request request) returns User|http:Unauthorized {
        return currentUser(request) ?: http:UNAUTHORIZED;
    }

    // The gateway's check: 200 with the user in headers, or 401.
    resource function get session(http:Request request) returns http:Response|http:Unauthorized {
        User? user = currentUser(request);
        if user is () {
            return http:UNAUTHORIZED;
        }
        http:Response response = new;
        response.setHeader("x-user-id", user.username);
        response.setHeader("x-user-roles", user.roles);
        return response;
    }
}

// The session cookie. On a loopback host (localhost, 127.0.0.1) it is also SameSite=None and Secure, which browsers
// accept over plain http there, so the apps also work inside frames of another local page (as in the demo recording,
// which shows two users side by side). Any other host keeps the browser default (Lax).
isolated function sessionCookie(http:Request request, string token, boolean expire = false) returns string {
    string cookie = string `${SESSION_COOKIE}=${token}; Path=/; HttpOnly`;
    if expire {
        cookie += "; Max-Age=0";
    }
    string|http:HeaderNotFoundError host = request.getHeader("x-forwarded-host");
    if host is string && (host.startsWith("localhost") || host.startsWith("127.0.0.1")) {
        cookie += "; SameSite=None; Secure";
    }
    return cookie;
}

isolated function sessionToken(http:Request request) returns string? {
    foreach http:Cookie cookie in request.getCookies() {
        if cookie.name == SESSION_COOKIE && cookie.value != "" {
            return cookie.value;
        }
    }
    return ();
}

isolated function currentUser(http:Request request) returns User? {
    string? token = sessionToken(request);
    if token is () {
        return ();
    }
    lock {
        (User & readonly)? user = sessions[token];
        return user;
    }
}
