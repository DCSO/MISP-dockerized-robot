FROM debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive


# Install core, additional and docker dependency components
RUN set -eu \
    ;apt-get update -y \
    ;apt-get upgrade -y \
    ;apt-get install -y \ 
        nano \
        gosu \
        make \
        bash \
        inetutils-ping \
    # Docker Installation: 
    # Install big software-properties-common dependency
    # + libpython3.5-dev
    # RUN apt-get update \
    #     ;apt-get -y install \
            #libpython3.5-dev \
        # ;apt-get autoremove -y \ 
        # ;apt-get clean -y
    # Install dependencies
    # + apt-transport-https
    # + ca-certificates
    # + curl
    # + gnupg2
    # + software-properties-common
    # RUN apt-get update \
    #     ;apt-get -y install \
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
    RUN set -eu \
        ;curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -  \
        ;apt-key fingerprint 0EBFCD88 \
        ;add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        ;apt-get update \
        ;apt-get install -y \
            docker-ce \
        ;apt-get autoremove -y \
        ;apt-get clean -y \
        ;curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
        ;chmod +x /usr/local/bin/docker-compose \
        ;

    # Install dependencies and clone the repository
    # apt-get is available (mostly debian or ubuntu)
    ENV MISP_dockerized_testbench_PATH="/srv/MISP-dockerized-testbench"
    RUN set -eu \
        ;apt-get update \
        ;apt-get -y install \
            git \
            python3-minimal \
            python3-pip \
            python3-venv \
        # ;apt-get -y autoremove \
        # ;apt-get -y clean \
        ;git clone https://github.com/DCSO/MISP-dockerized-testbench.git $MISP_dockerized_testbench_PATH \
        ;pip3 install --no-cache-dir -r $MISP_dockerized_testbench_PATH/requirements.txt \
    # Install MySQL Tuner
        #;apt-get update \
        ;apt-get -y install \
            wget \
            perl \
            perl-doc \
        # ;apt-get -y autoremove \
        # ;apt-get -y clean \
        ;mkdir -p /srv/scripts/mysqltuner \
        ;cd /srv/scripts/mysqltuner \
        ;wget http://mysqltuner.pl/ -O mysqltuner.pl \
        ;chmod +x mysqltuner.pl \
        ;wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O basic_passwords.txt \
        ;wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O vulnerabilities.csv \
    # Download Sysschema for MariaDB
        #;apt-get update \
        ;apt-get -y install \
            curl \
            unzip \
            mariadb-client \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;mkdir /srv/scripts/DB_improvement \
        ;cd /srv/scripts/DB_improvement \
        ;curl "https://codeload.github.com/good-dba/mariadb-sys/zip/master" > mariadb-sys.zip \
        ;unzip -l mariadb-sys.zip \
        #;cd mariadb-sys-master/ 
        #mysql -u root -p < ./mariadb_sys_install.sql
        ;

COPY files/misp-testbench.py ${MISP_dockerized_testbench_PATH}/

# Setup Workdir
WORKDIR /srv

# COPY scripts
COPY files/scripts/backup_restore.sh /srv/scripts/
COPY files/scripts/test.sh /srv/scripts/
COPY files/scripts/migrate_user_information_from_events.sh /srv/scripts/
COPY files/scripts/test_mysql_performance.sh /srv/scripts/
COPY files/scripts/test_mysql_performance.sql /srv/scripts/
COPY files/.bashrc /root/

# Add Entrypoint
#ENTRYPOINT [ "/entrypoint.sh" ]

# Add Healthcheck Config
HEALTHCHECK NONE

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

# Environment Variable to check Version
# Version + Name
ENV NAME ${NAME} \
    VERSION ${VERSION} \
    RELEASE_DATE ${RELEASE_DATE}
