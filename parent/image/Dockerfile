FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tar \
    unzip \
    libicu70 \
    git \
    sudo \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /myagent

COPY vsts-agent-linux-x64-4.260.0.tar.gz /tmp/agent.tar.gz

RUN echo "4C3AF1450788BC19B847253B02CB82036DBA55B4B563CD2563FAD9B46DE8B9C8  /tmp/agent.tar.gz" | sha256sum --check --status \
    && tar -xzf /tmp/agent.tar.gz -C /myagent \
    && rm /tmp/agent.tar.gz \
    && useradd --create-home agentuser \
    && chown -R agentuser:agentuser /myagent

USER agentuser

COPY configure_agent.py /myagent/

ENTRYPOINT ["python3", "configure_agent.py"]
