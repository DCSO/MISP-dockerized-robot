#!/bin/bash
[ -z "$(which mysql)" ] && echo "There is no mysql-client installed. Exit now." && exit 1

MYSQL_DATABASE="$(cat /var/www/MISP/app/Config/database.php |grep \'database\'|cut -d "'" -f 4)"
MYSQL_HOST="$(cat /var/www/MISP/app/Config/database.php |grep \'host\'|cut -d "'" -f 4)"
MYSQL_PASSWORD="$(cat /var/www/MISP/app/Config/database.php |grep \'password\'|cut -d "'" -f 4)"
MYSQL_PORT=3306
MYSQL_USER="$(cat /var/www/MISP/app/Config/database.php |grep \'login\'|cut -d "'" -f 4)"
FILE="update_users_from_old_misp.sql"


# Download Data
DATA=$(echo "select uuid, users.email from events LEFT JOIN users ON events.user_id = users.id;"|mysql -u $MYSQL_USER -h $MYSQL_HOST -P $MYSQL_PORT -p$MYSQL_PASSWORD $MYSQL_DATABASE -r -N| while read; do sed 's/\t/,/g'; done)

# Create empty file
echo "" > $FILE
i=0
for D in $DATA
do
    # Store UUID
    UUID="$(echo "$D"|cut -d "," -f 1 )"
    # Store Email
    EMAIL="$(echo "$D"|cut -d "," -f 2 )"
    # Write SQL
    SQL_STATEMENT="UPDATE events SET user_id = ( SELECT id FROM users WHERE email = '$EMAIL') WHERE uuid = '$UUID';"
    # Save SQL
    echo "$SQL_STATEMENT" >> $FILE
    i=$(($i+1))
    echo "$i/${#DATA} events written..."
done

