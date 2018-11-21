FROM debian:stable-slim

#     Variables:
# for Labels:
ARG VENDOR="DCSO GmbH <www.dcso.de>"
ARG RELEASE_DATE
ARG IS_PRODUCTION="false"
ARG MAINTAINER="DCSO MISP <misp@dcso.de>"
ARG BUILD_DATE
ARG NAME
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
#     END Variables

LABEL vendor=${VENDOR}
LABEL de.dcso.misp-server.version=${VERSION}
LABEL de.dcso.misp-server.release-date=${RELEASE_DATE}
LABEL de.dcso.misp-server.is-production=${IS_PRODUCTION}
LABEL maintainer=${MAINTAINER}
LABEL org.label-schema.build-date="${BUILD_DATE}" \
          org.label-schema.name="MISP-dockerized ${NAME}" \
          org.label-schema.description="This docker container is part of the DCSO MISP dockerized environment." \
          org.label-schema.vcs-ref="${VCS_REF}" \
          org.label-schema.vcs-url="${GIT_REPO}" \
          org.label-schema.vendor="${VENDOR}" \
          org.label-schema.version="${VERSION}" \
          org.label-schema.schema-version="1.0.0-rc1"


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
ENV VERSION=${VERSION}