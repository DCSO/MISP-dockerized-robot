#!/bin/sh
set -x

MODE="$1"
([ "$MODE" != "backup" ] && [ "$MODE" != "restore" ] ) && echo "Please specify mode: 'backup' or 'restore'. Exit now." && exit 0

[ -z "$MYSQL_PASSWORD" ] && MYSQL_PASSWORD="SIXFcjcb1UKqHs9rbrE9vqpnzbND"
[ -z "$MYSQL_USER" ] && MYSQL_USER="misp"
[ -z "$MYSQL_HOST" ] && MYSQL_HOST="localhost"
[ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE="misp"

DATE="$(date +%Y-%m-%d_%H)" #-%M)"
TABLES="attribute_tags attributes \
        event_blacklists event_delegations event_graph event_locks event_tags events \
        object_references object_relationships objects \
        org_blacklists \
        organisations \
        shadow_attribute_correlations shadow_attributes \
        template_element_attributes template_element_files template_element_texts template_elements template_tags templates \
    "

if [ "$MODE" = "backup" ];then
    FOLDER="$MYSQL_DATABASE.$DATE"
    [ -d "$FOLDER" ] || mkdir "$FOLDER"
    ARCHIV="$FOLDER.tar.gz"
    for i in $TABLES
    do 
        FILE="$i.sql"
        mysqldump -u "$MYSQL_USER" -p$MYSQL_PASSWORD -h "$MYSQL_HOST" --single-transaction --no-create-db --no-create-info "$MYSQL_DATABASE" "$i" > "$FOLDER/$FILE" && echo "Created File: $FOLDER/$FILE"
    done
    cp "$0" "$FOLDER"
    tar -czvf "$ARCHIV" "$FOLDER" && echo "Created archiv: $ARCHIV"
fi


#
#   Restore
#

TMP="0"
if [ "$MODE" = "restore" ];then
    FILE="$2"
    FOLDER="$(echo "$FILE"|sed -r 's/.{7}$//')"
    echo "Should i now import the following file: $FILE" && read "TMP"
    tar xzvf "$FILE"
        
    for i in $TABLES
    do 
        echo "Show table $i:" && mysql -u "$MYSQL_USER" -p$MYSQL_PASSWORD -h "$MYSQL_HOST" "$MYSQL_DATABASE" -e "select * from $i;"
        echo "Show auto_increment of table $i:" && mysql -u misp -p$MYSQL_PASSWORD misp -e "SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name = \"$i\" AND table_schema = DATABASE( ) ;"
        read "TMP"
        ############# MODIFY Sector
        echo "Set auto_increment of table $i to 1:" && read "TMP" && mysql -u misp -p$MYSQL_PASSWORD misp -e "ALTER TABLE $i AUTO_INCREMENT = 1;"
        
        echo "Truncate $i:" && read "TMP" && mysql -u "$MYSQL_USER" -p$MYSQL_PASSWORD -h "$MYSQL_HOST" "$MYSQL_DATABASE" -e "truncate $i;"
        echo "Import $FOLDER/$i:" && read "TMP" && mysql -u "$MYSQL_USER" -p$MYSQL_PASSWORD -h "$MYSQL_HOST" "$MYSQL_DATABASE" < "$FOLDER/$i.sql" && echo "Imported File: $FOLDER/$i.sql"
    done
fi

echo "Finished."


