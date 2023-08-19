import ballerina/http;
import ballerina/file;
import ballerina/log;
import ballerinax/ai.agent;
import ballerina/regex;

configurable string azureDeployementId = ?;
configurable string azureApiVersion = ?;
configurable string azureServiceUrl = ?;
configurable string azureOpenAIToken = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string tokenUrl = ?;

const string OPENAPI_DIR_PATH = "openapi";

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

        // load all the open api specs in the directory
        foreach file:MetaData file in files {
            string filePath = file.absPath;
            agent:HttpApiSpecification apiSpecification = check agent:extractToolsFromOpenApiSpecFile(filePath);
            string? serviceUrl = apiSpecification.serviceUrl;
            if (serviceUrl == null) {
                log:printError("Service name is not defined in the open api spec file: " + filePath);
                continue;
            }
            agent:HttpServiceToolKit toolKit = check new (serviceUrl, apiSpecification.tools, {
                auth: {
                    tokenUrl,
                    clientId,
                    clientSecret
                }
            });
            toolKits.push(toolKit);
        }
        agent:AzureGpt3Model model = check new ({auth: {apiKey: azureOpenAIToken}}, azureServiceUrl, azureDeployementId, azureApiVersion);
        self.agent = check new (model, ...toolKits);
        log:printInfo("Agent initialized successfully...");
    }

    resource function post execute(@http:Payload ExecuteCommandInput payload) returns json|error {
        agent:Agent agent = self.agent;

        // execute the command
        agent:ExecutionStep[] agentExecutionSteps = agent.run(
            payload.command,
            context = "Possible train stations are Colombo, Galle and Kandy. My location is Colombo."
        );

        // returns only the final outcome
        string answer = agentExecutionSteps.pop().thought;
        string[] splitedAnswer = regex:split(answer, "Final Answer:");
        return splitedAnswer[splitedAnswer.length() - 1].trim();
    }
}
