#!/bin/bash
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[TEST]${NC}"
PROXY_IP=$(docker inspect misp-proxy|grep IPAddress| tail -1|cut -d '"' -f 4)
# Functions
echo (){
    command echo "$STARTMSG $*"
}

# Environment Variables
GIT_FOLDER=${GIT_FOLDER:-"/srv/MISP-dockerized-testbench"}
MISP_FQDN=${MISP_FQDN:-"$(grep MISP_FQDN /srv/MISP-dockerized/config/config.env |cut -d = -f 2)"}
MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}


#
#   MAIN
#

cd  "$GIT_FOLDER" || exit 1

# generate report folder
[ -d reports ] || mkdir reports


# wait until misp-server is ready
MSG_3="####################################  started Apache2"
MSG_2="Your MISP-dockerized server has been successfully booted."
MSG_1="Your MISP docker has been successfully booted for the first time."
SLEEP_TIMER=5
while true
do
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_3")" ] || break
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_2")" ] || break
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_1")" ] || break
    #wait x seconds
    echo "$(date +%T) -  wait until misp-server is ready. sleep $SLEEP_TIMER seconds..."
    docker logs --tail 10 misp-server
    sleep "$SLEEP_TIMER"
    SLEEP_TIMER="$(expr $SLEEP_TIMER + 5)"
done

# Init MISP and create user

while true
do
    # copy auth_key
    AUTH_KEY="$(docker exec misp-server bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1')"
    
    # initial user if all is good auth_key is return
    [ -z "$AUTH_KEY"  ] && AUTH_KEY="$(docker exec misp-server bash -c "sudo -E /var/www/MISP/app/Console/cake userInit -q")" && echo "new Auth_Key: $AUTH_KEY"
    
    # if user is initalized but mysql is not ready continue
    [ "$AUTH_KEY" = "Script aborted: MISP instance already initialised." ] && continue
    
    # if the auth_key is save go out 
    [ -z "$AUTH_KEY" ] || break

    # wait 5 seconds
    echo "$(date +%T) -  wait until the test script get the authentication key." && sleep 5
done


# generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "${MISP_BASEURL}",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!",
    "loglevel": "info",
    "log2file": "True"
}

EOF
# Show settings...
cat settings.json


# Add MISP_FQDN to robots hosts file for ping etc.
    ! grep -q "$PROXY_IP" /etc/hosts  && echo "Add $MISP_FQDN to $PROXY_IP in /etc/hosts" && command echo "$PROXY_IP $MISP_FQDN" >> /etc/hosts
# Ping
    echo "Ping $MISP_FQDN:" && ping -w 2 "$MISP_FQDN"
    echo
    echo "Ping misp-proxy:" && ping -w 2 misp-proxy

# Run Tests
echo "Start Test: python3 misp-testbench.py " && python3 misp-testbench.py 

exit 0