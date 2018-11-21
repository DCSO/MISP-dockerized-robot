FROM debian:stable-slim

#     Variables for Labels:
ARG VENDOR="DCSO GmbH"
ARG COMPONENT="robot"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
ARG NAME="MISP-dockerized-${COMPONENT}"
ARG DESCRIPTION="This docker container is part of the DCSO MISP dockerized environment."
ARG DOCUMENTATION="https://github.com/DCSO/MISP-dockerized"
ARG AUTHOR="DCSO MISP Docker Team <misp.docker@dcso.de>"
ARG LICENSE="BSD-3-Clause"
#     END Variables

#########################################
LABEL org.label-schema.build-date="${BUILD_DATE}" \
        org.label-schema.name="${NAME}" \
        org.label-schema.description="${DESCRIPTION}" \
        org.label-schema.vcs-ref="${VCS_REF}" \
        org.label-schema.vcs-url="${GIT_REPO}" \
        org.label-schema.url="${GIT_REPO}" \
        org.label-schema.vendor="${VENDOR}" \
        org.label-schema.version="${VERSION}" \
        org.label-schema.usage="${DOCUMENTATION}" \
        org.label-schema.schema-version="1.0.0-rc1"

LABEL   org.opencontainers.image.created="${BUILD_DATE}" \
        org.opencontainers.image.url="${GIT_REPO}" \
        org.opencontainers.image.source="${GIT_REPO}" \
        org.opencontainers.image.version="${VERSION}" \
        org.opencontainers.image.revision="${VCS_REF}" \
        org.opencontainers.image.vendor="${VENDOR}" \
        org.opencontainers.image.title="${NAME}" \
        org.opencontainers.image.description="${DESCRIPTION}" \
        org.opencontainers.image.documentation="${DOCUMENTATION}" \
        org.opencontainers.image.authors="${AUTHOR}" \
        org.opencontainers.image.licenses="${LICENSE}"
#########################################


# Install core, additional and docker dependency components
# Docker Installation: 
# + apt-transport-https
# + ca-certificates
# + curl
# + software-properties-common
# Ansible Installation:
# + software-properties-common
# For our Own Scripts:
# + make git net-tools iputils-ping sudo wget zip locales
# + 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y; \
    apt-get install -y \ 
        software-properties-common \
        rng-tools \
        nano \
        vim \
        curl \
        apt-transport-https \
        ca-certificates \
        make \
        git \
        net-tools \
        iputils-ping \
        sudo \
        wget \
        locales \
        python \
        python-pip \
        python3 \
        python3-pip \
        openssl \
        zip \
        mariadb-client \
        python-mysqldb \
        python-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        python-setuptools \
        ; \
    apt-get upgrade -y; \
    apt-get autoremove -y; \ 
    apt-get clean -y

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ; \
    apt-key fingerprint 0EBFCD88; \
    add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ;\
    apt-get update; \
    apt-get install -y docker-ce; \
    apt-get autoremove -y; \
    apt-get clean -y

# change language
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# Update PIP & PIP 3
# + Install docker-py for docker ansible module
# + Install pyopen ssl for openssl ansible module
# + Install docker-compose
RUN pip install docker-compose \
    ; pip install pyopenssl \
    ; pip install --upgrade pip \
    ; pip3 install --upgrade pip
    
# Setup Ansible
RUN add-apt-repository -y ppa:ansible/ansible; \
    apt-get update -y; \
    apt-get install ansible -y; \
    apt-get autoremove -y; \
    apt-get clean -y \
    mkdir /etc/ansible/playbooks


# Setup Workdir
WORKDIR /srv

# Add Healthcheck Config
HEALTHCHECK NONE

# Environment Variable for Proxy
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
ENV NO_PROXY="0.0.0.0"

# Environment Variable to check Version
# Version + Name
    ENV NAME ${NAME}
    ENV VERSION ${VERSION}