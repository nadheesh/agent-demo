FROM jayanihewavitharana/agent:latest

ARG USER=agent
ARG USER_ID=10500

USER root

RUN adduser --disabled-password -G troupe -u $USER_ID -h /home/ballerina $USER

COPY ./openapi /home/ballerina/openapi
# COPY ./Config.toml /home/ballerina/Config.toml

WORKDIR /home/ballerina

EXPOSE  9090
USER $USER

CMD java -Xdiag -cp "jayanihewavitharana-agent_service-0.1.0.jar:jars/*" 'jayanihewavitharana.agent_service.0.$_init'
