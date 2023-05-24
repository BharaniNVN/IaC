FROM ubuntu:20.04

ARG AGENTUSER="someuser"
ARG AZURE_CLI_VERSION=2.33.1
ARG POWERSHELL_VERSION=7.2.1
ARG TERRAFORM_VERSION=0.12.31
ARG ANSIBLE_VERSION=2.9.27

LABEL org.opencontainers.image.title="Azure DevOps Agent" \
    org.opencontainers.image.description="Azure DevOps Agent with prerequisites installed for IaC builds and releases" \
    org.opencontainers.image.vendor="MatrixCare HHP" \
    com.matrixcare.operations.project="Infrastructure As Code" \
    org.opencontainers.image.authors="HHPOPS@mxhhpprod.com" \
    org.opencontainers.image.source="https://dev.azure.com/MatrixCareHHP/HHP/_git/IAC"

ENV DEBIAN_FRONTEND=noninteractive
ENV AZ_VERSION=$AZURE_CLI_VERSION
ENV POWERSHELL_VERSION=$POWERSHELL_VERSION
ENV TERRAFORM_VERSION=$TERRAFORM_VERSION
ENV ANSIBLE_VERSION=$ANSIBLE_VERSION

RUN useradd --create-home --no-log-init --shell /bin/bash ${AGENTUSER}

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes && \
    echo "APT::Get::Install-Recommends \"false\";" > /etc/apt/apt.conf.d/95installrecommends

# hadolint ignore=DL3008,DL3014,DL3015
RUN apt-get update && \
    apt-get upgrade && \
    apt-get install \
    acl \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    dnsutils \
    git \
    iputils-ping \
    jq \
    libcurl4 \
    libgssapi-krb5-2 \
    libicu66 \
    libkrb5-3 \
    liblttng-ust0 \
    libssl1.1 \
    gnupg2 \
    libunwind8 \
    lsb-release \
    netcat \
    python3-pip \
    python3-setuptools \
    runit \
    unzip \
    zip \
    zlib1g && \
    rm -rf /var/lib/apt/lists/*

# Install azure cli
# hadolint ignore=DL3014,DL3015,DL4006
RUN echo "==> Installing azure cli ${AZURE_CLI_VERSION}..." && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.asc.gpg && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/azure-cli.list && \
    apt-get install azure-cli="${AZURE_CLI_VERSION}*" && \
    rm -rf /var/lib/apt/lists/*

# Install powershell
# hadolint ignore=DL3014,DL3015
RUN echo "==> Installing powershell ${POWERSHELL_VERSION}..." && \
    curl -LOs "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install powershell="${POWERSHELL_VERSION}*" && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN echo "==> Installing Terraform ${TERRAFORM_VERSION}..." && \
    curl -LOs "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/terraform && \
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Install Ansible
# hadolint ignore=DL3013
RUN echo "==> Installing Ansible ${ANSIBLE_VERSION}..." && \
    pip3 install --no-cache-dir wheel && \
    pip3 install --no-cache-dir ansible==${ANSIBLE_VERSION}

WORKDIR /azp

COPY ./start.sh .
RUN sed -i "0,/AGENTUSER=/{s|AGENTUSER=|AGENTUSER=\"${AGENTUSER}\"|}" start.sh && \
    chmod +x start.sh

CMD ["./start.sh"]
