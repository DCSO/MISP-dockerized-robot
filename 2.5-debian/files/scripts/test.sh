#!/bin/bash
set -eu

# Parameters
[ -n "${1-}" ] && TEST_LOGLEVEL=$(echo "$1"|cut -d = -f 2)
[ -n "${2-}" ] && TEST_LOG2FILE=$(echo "$2"|cut -d = -f 2)

# Variables
# NC='\033[0m' # No Color
# Light_Green='\033[1;32m'  
STARTMSG="[TEST]"
PROXY_IP=$(docker inspect misp-proxy|grep IPAddress| tail -1|cut -d '"' -f 4)
MISP_DOCKERIZED_TESTBENCH_FOLDER="/srv/MISP-dockerized-testbench"
MSG_3="Start Workers ... finished"
MSG_2="Your MISP-dockerized server has been successfully booted."
MSG_1="Your MISP docker has been successfully booted for the first time."
SLEEP_TIMER=5
DEFAULT_RETRY=100


# Functions
echo (){
    command echo "$STARTMSG $*"
}

# Environment Variables
MISP_FQDN=${MISP_FQDN:-"$(grep MISP_FQDN /srv/MISP-dockerized/config/config.env |cut -d = -f 2|cut -d \" -f 2)"}
MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}
TEST_LOGLEVEL=${TEST_LOGLEVEL:-"debug"}
TEST_LOG2FILE=${TEST_LOG2FILE:-"True"}



#
#   MAIN
#

command echo && echo "Start Test script ... " && command echo
# Wait until all is ready
    [ "${CI-}" = "true" ] && echo "wait 50 seconds..." && sleep 10
    [ "${CI-}" = "true" ] && echo "wait 40 seconds..." && sleep 10
    [ "${CI-}" = "true" ] && echo "wait 30 seconds..." && sleep 10
    [ "${CI-}" = "true" ] && echo "wait 20 seconds..." && sleep 10
    [ "${CI-}" = "true" ] && echo "wait 10 seconds..." && sleep 10

# Wait until misp-server is ready
RETRY=$DEFAULT_RETRY
until [ $RETRY -le 0 ]
do
    # shellcheck disable=SC2143
    [ -n "$(docker logs misp-server 2>&1 | grep "$MSG_3")" ] && break
    # shellcheck disable=SC2143
    [ -n "$(docker logs misp-server 2>&1 | grep "$MSG_2")" ] && break
    # shellcheck disable=SC2143
    [ -n "$(docker logs misp-server 2>&1 | grep "$MSG_1")" ] && break
    command echo && echo "$(date +%T) -  Wait until misp-server is ready. sleep $SLEEP_TIMER seconds; Retry $RETRY/100..." && command echo
    docker logs --tail 10 misp-server
    sleep "$SLEEP_TIMER"
    SLEEP_TIMER="$(( SLEEP_TIMER + 5))"
    
    # shellcheck disable=SC2004
    RETRY=$(( $RETRY - 1))
    if [ $RETRY -le 0 ]; then
        >&2 echo "... ... Error: Could not connect to MISP server."
        exit 1
    fi
done

# Init MISP and create user
RETRY=$DEFAULT_RETRY
until [ $RETRY -le 0 ]
do
    # copy auth_key
    AUTH_KEY="$(docker exec misp-server bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1')"
    # initial user if all is good auth_key is return
    [ -z "$AUTH_KEY"  ] && AUTH_KEY="$(docker exec misp-server bash -c "gosu www-data /var/www/MISP/app/Console/cake userInit -q")"
    # if user is initalized but mysql is not ready continue
    [ "$AUTH_KEY" = "Script aborted: MISP instance already initialised." ] && continue
    # if the auth_key is save go out 
    [ -n "$AUTH_KEY" ] && break
    # wait 5 seconds
    command echo && echo "$(date +%T) -  wait until the test script get the authentication key." && command echo
    sleep $SLEEP_TIMER

    # shellcheck disable=SC2004
    RETRY=$(( $RETRY - 1))
    if [ $RETRY -le 0 ]; then
        >&2 echo "... ... Error: Could not connect to MISP server."
        exit 1
    fi
done

set -xv
# Change to testbench folder
cd  "$MISP_DOCKERIZED_TESTBENCH_FOLDER" || exit 1

# Create report folder
[ -d reports ] || mkdir reports
[ -d logs ] || mkdir logs
set +xv
# Generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "${MISP_BASEURL}",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!",
    "loglevel": "${TEST_LOGLEVEL}",
    "log2file": "${TEST_LOG2FILE}"
}

EOF
# Show settings...
    command echo && cat settings.json

# Add MISP_FQDN to robots hosts file for ping etc.
    ! grep -q "$MISP_FQDN" /etc/hosts  && command echo && echo "Add $MISP_FQDN to $PROXY_IP in /etc/hosts" && command echo "$PROXY_IP $MISP_FQDN" >> /etc/hosts
# Test if Ping works for MISP_FQDN and misp-proxy
    command echo && echo "Ping $MISP_FQDN:" && ping -w 2 "$MISP_FQDN"
    command echo && echo "Ping misp-proxy:" && ping -w 2 misp-proxy

# Run Tests
    command echo && echo "Start Test: python3 misp-testbench.py " && python3 misp-testbench.py 
    command echo && command echo && command echo && command echo
