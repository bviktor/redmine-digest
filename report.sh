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

# initial cleanup
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

# generate mail headers and recipients
sh ${ROOT_DIR}/mail.sh --header "${REPORT_DIR}/${ARG1}.rcpt" "Redmine Report ${ARG2}" > ${MAIL_FILE}
RCPT_LIST=`sh ${ROOT_DIR}/mail.sh --rcpt "${REPORT_DIR}/${ARG1}.rcpt"`

# perform the relevant SQL query
sh ${ROOT_DIR}/query.sh "${REPORT_DIR}/${ARG1}.psql" > ${QUERY_FILE}

# convert the query output to an HTML document
sh ${ROOT_DIR}/html.sh ${QUERY_FILE} >> ${MAIL_FILE}

# set up debug
if [ ${DEBUG} -eq 1 ]
LINE_SEP='*******************************************************************************'
then
    CURL_FLAGS='--verbose'
    echo "${LINE_SEP}"
    echo 'DATABASE QUERY OUTPUT:'
    echo "${LINE_SEP}"
    cat ${QUERY_FILE}
    echo "${LINE_SEP}"
    echo 'GENERATED EMAIL BODY:'
    echo "${LINE_SEP}"
    cat ${MAIL_FILE}
    echo "${LINE_SEP}"
    echo 'CURL OUTPUT:'
    echo "${LINE_SEP}"
else
    CURL_FLAGS='--silent'
fi

# send the email
curl ${CURL_FLAGS} --ssl-reqd --mail-from ${SMTP_SENDER} ${RCPT_LIST} --user ${SMTP_USER} --upload-file ${MAIL_FILE} ${SMTP_HOST}

exit 0
