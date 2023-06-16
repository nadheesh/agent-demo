FROM jayanihewavitharana/agent:latest

USER root

RUN adduser --disabled-password -G troupe -u 10500 -h /home/ballerina "agent"

COPY ./openapi /home/ballerina/openapi
# COPY ./Config.toml /home/ballerina/Config.toml

WORKDIR /home/ballerina

EXPOSE  9090
USER 10500

CMD java -Xdiag -cp "jayanihewavitharana-agent_service-0.1.0.jar:jars/*" 'jayanihewavitharana.agent_service.0.$_init'
