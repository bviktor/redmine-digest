#!/bin/sh

# Generates the required files for a new report

# dir locations
ROOT_DIR=`dirname $0`
REPORT_DIR="${ROOT_DIR}/data"

# source the config file
. ${ROOT_DIR}/config.sh

# check DB type right away
case ${DB_TYPE} in
    postgresql)
	CLOSEDON_MATCH="date_trunc('day', issues.closed_on) = current_date - 1"
	;;
    sqlite)
	CLOSEDON_MATCH="date(issues.closed_on) = date('now', '-1 days')"
	;;
    mysql|mssql)
	echo 'Unimplemented database type, sorry.'
	exit 1
	;;
    *)
	echo 'Invalid database type, check your config.sh.'
	exit 1
	;;
esac

ID_QUERY='SELECT id, name FROM projects ORDER BY id'

# create directory for reports if needed
mkdir -p ${REPORT_DIR}

read -p "Report name? " REPORT_NAME

# make sure we don't overwrite something accidentally
if [ -e ${REPORT_DIR}/${REPORT_NAME}.rcpt ] || [ -e ${REPORT_DIR}/${REPORT_NAME}.sql ]
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

read -p "Report type (1 = daily in progress, 2 = daily resolved, 3 = daily closed, 4 = daily custom, 5 = monthly closed)? " REPORT_TYPE

if [ ${REPORT_TYPE} -lt 4 ]
then
    while true
    do
	read -p "Project ID (type ? for a list)? " PROJECT_ID
        case ${PROJECT_ID} in
	    '?')
		# other cases are handled in the beginning already
		case ${DB_TYPE} in
		    postgresql)
			PGPASSWORD=${DB_PASS} psql --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} --username=${DB_USER} \
			--tuples-only --no-align --field-separator=' ' --command "${ID_QUERY}"
			;;
		    sqlite)
			sqlite3 -separator ' ' ${DB_FILE} "${ID_QUERY}"
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
if [ ${REPORT_TYPE} -lt 5 ]
then
echo \
'SELECT projects.name, issues.id, issues.subject, issues.parent_id, parent_issues.subject, users.firstname, users.lastname, ROUND(CAST(st.hours_sum AS numeric), 2)
FROM issues
JOIN users ON (issues.assigned_to_id = users.id)
JOIN projects ON (issues.project_id = projects.id)
LEFT JOIN issues parent_issues ON (issues.parent_id = parent_issues.id)
LEFT JOIN (
    SELECT issue_id, SUM(hours) AS hours_sum
    FROM time_entries
    GROUP BY issue_id
    ORDER BY issue_id) st ON issues.id = st.issue_id' \
> ${REPORT_DIR}/${REPORT_NAME}.sql
else
echo \
"SELECT users.id, users.firstname, users.lastname, coalesce(all_issues.i_count, 0)
FROM users
LEFT JOIN (
    SELECT users.id as u_id, COUNT(issues.id) as i_count
    FROM users
    LEFT JOIN issues ON (users.id = issues.assigned_to_id)
    WHERE date_trunc('month', issues.closed_on) = date_trunc('month', current_date - 28)
    GROUP BY users.id) all_issues ON users.id = all_issues.u_id
WHERE users.type = 'User' AND users.status = 1 AND admin = FALSE
ORDER BY users.firstname, users.lastname" \
> ${REPORT_DIR}/${REPORT_NAME}.sql
fi

case $REPORT_TYPE in
    1)
	echo \
	"WHERE issues.status_id = 2 AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.sql
	;;
    2)
	echo \
	"WHERE issues.status_id = 3 AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.sql
	;;
    3)
	echo \
	"WHERE ${CLOSEDON_MATCH} AND (projects.id = ${PROJECT_ID} OR projects.parent_id = ${PROJECT_ID})" \
	>> ${REPORT_DIR}/${REPORT_NAME}.sql
	;;
    4)
	echo \
	"WHERE *** INSERT YOUR CONDITIONS HERE ***" \
	>> ${REPORT_DIR}/${REPORT_NAME}.sql
	;;
    5)
	break
	;;
esac

if [ ${REPORT_TYPE} -lt 5 ]
then
echo \
'ORDER BY projects.name, users.login, issues.subject' \
>> ${REPORT_DIR}/${REPORT_NAME}.sql
fi

# copy HTML generator template
case ${REPORT_TYPE} in
    1|2|3|4)
	cp ./html_daily.tmpl ${REPORT_DIR}/${REPORT_NAME}.sh
	;;
    5)
	cp ./html_monthly.tmpl ${REPORT_DIR}/${REPORT_NAME}.sh
	;;
esac

exit 0
