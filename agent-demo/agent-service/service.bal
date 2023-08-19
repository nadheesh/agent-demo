import ballerina/http;
import ballerina/file;
import ballerina/log;
import ballerinax/ai.agent;
import ballerina/regex;

configurable string azureOpenAIToken = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;

const string DEPLOYMENT_ID = "gpt3";
const string API_VERSION = "2023-05-15";
const string SERVICE_URL = "https://openai-rnd.openai.azure.com/openai";
const string OPENAPI_DIR_PATH = "openapi";

// const string OPENAPI_DIR_PATH = "/home/ballerina/openapi";

type ExecuteCommandInput record {|
    string command;
|};

type AgentData record {|
    readonly int orgId;
    agent:Agent agent;
    map<agent:HttpServiceToolKit> toolKits;
|};

isolated service / on new http:Listener(9090) {

    private final agent:Agent agent;

    function init() returns error? {
        agent:HttpServiceToolKit[] toolKits = [];
        file:MetaData[] files = check file:readDir(OPENAPI_DIR_PATH);
        foreach file:MetaData file in files {
            string filePath = file.absPath;
            if !(file.absPath.endsWith(".json") || file.absPath.endsWith(".yaml")) {
                continue;
            }
            agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpecFile(filePath);
            string? serviceUrl = apiSpecification.serviceUrl;
            if serviceUrl == () {
                return error("Service URL not found for the API: " + filePath);
            }
            agent:HttpServiceToolKit toolKit = check new (serviceUrl, apiSpecification.tools, {
                auth: {
                    tokenUrl: "https://sts.choreo.dev/oauth2/token",
                    clientId,
                    clientSecret
                }
            });
            toolKits.push(toolKit);
        }
        agent:AzureGpt3Model model = check new ({auth: {apiKey: azureOpenAIToken}}, SERVICE_URL, DEPLOYMENT_ID, API_VERSION);
        self.agent = check new (model, ...toolKits);
        log:printInfo("Agent initialized successfully...");
    }

    resource function post execute(@http:Payload ExecuteCommandInput payload) returns json|error {
        agent:Agent? agent = self.agent;
        if agent == () {
            return error("Agent is not initialized");
        }
        agent:ExecutionStep[] agentExecutionSteps = agent.run(payload.command, context = "Possible train stations are Colombo, Galle and Kandy. My location is Colombo.");

        string answer = agentExecutionSteps.pop().thought;
        string[] splitedAnswer = regex:split(answer, "Final Answer:");

        return splitedAnswer[splitedAnswer.length() - 1].trim();
    }
}
