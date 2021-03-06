#!/bin/sh

# Send reports about Redmine issues
# ./report.sh <id> <subject>
# id = filename of report under data
# example: ./report.sh issues_closed "YESTERDAY - All Issues Closed"

# subject variables
YESTERDAY=`date --date="yesterday" +%Y-%m-%d`
TODAY=`date +%Y-%m-%d`
LASTMONTH=`date --date="1 month ago" +%Y-%m`
THISMONTH=`date +%Y-%m`

# parse arguments
ARG1=$1
ARG2=`echo $2 | sed "s@YESTERDAY@${YESTERDAY}@" | sed "s@TODAY@${TODAY}@" | sed "s@LASTMONTH@${LASTMONTH}@" | sed "s@THISMONTH@${THISMONTH}@"`

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

# perform the relevant SQL query
sh ${ROOT_DIR}/query.sh "${REPORT_DIR}/${ARG1}.sql" > ${QUERY_FILE}

# don't do any extra work if the query returns nothing
QUERY_LEN=`wc -l < ${QUERY_FILE}`

if [ ${QUERY_LEN} -eq 0 ]
then
    echo 'The SQL query returned no rows, report aborted'
    exit 1
fi

# generate mail headers and recipients
sh ${ROOT_DIR}/mail.sh --header "${REPORT_DIR}/${ARG1}.rcpt" "Redmine Report ${ARG2}" > ${MAIL_FILE}
RCPT_LIST=`sh ${ROOT_DIR}/mail.sh --rcpt "${REPORT_DIR}/${ARG1}.rcpt"`

# convert the query output to an HTML document
sh ${ROOT_DIR}/html.sh "${REPORT_DIR}/${ARG1}.sh" ${QUERY_FILE} >> ${MAIL_FILE}

# set up debug
if [ ${DEBUG} -eq 1 ]
then
    LINE_SEP='*******************************************************************************'
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
