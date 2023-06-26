import ballerina/http;
import ballerina/file;
import ballerina/log;
import ballerinax/ai.agent;
import ballerina/regex;

configurable string openAIToken = ?;
configurable string accessToken = ?;

const string OPENAPI_DIR_PATH = "/home/ballerina/openapi";

type ExecuteCommandInput record {|
    string command;
|};

type AgentData record {|
    readonly int orgId;
    agent:Agent agent;
    map<agent:HttpServiceToolKit> toolKits;
|};

# A service representing a network-accessible API
# bound to port `9090`.
isolated service / on new http:Listener(9090) {

    private final agent:Agent agent;

    function init() returns error? {
        agent:HttpServiceToolKit[] toolKits = [];
        file:MetaData[] files = check file:readDir(OPENAPI_DIR_PATH);
        foreach file:MetaData file in files {
            string filePath = file.absPath;
            if !file.absPath.endsWith(".json") {
                continue;
            }
            agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpec(filePath);
            string? serviceUrl = apiSpecification.serviceUrl;
            if serviceUrl == () {
                return error("Service URL not found for the API: " + filePath);
            }
            agent:HttpServiceToolKit toolKit = check new (serviceUrl, apiSpecification.tools, headers = {
                "authorization": "Bearer " + accessToken
            });
            toolKits.push(toolKit);
        }
        agent:Gpt3Model model = check new ({auth: {token: openAIToken}});
        self.agent = check new (model, ...toolKits);
        log:printInfo("Agent initialized successfully...");
    }

    resource function post execute(@http:Payload ExecuteCommandInput payload) returns json|error {
        agent:Agent? agent = self.agent;
        if agent == () {
            return error("Agent is not initialized");
        }
        agent:ExecutionStep[] agentExecutionSteps = agent.run(payload.command);

        string answer = agentExecutionSteps.pop().thought;
        string[] splitedAnswer = regex:split(answer, "Final Answer:");

        return splitedAnswer[splitedAnswer.length() - 1].trim();
    }
}
