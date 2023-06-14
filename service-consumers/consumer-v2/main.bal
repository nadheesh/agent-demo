import ballerina/http;
import ballerina/io;

configurable string openapiPath = ?;
configurable string apiServiceUrl = ?;
configurable string platformServiceUrl = ?;

const ORG_ID = 1;

type RegisterToolsInput record {|
    int orgId;
    string serviceUrl;
    json openapi;
|};

type ExecuteToolInput record {|
    int orgId;
    string command;
|};

final http:Client platformServiceClient = check new(platformServiceUrl);

public function main() returns error? {
    // register tools
    // io:println("\n\nRegistering tools...");
    // string registerRes = check registerTools();
    // io:println(registerRes);

    // execute command
    string command = "list all my wifi accounts and send it to my email address. my email is alice@gmail.com";
    io:println("\n\nExecuting command: " + command);
    json executeRes = check executeCommand(command);
    io:println(executeRes.response);
}

function registerTools() returns string|error {
    RegisterToolsInput payload = {
        serviceUrl: apiServiceUrl,
        openapi: check io:fileReadJson(openapiPath),
        orgId: ORG_ID
    };
    http:Response response = check platformServiceClient->post("/register", payload);
    return response.getTextPayload();
}

function executeCommand(string command) returns json|error {
    ExecuteToolInput payload = {
        command,
        orgId: ORG_ID
    };
    http:Response response = check platformServiceClient->post("/execute", payload);
    return response.getJsonPayload();
}