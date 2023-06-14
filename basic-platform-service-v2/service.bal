import ballerina/io;
import ballerina/http;
import ballerina/file;
import ballerinax/ai.agent;

configurable string openAIToken = ?;

const string OPENAPI_PATH = "openapi.json";

type RegisterToolsInput record {|
    int orgId;
    string serviceUrl;
    json openapi;
|};

type ExecuteToolInput record {|
    int orgId;
    string command;
|};

type AgentData record {|
    readonly int orgId;
    agent:Agent agent;
    map<agent:HttpServiceToolKit> toolKits;
|};

table<AgentData> key(orgId) registeredAgents = table [];

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post register(@http:Payload RegisterToolsInput payload) returns string|error {
        agent:HttpServiceToolKit[] toolKitList = [];
        map<agent:HttpServiceToolKit> registeredToolKits = {};

        check io:fileWriteJson(OPENAPI_PATH, payload.openapi);

        agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpec(OPENAPI_PATH);
        agent:HttpServiceToolKit toolKit = check new (payload.serviceUrl, apiSpecification.tools);

        if registeredAgents.hasKey(payload.orgId) {
            AgentData agentData = registeredAgents.get(payload.orgId);
            if(agentData.toolKits.hasKey(payload.serviceUrl)) { // TODO: find a better way to check if the toolkit is already registered
                return "The toolkit is already registered for the agent.";
            }
            toolKitList = agentData.toolKits.toArray();
            toolKitList.push(toolKit);
            registeredToolKits = agentData.toolKits;
        }
        else {
            toolKitList = [toolKit];
        }

        registeredToolKits[payload.serviceUrl] = toolKit;
        agent:Gpt3Model model = check new ({auth: {token: openAIToken}});
        agent:Agent agent = check new (model, ...toolKitList);

        registeredAgents.put({orgId: payload.orgId, agent: agent, toolKits: registeredToolKits});
        check file:remove(OPENAPI_PATH);

        return "Successfully registered API for the agent.";
    }

    resource function post execute(@http:Payload ExecuteToolInput payload) returns json|error {

        if !registeredAgents.hasKey(payload.orgId) {
            return error("An agent not registered for the organization.");
        }
        agent:Agent agent = registeredAgents.get(payload.orgId).agent;
        agent:ExecutionStep[] agentExecutionSteps = agent.run(payload.command);

        return {"response": agentExecutionSteps.toString()};
    }
}

function isContain(agent:HttpServiceToolKit[] existingToolkits, agent:HttpServiceToolKit toolkit) returns boolean {
    return existingToolkits.some(tk => tk === toolkit); // this checks for the reference equality, but we need value equality
}
