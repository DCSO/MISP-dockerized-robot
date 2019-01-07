FROM debian:stretch-slim

#     Variables for Labels:
ARG VENDOR="DCSO GmbH"
ARG COMPONENT="robot"
ARG BUILD_DATE
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
ARG RELEASE_DATE
ARG NAME="MISP-dockerized-${COMPONENT}"
ARG DESCRIPTION="This docker container is part of the DCSO MISP dockerized environment."
ARG DOCUMENTATION="https://github.com/DCSO/MISP-dockerized"
ARG AUTHOR="DCSO <misp.docker@dcso.de>"
ARG LICENSE="BSD-3-Clause"
#     END Variables

#########################################
LABEL   org.label-schema.build-date="${BUILD_DATE}" \
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

# Ansible Installation:
# + software-properties-common
# For our Own Scripts:
# + make git net-tools iputils-ping sudo wget zip locales
# + 
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y; \
    apt-get upgrade -y; \
    apt-get install -y \ 
        nano \
        sudo \
        make \
        apt-utils \
        ;\
    apt-get autoremove -y; \ 
    apt-get clean -y

RUN apt-get update -y; \
    apt-get install -y \ 
        git \
        inetutils-ping \
        mysql-client \
        ;\
    apt-get autoremove -y; \ 
    apt-get clean -y



# Install big software-properties-common dependency
# + libpython3.5-dev
RUN apt-get update; apt-get -y install \
    libpython3.5-dev ; \
    apt-get autoremove -y; \ 
    apt-get clean -y

# Docker Installation: 
# + apt-transport-https
# + ca-certificates
# + curl
# + gnupg2
# + software-properties-common
RUN apt-get update; apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common ;\
    apt-get autoremove -y; \ 
    apt-get clean -y


RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - ; \
    apt-key fingerprint 0EBFCD88; \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" ;\
    apt-get update; \
    apt-get install -y docker-ce; \
    apt-get autoremove -y; \
    apt-get clean -y

# change language
# RUN locale-gen en_US.UTF-8
# ENV LANG en_US.UTF-8

# Setup Ansible
# https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-debian
RUN curl -fsSL http://keyserver.ubuntu.com/pks/lookup?op=get\&search=0x93C4A3FD7BB9C367 | apt-key add - \ 
    ; apt-key fingerprint 93C4A3FD7BB9C367 \
    ; add-apt-repository "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" \
    ; apt-get update \
    ; apt-get -y --allow-unauthenticated install ansible \
    ; apt-get autoremove -y \
    ; apt-get clean -y \
    mkdir /etc/ansible/playbooks

# Install dependencies for PIP3:
# + Install python-pip3 for pip3
# + Install openssl for pyopenssl
# + libxml2-dev  for pyopenssl
# + libxslt1-dev  for pyopenssl
# + zlib1g-dev  for pyopenssl
RUN apt-get update -y; \
    apt-get install -y \         
        # python3 \
        python-pip \
        # openssl \
        # zip \
        # mariadb-client \
        # python-mysqldb \
        # python-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        # python-setuptools \
        ; \
    apt-get autoremove -y; \ 
    apt-get clean -y

# Install:
#+ docker-compose
#+ pyopenssl for ansible openssl modules
RUN pip --no-cache-dir install docker-compose \
    ; pip --no-cache-dir install pyopenssl

# Install git
RUN apt-get update -y; \
    apt-get install -y \         
        git ; \
    apt-get autoremove -y; \ 
    apt-get clean -y


# Install MISP-dockerized-testbench
    ARG GIT_FOLDER="/srv/MISP-dockerized-testbench"

    # apt-get is available (mostly debian or ubuntu)
    RUN apt-get update; \
        apt-get -y install sudo \
            git \
            bash \
            make \
            python3 \
            python3-pip \
            python3-venv \
            mysql-client \
            ; \
            apt-get -y autoremove; \
            apt-get -y clean

    # clone the repository
    RUN git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER; \
        pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt



# Setup Workdir
WORKDIR /srv

# Add scripts
COPY files/scripts /srv/scripts

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
ENV RELEASE_DATE ${RELEASE_DATE}

