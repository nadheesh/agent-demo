FROM nadheesh/agent:v1.0.0

USER root

RUN adduser --disabled-password -G troupe -u 10001 -h /home/ballerina "agent"

# COPY ./openapi /home/ballerina/openapi
# # COPY ./Config.toml /home/ballerina/Config.toml

WORKDIR /home/ballerina

EXPOSE  9090
USER 10001

CMD java -Xdiag -cp "nadheesh-agent_service-0.1.0.jar:jars/*" 'nadheesh.agent_service.0.$_init'
