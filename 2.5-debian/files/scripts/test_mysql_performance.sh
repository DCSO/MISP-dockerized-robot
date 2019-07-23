#!/bin/sh
set -eu

# https://dev.mysql.com/doc/refman/5.5/en/optimize-benchmarking.html
# https://www.digitalocean.com/community/tutorials/how-to-measure-mysql-query-performance-with-mysqlslap

# To log new sql commands:
# Log in to MYSQL:
#       Activate Logging with:
#            SET GLOBAL general_log=1, general_log_file='capture_queries.log';
#       After your commands deactivate with: 
#           SET GLOBAL general_log=0;
#       Find File:
#           ls /var/lib/mysql/capture_queries.log
#
#


# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[TEST_MYSQL_PERFORMANCE]${NC}"


# Functions
echo (){
    command echo "$STARTMSG $*"
}

# Environment Parameter
USER=${MYSQL_USER:-"root"}
PW=${MYSQL_PASSWORD:-"NaUgmNJATAYLo4D4meZ77rpWGw76"}
HOST=${MYSQL_HOST:-"misp-db"}
DB=${MYSQL_DATABASE:-"misp"}


#
#   MAIN
#
[ "$USER" = "root" ] && echo "We use the user root for the performance test."
[ -z "$PW" ] && echo "Your MYSQL_PASSWORD environment variable is not set or empty, please type your password manual in:" && read -r PW


echo "Basic Test..."
mysqlslap --no-defaults --user="$USER" --password="$PW" --host="$HOST"  --auto-generate-sql --verbose

CONCURRENCY=50
ITERATIONS=10
echo "Concurrent Connections: $CONCURRENCY | Iterations: $ITERATIONS"
mysqlslap --no-defaults --user="$USER" --password="$PW" --host="$HOST"  --concurrency="$CONCURRENCY" --iterations="$ITERATIONS" --auto-generate-sql --verbose


CONCURRENCY=50
ITERATIONS=10
echo "Concurrent Connections: $CONCURRENCY | Iterations: $ITERATIONS | Added more complexity"
mysqlslap --no-defaults --user="$USER" --password="$PW" --host="$HOST"  --concurrency="$CONCURRENCY" --iterations="$ITERATIONS" --number-int-cols=5 --number-char-cols=20 --auto-generate-sql --verbose


echo "MISP Database Tests..."
CONCURRENCY=50
ITERATIONS=20
echo "Concurrent Connections: $CONCURRENCY | Iterations: $ITERATIONS | Make test on base of MISP database"
mysqlslap --no-defaults --user="$USER" --password="$PW" --host="$HOST"  --concurrency="$CONCURRENCY" --iterations="$ITERATIONS" \
        --number-of-queries=1000 \
        --create-schema="$DB" \
        --query="/scripts/test_mysql_performance.sql" \
        --delimiter=";"  \
        --debug-info \
        --verbose 

