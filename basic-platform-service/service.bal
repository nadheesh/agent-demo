import ballerina/io;
import ballerina/http;
import ballerina/file;
import ballerinax/ai.agent;

configurable string openAIToken = ?;

const string OPENAPI_PATH = "openapi.json";

type RegisterToolsInput record {|
    string toolKitName; // any unique name as an identifier for the tool kit
    string serviceUrl;
    json openapi;
|};

type ExecuteToolInput record {|
    string toolKitName;
    string command;
|};

type ToolKitData record {|
    readonly string name;
    agent:HttpServiceToolKit toolkit;
|};

table<ToolKitData> key(name) registeredToolKits = table[];

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post register(@http:Payload RegisterToolsInput payload) returns string|error {
        check io:fileWriteJson(OPENAPI_PATH, payload.openapi);

        agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpec(OPENAPI_PATH);
        agent:HttpServiceToolKit toolKit = check new (payload.serviceUrl, apiSpecification.tools);

        boolean toolKitNameExists = registeredToolKits.hasKey(payload.toolKitName);

        registeredToolKits.put({name: payload.toolKitName, toolkit: toolKit});
        check file:remove(OPENAPI_PATH);

        if toolKitNameExists {
            return "A tool kit with the name " + payload.toolKitName + " already exists. The tool kit has been updated.";
        }
        return "Successfully registered the tools from the OpenAPI specification.";

    }

    resource function post execute(@http:Payload ExecuteToolInput payload) returns json|error {
        if !registeredToolKits.hasKey(payload.toolKitName) {
            return "A tool kit with the name " + payload.toolKitName + " is not registered. Register the tool kit using the OpenAPI specification prior to execution.";
        }

        ToolKitData toolKitData = registeredToolKits.get(payload.toolKitName);
        agent:HttpServiceToolKit toolKit = toolKitData.toolkit;

        agent:Gpt3Model model = check new ({auth: {token: openAIToken}});
        agent:Agent agent = check new (model, toolKit);

        agent:ExecutionStep[] agentExecutionSteps = agent.run(payload.command);
        
        return {"response": agentExecutionSteps.toString()};
    }
}
