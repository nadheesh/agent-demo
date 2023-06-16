FROM jayanihewavitharana/agent:v0.1.0

COPY ./openapi /home/ballerina/openapi
COPY ./Config.toml /home/ballerina/Config.toml

CMD java -Xdiag -cp "jayanihewavitharana-agent_service-0.1.0.jar:jars/*" 'jayanihewavitharana.agent_service.0.$_init'
