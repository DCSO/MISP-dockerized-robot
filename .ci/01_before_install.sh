#!/bin/sh
START="[before_install]"
#########################
#   FOR Local Testing
#########################
#
#       Please do the following for the local dev tests:
#       export VERSION=1.0.0 or any other version you want to test
#       'docker login' with your credentials
#
#

# Install Requirements
echo
echo "$START Install requirements..."
    [ ! -z $(which apk) ] && apk add --no-cache make bash sudo git curl coreutils grep python3
    [ ! -z $(which apt-get) ] && apt-get update; 
    [ ! -z $(which apt-get) ] && apt-get install make bash sudo git curl coreutils grep python3
    # Upgrade Docke
    [ ! -z $(which apt-get) ] && apt-get install --only-upgrade docker-ce -y
# Install docker-compose
    # https://stackoverflow.com/questions/42295457/using-docker-compose-in-a-gitlab-ci-pipeline
    [ -z $(which docker-compose) ] && pip3 install --no-cache-dir docker-compose
# Show version of docker-compose:
    docker-compose -v



# Set Git Options
echo
echo "$START Set Git options..."
git config --global user.name "MISP-dockerized-bot"


# # Updating Docker configuration
# echo
# echo "$START Updating Docker configuration..."
# echo '{
#   "experimental": true,
#   "storage-driver": "overlay2",
#   "max-concurrent-downloads": 50,
#   "max-concurrent-uploads": 50
# }' | sudo tee /etc/docker/daemon.json
#   sudo service docker restart


# Set new Gitlab Repository
    echo
    echo "$START Docker login..."
    [ ! -z "$CUSTOM_REGISTRY_URL" -a ! -z "$CUSTOM_REGISTRY_USER" -a ! -z "$CUSTOM_REGISTRY_PW" ] && echo "$CUSTOM_REGISTRY_PW" | docker login -u "$CUSTOM_REGISTRY_USER" "$CUSTOM_REGISTRY_URL" --password-stdin;
    
echo "$START before_install is finished."