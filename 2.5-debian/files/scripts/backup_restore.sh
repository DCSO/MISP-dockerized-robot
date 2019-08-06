#!/bin/bash
#description     :This script can be used to backup and retore the misp docker environment.
#==============================================================================

if [[ ! ${1} =~ (backup|restore) ]]; then
  echo "First parameter needs to be 'backup' or 'restore'"
  exit 1
fi

BACKUP_TYPE=${1}

if [[ ! ${2} =~ (server|redis|mysql|proxy|config|all) ]]; then
  echo "Second parameter needs to be 'server', 'redis', 'mysql', 'proxy', 'config' or 'all'"
  exit 1
fi

#SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#COMPOSE_FILE=${SCRIPT_DIR}/../docker-compose.yml
# shellcheck disable=SC1091
source /srv/MISP-dockerized/config/config.env


# DB
MYSQL_DATABASE=${DB_DATABASE:-"misp"}
MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
MYSQL_HOST=${DB_HOST:-"misp-server"}
MYSQL_PORT=${DB_PORT:-3306}
MYSQL_CMD="-v -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} --log-error=$LOG_FILE"
# Redis
REDIS_FQDN=${REDIS_FQDN:-"misp-server"}
REDIS_PORT=${REDIS_PORT:-5432}
REDIS_PW=${REDIS_PW:-""}
# MISP
MISP_FQDN=${MISP_FQDN:-""}
MISP_BASEURL=${MISP_BASEURL:-"https://$MISP_FQDN"}


BACKUP_LOCATION="/srv/MISP-dockerized/backup"
DATE=$(date +"%Y-%m-%d-%H-%M-%S")
LOG_FILE="$BACKUP_LOCATION/log_${DATE}_$BACKUP_TYPE"
RESTORE_DB=""

echo () {
  command echo "[$(date +%Y-%M-%d\ %T)] $*" >> "$LOG_FILE" 2>&1
  command echo "[$(date +%Y-%M-%d\ %T)] $*"
}

newline () {
  command echo "" >> "$LOG_FILE" 2>&1
}

tar () {
  command tar -cvpzPf "$1" "$2" >> "$LOG_FILE" 2>&1  & pid=$!
  loading_animation ${pid} "$2"
}

tar_extract () {
  command tar -xvzPf "$*"  >> "$LOG_FILE" 2>&1  & pid=$!
  loading_animation ${pid} "$2"
} 

# LOADING Animation
loading_animation() {
  # How to use: cmd & pid=$! ; loading_animation ${pid} "$2" 
  pid="${1}"

  spin='-\|/'

  i=0
  while kill -0 "$pid" 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    # shellcheck disable=SC2059
    printf "\r${spin:$i:1} ...working $2"
    sleep .1
  done
  command echo ""
}


#
# BACKUP
#

backup() {
  #set -xv
  DOCKER_BACKUPDIR="${BACKUP_LOCATION}/misp-${DATE}"
  mkdir -p "${DOCKER_BACKUPDIR}"
  chmod 755 "${DOCKER_BACKUPDIR}"
  echo "--- Start Backup ---"
  echo "To follow the backup in detail please make 'tail -f <MISP-dockerized>/backup/log_${DATE}_${BACKUP_TYPE}' ... wait 5 seconds ..."
  sleep 5
  while (( "$#" )); do
    case "$1" in
      server|all)
        newline 
        echo "Backup server at ${DOCKER_BACKUPDIR}"
        newline
        tar "${DOCKER_BACKUPDIR}"/backup_server_data.tar.gz /srv/misp-server/MISP
        # tar "${DOCKER_BACKUPDIR}"/backup_server_config.tar.gz /srv/misp-server/apache2  & pid=$!
        # loading_animation ${pid}
        tar "${DOCKER_BACKUPDIR}"/backup_ssl.tar.gz /srv/misp-ssl
        tar "${DOCKER_BACKUPDIR}"/backup_smime.tar.gz /srv/misp-smime
        tar "${DOCKER_BACKUPDIR}"/backup_pgp.tar.gz /srv/misp-pgp
        ;;&
      redis|all)
        newline
        echo "Backup redis at ${DOCKER_BACKUPDIR}"
        newline
        docker exec "$REDIS_FQDN" redis-cli save  >> "$LOG_FILE" 2>&1 & pid=$!
        loading_animation ${pid} "redis-cli save"
        tar "${DOCKER_BACKUPDIR}"/backup_redis.tar.gz /srv/misp-redis
        ;;&      
      proxy|all)
        newline
        echo "Backup proxy at ${DOCKER_BACKUPDIR}"
        newline
        #tar "${DOCKER_BACKUPDIR}"/backup_proxy_data.tar.gz /srv/misp-proxy/conf.d
        tar "${DOCKER_BACKUPDIR}"/backup_ssl.tar.gz /srv/misp-ssl
        ;;&
      mysql|all)
        
        newline
        echo "Backup mysql at ${DOCKER_BACKUPDIR} - This could take a while"
        newline
        # shellcheck disable=SC2086
        mysqldump ${MYSQL_CMD} --add-drop-table --all-databases | gzip > "${DOCKER_BACKUPDIR}/backup_mysql_all.gz" & pid=$! 
        loading_animation ${pid} "mysqldump all-databases"
        # shellcheck disable=SC2086
        mysqldump ${MYSQL_CMD} --add-drop-table "${MYSQL_DATABASE}" | gzip > "${DOCKER_BACKUPDIR}/backup_mysql_$MYSQL_DATABASE.gz" & pid=$!
        loading_animation ${pid} "mysqldump ${MYSQL_DATABASE}"
        ;;&
      config|all)
        newline
        echo "Backup MISP-dockerized config files at ${DOCKER_BACKUPDIR}"
        newline
        tar -cvpzf "${DOCKER_BACKUPDIR}"/backup_MISP-dockerized_config.tar.gz /srv/MISP-dockerized/config
        ;;
    esac
    shift
  done
  echo "--- Done ---"
  set +xv
}





