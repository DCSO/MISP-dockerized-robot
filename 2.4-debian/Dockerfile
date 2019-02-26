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
        vim \
        sudo \
        make \
        bash \
        inetutils-ping \
        ;\
    apt-get autoremove -y; \ 
    apt-get clean -y


# Docker Installation: 
    # Install big software-properties-common dependency
    # + libpython3.5-dev
    RUN apt-get update \
        ;apt-get -y install \
            libpython3.5-dev \
        ;apt-get autoremove -y \ 
        ;apt-get clean -y

    # Install dependencies
    # + apt-transport-https
    # + ca-certificates
    # + curl
    # + gnupg2
    # + software-properties-common
    RUN apt-get update \
        ;apt-get -y install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg2 \
            software-properties-common \
            python3-pip \
            python3-setuptools \
        ;apt-get autoremove -y \ 
        ;apt-get clean -y
    # Install Docker + docker-compose
    RUN apt-get update \
        ;apt-get -y install \
            curl \
        ;curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -  \
        ;apt-key fingerprint 0EBFCD88 \
        ;add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        ;apt-get update \
        ;apt-get install -y \
            docker-ce \
        ;apt-get autoremove -y \
        ;apt-get clean -y \
        ;pip3 --no-cache-dir install docker-compose \
        ;


# # Setup Ansible
    # # https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-debian
    # RUN curl -fsSL http://keyserver.ubuntu.com/pks/lookup?op=get\&search=0x93C4A3FD7BB9C367 | apt-key add - \ 
    #     ; apt-key fingerprint 93C4A3FD7BB9C367 \
    #     ; add-apt-repository "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" \
    #     ; apt-get update \
    #     ; apt-get -y --allow-unauthenticated install ansible \
    #     ; apt-get autoremove -y \
    #     ; apt-get clean -y \
    #     mkdir /etc/ansible/playbooks

    # Install dependencies for PIP3:
    # + Install python-pip3 for pip3
    # + Install openssl for pyopenssl
    # + libxml2-dev  for pyopenssl
    # + libxslt1-dev  for pyopenssl
    # + zlib1g-dev  for pyopenssl
    # RUN apt-get update -y; \
    #     apt-get install -y \         
    #         # python-pip \
    #         # libxml2-dev \
    #         # libxslt1-dev \
    #         # zlib1g-dev \
    #         ; \
    #     apt-get autoremove -y; \ 
    #     apt-get clean -y

    # Install:
    #+ pyopenssl for ansible openssl modules
    # RUN pip3 --no-cache-dir install pyopenssl


# Install MISP-dockerized-testbench
    ARG GIT_FOLDER="/srv/MISP-dockerized-testbench"
    
    # Install dependencies and clone the repository
    # apt-get is available (mostly debian or ubuntu)
    RUN apt-get update \
        ;apt-get -y install \
            git \
            python3-minimal \
            python3-pip \
            python3-venv \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER \
        ;pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt \
        ;


# Install PyMISP
    RUN pip3 install --no-cache-dir request pymisp


# Install MySQL Tuner
    RUN apt-get update \
        ;apt-get -y install \
            wget \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;mkdir -p /srv/scripts/mysqltuner \
        ;cd /srv/scripts/mysqltuner \
        ;wget http://mysqltuner.pl/ -O mysqltuner.pl \
        ;chmod +x mysqltuner.pl \
        ;wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O basic_passwords.txt \
        ;wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O vulnerabilities.csv \
        ;

# Download Sysschema for MariaDB
    RUN apt-get update \
        ;apt-get -y install \
            curl \
            unzip \
            mysql-client \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;mkdir /srv/DB_improvement \
        ;cd /srv/DB_improvement \
        ;curl "https://codeload.github.com/good-dba/mariadb-sys/zip/master" > mariadb-sys.zip \
        ;unzip -l mariadb-sys.zip \
        ;unzip mariadb-sys.zip \
        #;cd mariadb-sys-master/ 
        #mysql -u root -p < ./mariadb_sys_install.sql
        ;

# Setup Workdir
WORKDIR /srv

# Add scripts
COPY files/scripts/backup_restore.sh /srv/scripts/
COPY files/scripts/configure_misp.sh /srv/scripts/
COPY files/scripts/deploy_environment.sh /srv/scripts/
COPY files/scripts/test.sh /srv/scripts/

COPY files/scripts/pymisp_scripts/keys.py /srv/scripts/pymisp_scripts/
COPY files/scripts/pymisp_scripts/migrate_events.py /srv/scripts/pymisp_scripts/
COPY files/scripts/pymisp_scripts/misp_cron.py /srv/scripts/pymisp_scripts/

COPY files/.bashrc /root/
COPY files/entrypoint.sh /

# Add Entrypoint
#ENTRYPOINT [ "/entrypoint.sh" ]

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

# Add /srv/srcipts to path var
ENV PATH=/srv/scripts:$PATH
