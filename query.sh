#!/bin/sh

# Perform a db query

# dir locations
ROOT_DIR=`dirname $0`

# source the config file
. ${ROOT_DIR}/config.sh

# perform the relevant SQL query
case ${DB_TYPE} in
    postgresql)
	PGPASSWORD=${DB_PASS} psql --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} --username=${DB_USER} --field-separator='|' \
	--tuples-only --no-align --command "`cat $1`"
	;;
    sqlite)
	sqlite3 -separator '|' ${DB_FILE} "`cat $1`"
	;;
    mysql|mssql)
	echo 'Unimplemented database type.'
	exit 1
	;;
    *)
	echo 'Invalid database type.'
	exit 1
	;;
esac

exit 0