#
#   RESTORE
#

restore() {
  RESTORE_LOCATION="${1}"
  echo "--- Start Restore ---"
  echo "To follow the restore in detail please make 'tail -f <MISP-dockerized>/backup/log_${DATE}_${BACKUP_TYPE}' ... wait 5 seconds ..."
  sleep 5
  # echo "Restore location: ${RESTORE_LOCATION}" # Debug Output
  shift
  while (( "$#" )); do
    case "$1" in    
      config|all)
        echo "Restore MISP-dockerized config files"
        tar_extract "${RESTORE_LOCATION}/backup_MISP-dockerized_config.tar.gz"
        ;;&
      redis|all)
        echo "Restore MISP Redis" #Debug
        tar_extract "${RESTORE_LOCATION}/backup_redis.tar.gz"
        echo "Docker restart $REDIS_FQDN" && docker restart "$REDIS_FQDN"
        ;;&
      server|all)
        echo "Restore MISP Server" #Debug
        tar_extract "${RESTORE_LOCATION}/backup_server_data.tar.gz"
        #tar_extract "${RESTORE_LOCATION}backup_server_config.tar.gz";
        tar_extract "${RESTORE_LOCATION}/backup_ssl.tar.gz";
        tar_extract "${RESTORE_LOCATION}/backup_smime.tar.gz";
        tar_extract "${RESTORE_LOCATION}/backup_pgp.tar.gz";
        [ -f /srv/misp-server/MISP/Config/NOT_CONFIGURED ] && rm /srv/misp-server/MISP/Config/NOT_CONFIGURED
        echo "Docker restart misp-server" && docker restart misp-server
        ;;&
      proxy|all)
        echo "Restore MISP Proxy"
        tar_extract "${RESTORE_LOCATION}/backup_ssl.tar.gz";
        echo "docker restart misp-proxy" && docker restart misp-proxy
        ;;&
      mysql_full|all)
        echo "Restore MISP DB - This could take a while"
        echo "-> restore database"
        # https://stackoverflow.com/questions/23180963/restore-all-mysql-database-from-a-all-database-sql-gz-file#23180977
        gunzip < "${RESTORE_LOCATION}"/backup_mysql_all.gz | mysql "${MYSQL_CMD}" & pid=$!
        loading_animation ${pid}
        ;;
      mysql_single_db)
        echo "Restore MISP DB - This could take a while"
        echo "-> restore database"
        # https://stackoverflow.com/questions/23180963/restore-all-mysql-database-from-a-all-database-sql-gz-file#23180977
        gunzip < "${RESTORE_LOCATION}"/${RESTORE_DB} | mysql "${MYSQL_CMD}" & pid=$!
        loading_animation ${pid}
        ;;
    esac
    shift
    echo "--- Done ---"
  done
}



#
# MAIN
#

if [[ "${BACKUP_TYPE}" = "backup" ]]; then
  # shellcheck disable=SC2068
  backup ${@,,}
elif [[ "${BACKUP_TYPE}" = "restore" ]]; then
  i=1
  declare -A FOLDER_SELECTION
  if [[ $(find ${BACKUP_LOCATION}/misp-* -maxdepth 1 -type d 2> /dev/null | wc -l) -lt 1 ]]; then
    echo "Selected backup location has no subfolders"
    exit 1
  fi
  # shellcheck disable=SC2045
  for folder in $(find ${BACKUP_LOCATION}/misp-* -maxdepth 1 -type d 2> /dev/null); do
    echo "[ ${i} ] - ${folder}"
    FOLDER_SELECTION[${i}]="${folder}"
    ((i++))
  done
  echo
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -rp "Select a restore point: " input_sel
  done
  i=1
  echo
  declare -A FILE_SELECTION
  RESTORE_POINT="${FOLDER_SELECTION[${input_sel}]}"
  
  if [[ -z $(find "$RESTORE_POINT" -maxdepth 1 -type f -regex ".*\(redis\|mysql\|server\|config\).*") ]]; then
    echo "No datasets found"
    exit 1
  fi


  # shellcheck disable=SC2045
  for file in $(ls -f "$RESTORE_POINT"); do
    if [[ ${file} =~ server ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="server"
      ((i++))
    elif [[ ${file} =~ proxy ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="proxy"
      ((i++))
    elif [[ ${file} =~ redis ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="redis"
      ((i++))
    elif [[ ${file} =~ mysql_all ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="mysql_all"
      ((i++))
    elif [[ ${file} =~ mysql ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="mysql_single_db"
      RESTORE_DB=${file}
      ((i++))
    elif [[ ${file} =~ config ]]; then
      echo "[ ${i} ] - $file"
      FILE_SELECTION[${i}]="config"
      ((i++)) 
    else
      echo "[ ${i} ] - $file "
      FILE_SELECTION[${i}]="$file"
      ((i++)) 
    fi   
  done
  echo "[ ${i} ] - All"
  FILE_SELECTION[${i}]="all"
  
  echo
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -rp "Select a dataset to restore: " input_sel
  done
  echo "Restoring ${FILE_SELECTION[${input_sel}]} from ${RESTORE_POINT}..."
  restore "${RESTORE_POINT}" ${FILE_SELECTION[${input_sel}]}

fi
