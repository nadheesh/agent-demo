import ballerina/http;

type SendEmailPayload record {|
    string email;
    string subject;
    string content;
|};

service / on new http:Listener(8090) {

    resource function post sendEmail(@http:Payload SendEmailPayload payload) returns string {
        return "Successfully sent the email to " + payload.email;
    }

}
