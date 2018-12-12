#!/bin/bash

GIT_FOLDER="/srv/MISP-dockerized-testbench"
#myHOSTNAME=$(cat ../docker-compose.override.yml |grep HOSTNAME |cut -d : -f 2|cut -d " " -f 2|head -1)
myHOSTNAME="$HOSTNAME"
PROXY_IP=$(docker inspect misp-proxy|grep IPAddress| tail -1|cut -d '"' -f 4)

cd  $GIT_FOLDER

# generate report folder
[ -d reports ] || mkdir reports

# Init MISP and create user
while true
do
    # check status of misp-server
    docker logs --tail 10 misp-server
    
    # copy auth_key
    export AUTH_KEY=$(docker exec misp-server bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1')
    
    # initial user if all is good auth_key is return
    [ -z $AUTH_KEY  ] && export AUTH_KEY=$(docker exec misp-server bash -c "sudo -E /var/www/MISP/app/Console/cake userInit -q") && echo "new Auth_Key: $AUTH_KEY"
    
    # if user is initalized but mysql is not ready continue
    [ "$AUTH_KEY" == "Script aborted: MISP instance already initialised." ] && continue
    
    # if the auth_key is save go out 
    [ -z $AUTH_KEY ] || break
    
    # check status of misp-server
    docker logs --tail 10 misp-server
    
    # wait 5 seconds
    sleep 5
done


# generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "https://${myHOSTNAME}",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!"
}

EOF
cat settings.json



echo "Add $myHOSTNAME to $PROXY_IP in /etc/hosts" && sudo echo "$PROXY_IP $myHOSTNAME" >> /etc/hosts
ping -w 2 $myHOSTNAME
pign -w 2 misp-proxy


# Run Tests
echo "python3 misp-testbench.py " && python3 misp-testbench.py 

exit 0