#!/bin/sh

# Construct an HTML document from the SQL query

# dir locations
ROOT_DIR=`dirname $0`

# source the config file
. ${ROOT_DIR}/config.sh

# separator used in our queries
IFS='|'

# alternating row colors
EVEN=0

# HTML  header
echo \
"<html>
<head>
<style type=\"text/css\">
${EMAIL_CSS}
</style>
</head>
<body>
<table>"

# parse the actual query and generate the custom table body
. $1

# table and HTML footer
echo \
'</table>
</body>
</html>'

exit 0
