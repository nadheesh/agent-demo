import ballerina/io;
import ballerina/http;
import ballerina/file;
import ballerinax/ai.agent;

configurable string openAIToken = ?;

const string OPENAPI_PATH = "openapi.json";

type RegisterToolsInput record {|
    string serviceUrl;
    json openapi;
|};

type ExecuteToolInput record {|
    string command;
|};

type ToolKitData record {|
    readonly int toolkitId;
    agent:HttpServiceToolKit toolkit;
|};

table<ToolKitData> key(toolkitId) registeredToolKits = table[];

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post register(@http:Payload RegisterToolsInput payload) returns string|error {
        check io:fileWriteJson(OPENAPI_PATH, payload.openapi);

        agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpec(OPENAPI_PATH);
        agent:HttpServiceToolKit toolKit = check new (payload.serviceUrl, apiSpecification.tools);

        int nextId = registeredToolKits.nextKey();
        registeredToolKits.put({toolkitId: nextId, toolkit: toolKit});
        check file:remove(OPENAPI_PATH);

        return "Successfully registered the tools from the OpenAPI specification.";

    }

    resource function post execute(@http:Payload ExecuteToolInput payload) returns json|error {

        agent:HttpServiceToolKit[] toolKits = [];

        foreach ToolKitData row in registeredToolKits {
            toolKits.push(row.toolkit);
        }

        agent:Gpt3Model model = check new ({auth: {token: openAIToken}});
        agent:Agent agent = check new (model, ...toolKits);

        agent:ExecutionStep[] agentExecutionSteps = agent.run(payload.command);
        
        return {"response": agentExecutionSteps.toString()};
    }
}
