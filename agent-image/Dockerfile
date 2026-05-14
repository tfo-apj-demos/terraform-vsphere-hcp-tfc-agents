FROM hashicorp/tfc-agent:latest

USER root

COPY ca-chain.pem /usr/local/share/ca-certificates/hashicorp-local-chain.crt
RUN update-ca-certificates

USER tfc-agent
