#!/bin/sh

# Generate mail headers and recipients

RCPT_LIST=''
TO_LIST=''

# parse recipient list
while read line
do
    RCPT=`echo ${line} | grep --invert-match "^#"`
    if [ $? -eq 0 ]
    then
	RCPT_LIST="${RCPT_LIST} --mail-rcpt ${RCPT}"
	TO_LIST="${TO_LIST} ${RCPT},"
    fi
done << EOT
`cat $2`
EOT

# generate either a mail header or a recipient list for curl
case $1 in
    --header)
	# echo -e works inconsistently across platforms, so let's just use multiple echos to preserve indentation
	echo "To: ${TO_LIST}"
	echo "Subject: $3"
	echo "Mime-Version: 1.0;"
	echo "Content-Type: text/html; charset=UTF-8;"
	echo ""
	;;
    --rcpt)
	echo "${RCPT_LIST}"
	;;
    *)
	echo "Invalid argument, use --header or --rcpt."
	exit 1
	;;
esac

exit 0
