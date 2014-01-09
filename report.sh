#!/bin/sh

# Send reports about Redmine issues
# ./report.sh <id> <subject>
# id = filename of report under data
# example: ./report.sh issues_closed "YESTERDAY - All Issues Closed"

# subject variables
YESTERDAY=`date --date="yesterday" +%Y-%m-%d`
TODAY=`date +%Y-%m-%d`

# parse arguments
ARG1=$1
ARG2=`echo $2 | sed "s@YESTERDAY@${YESTERDAY}@" | sed "s@TODAY@${TODAY}@"`

# dir locations
ROOT_DIR=`dirname $0`
TEMP_DIR="${ROOT_DIR}/tmp/${ARG1}"
REPORT_DIR="${ROOT_DIR}/data"

# file locations
MAIL_FILE="${TEMP_DIR}/mail.txt"
QUERY_FILE="${TEMP_DIR}/query.txt"

# source the config file
. ${ROOT_DIR}/config.sh

# set up debug
if [ ${DEBUG} -eq 1 ]
then
    CURL_FLAGS='--verbose'
else
    CURL_FLAGS='--silent'
fi

# initial cleanup
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# generate mail headers and recipients
sh ${ROOT_DIR}/mail.sh --header "${REPORT_DIR}/${ARG1}.rcpt" "Redmine Report ${ARG2}" > ${MAIL_FILE}
RCPT_LIST=`sh ${ROOT_DIR}/mail.sh --rcpt "${REPORT_DIR}/${ARG1}.rcpt"`

# perform the relevant SQL query
case ${DB_TYPE} in
    postgresql)
	PGPASSWORD=${DB_PASS} psql --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} --username=${DB_USER} --tuples-only --no-align --command "`cat ${REPORT_DIR}/${ARG1}.psql`" > ${QUERY_FILE}
	;;
    *)
	echo 'Unsupported database type.'
	exit 1
	;;
esac

# convert the query output to an HTML document
sh ${ROOT_DIR}/html.sh ${QUERY_FILE} >> ${MAIL_FILE}

# send the email
curl ${CURL_FLAGS} --ssl-reqd --mail-from ${SMTP_SENDER} ${RCPT_LIST} --user ${SMTP_USER} --upload-file ${MAIL_FILE} ${SMTP_HOST}

exit 0
