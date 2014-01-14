#!/bin/sh

# Construct an HTML document from the postgres query

# dir locations
ROOT_DIR=`dirname $0`

# source the config file
. ${ROOT_DIR}/config.sh

# HTML and table header
echo \
"<html>
<head>
<style type=\"text/css\">
${EMAIL_CSS}
</style>
</head>
<body>
<table>
<tr> <th>Project</th> <th>Issue</th> <th>Assignee</th> <th>Spent time</th> </tr>"

# separator used by psql
IFS='|'

# alternating row colors
EVEN=0

# parse variables and construct table lines
while read -r PROJ I_ID I_SUB P_ID P_SUB A_FIRST A_LAST TIME
do
    if [ ${EVEN} -eq 1 ]
    then
        echo "<tr class=\"even\"> <td>${PROJ}</td>"
	EVEN=0
    else
        echo "<tr> <td>${PROJ}</td>"
	EVEN=1
    fi

    LEN=`echo ${P_ID} | wc -c`
    if [ ${LEN} -ge 2 ]
    then
        echo "<td><small><i><a href=\"${REDMINE_URL}/issues/${P_ID}\">${P_SUB}</a></i></small><br />&gt; <a href=\"${REDMINE_URL}/issues/${I_ID}\">${I_SUB}</a></td> "
    else
        echo "<td><a href=\"${REDMINE_URL}/issues/${I_ID}\">${I_SUB}</a></td>"
    fi

    echo "<td>${A_FIRST} ${A_LAST}</td> <td>${TIME}</td> </tr>"
done << EOT
`cat $1`
EOT

# table and HTML footer
echo \
'</table>
</body>
</html>'

exit 0
