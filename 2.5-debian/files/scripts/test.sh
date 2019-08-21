#!/bin/bash
set -eu
[ "${DEBUG-}" = "true" ] && set -xv

# Parameters
[ -n "${1-}" ] && TEST_WAIT=$(echo "$1"|cut -d = -f 2)
[ -n "${2-}" ] && TEST_LOGLEVEL=$(echo "$2"|cut -d = -f 2)
[ -n "${3-}" ] && TEST_LOG2FILE=$(echo "$3"|cut -d = -f 2)

# Variables
# NC='\033[0m' # No Color
# Light_Green='\033[1;32m'  
STARTMSG="[TEST]"
PROXY_IP=$(docker inspect misp-proxy|grep IPAddress| tail -1|cut -d '"' -f 4)
MISP_DOCKERIZED_TESTBENCH_FOLDER="/srv/MISP-dockerized-testbench"
MSG_3="Start Workers ... finished"
MSG_2="Your MISP-dockerized server has been successfully booted."
MSG_1="Your MISP docker has been successfully booted for the first time."
SLEEP_TIMER=10
DEFAULT_RETRY=50

# Functions
echo (){
    command echo "$STARTMSG $*"
}

check_curl() {
    curl -Lk "$1" > /dev/null 2>&1
}

newline() {
    command echo
}

# Environment Variables
MISP_FQDN=${MISP_FQDN:-"$(grep MISP_FQDN /srv/MISP-dockerized/config/config.env |cut -d = -f 2|cut -d \" -f 2)"}
MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}
TEST_LOGLEVEL=${TEST_LOGLEVEL:-"debug"}
TEST_LOG2FILE=${TEST_LOG2FILE:-"True"}
TEST_WAIT=${TEST_WAIT:-"180"}

#
#   MAIN
#



newline && echo "Start Test script ... " && newline
# Wait until all is ready
        # shellcheck disable=SC2086
        for i in $(seq 0 15 $TEST_WAIT)
        do
            k=$((TEST_WAIT - i))
            echo "wait $k seconds..." && sleep 15
        done
    
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
    newline && echo "$(date +%T) -  Wait until misp-server is ready. sleep $SLEEP_TIMER seconds; Retry $RETRY/$DEFAULT_RETRY..." && newline
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
    newline && echo "$(date +%T) -  wait until the test script get the authentication key.  sleep $SLEEP_TIMER seconds; Retry $RETRY/$DEFAULT_RETRY..." && newline
    sleep $SLEEP_TIMER

    # shellcheck disable=SC2004
    RETRY=$(( $RETRY - 1))
    if [ $RETRY -le 0 ]; then
        >&2 echo "... ... Error: Could not connect to MISP server."
        exit 1
    fi
done

# Change to testbench folder
cd  "$MISP_DOCKERIZED_TESTBENCH_FOLDER" || exit 1

# Create report folder
[ -d reports ] || mkdir reports
[ -d logs ] || mkdir logs

# Disable problematic event for CI Pipeline
# if [ "$MISP_FQDN" = "misp.example.com" ];then
# cat << EOF > samples/event_filelist.json
# {
#     "event1":{
#         "active": true,
#         "file_name": "5bf26acf-d95c-4892-a05d-4db5950d210f.json"
#     },
#     "event2":{
#         "active": false,
#         "file_name": "5614b57d-0f58-4c26-ad03-6aac950d210b.json"
#     }
# }       

# EOF
# fi

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
    newline && cat settings.json


# Add MISP_FQDN to robots hosts file for ping etc.
    ! grep -q "$MISP_FQDN" /etc/hosts  && newline && echo "Add $MISP_FQDN to $PROXY_IP in /etc/hosts" && command echo "$PROXY_IP $MISP_FQDN" >> /etc/hosts


# # Test if curl is possible
#     # shellcheck disable=SC2046
#     if check_curl "${MISP_BASEURL}"
#     then
#         echo "Curl to ${MISP_BASEURL} is not succesful. So I try to restart misp-proxy..."
#         docker restart misp-proxy
#         sleep 5
#         if [ "$(check_curl "${MISP_BASEURL}")" -ne 0 ]; then
#             echo "curl to ${MISP_BASEURL} is not succesful. So I exist now."
#             exit 1
#         fi
#     fi


# Test if Ping works for MISP_FQDN and misp-proxy
    newline && echo "Ping $MISP_FQDN:" && ping -w 2 "$MISP_FQDN"
    newline && echo "Ping misp-proxy:" && ping -w 2 misp-proxy

# Run Tests
    # python -m unittest test_module.TestClass
    # python -m unittest test_module.TestClass.test_method
    set +eu
    newline && echo "Start Test: python3 misp-testbench.py " && python3 misp-testbench.py 2> $MISP_DOCKERIZED_TESTBENCH_FOLDER/logs/error.txt
    cat $MISP_DOCKERIZED_TESTBENCH_FOLDER/logs/test_output.log
    newline && newline && newline && newline
