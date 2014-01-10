#!/bin/sh

# Generates the required files for a new report

# dir locations
ROOT_DIR=`dirname $0`
REPORT_DIR="${ROOT_DIR}/data"

# source the config file
. ${ROOT_DIR}/config.sh

ID_QUERY='SELECT id, name FROM projects ORDER BY id'

# create directory for reports if needed
mkdir -p ${REPORT_DIR}

read -p "Report name? " REPORT_NAME

# make sure we don't overwrite something accidentally
if [ -e ${REPORT_DIR}/${REPORT_NAME}.rcpt ] || [ -e ${REPORT_DIR}/${REPORT_NAME}.psql ]
then
    while true
    do
	read -p 'This report already exists! Should I overwrite it? [y/n]' YN
	case ${YN} in
	    [Yy]*)
		break
		;;
	    [Nn]*)
		exit 1
		;;
	    *)
		echo "Please answer yes or no."
		;;
	esac
    done
fi

read -p "Report type (1 = in progress, 2 = resolved, 3 = closed, 4 = custom)? " REPORT_TYPE

if [ ${REPORT_TYPE} -ne 4 ]
then
    while true
    do
	read -p "Project ID (type ? for a list)? " PROJECT_ID
        case ${PROJECT_ID} in
	    '?')
		case ${DB_TYPE} in
		    postgresql)
			PGPASSWORD=${DB_PASS} psql --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} --username=${DB_USER} \
			--tuples-only --no-align --field-separator=' ' --command "${ID_QUERY}"
			;;
		    sqlite)
			sqlite3 -separator ' ' ${DB_FILE} "${ID_QUERY}"
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
		;;
	    *)
		break
		;;
	esac
    done
fi

# recipient file
echo \
"# comment out lines with a leading #, don't add empty lines
${DEFAULT_RCPT}
# end" \
> ${REPORT_DIR}/${REPORT_NAME}.rcpt

# query file
echo \
"SELECT projects.name, issues.id, issues.subject, issues.parent_id, parent_issues.subject, users.firstname, users.lastname
FROM issues
JOIN users ON (issues.assigned_to_id = users.id)
JOIN projects ON (issues.project_id = projects.id)
LEFT JOIN issues parent_issues ON (issues.parent_id = parent_issues.id)" \
> ${REPORT_DIR}/${REPORT_NAME}.psql

case $REPORT_TYPE in
    1)
	echo \
	"WHERE issues.status_id = 2 AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.psql
	;;
    2)
	echo \
	"WHERE issues.status_id = 3 AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.psql
	;;
    3)
	echo \
	"WHERE date_trunc('day', issues.closed_on) = current_date - 1 AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.psql
	;;
    4)
	echo \
	"WHERE *** INSERT YOUR CONDITIONS HERE ***" \
	>> ${REPORT_DIR}/${REPORT_NAME}.psql
	;;
esac

echo \
"ORDER BY projects.name, users.login, issues.subject" \
>> ${REPORT_DIR}/${REPORT_NAME}.psql

exit 0
