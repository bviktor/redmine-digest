# redmine-digest


## What is it?

It generates and sends email digests about Redmine issues that meet the given criteria (SQL query).

<img src="screenshot.png" />

It queries the data to be reported directly from the database, so it doesn't bloat your Redmine installation, doesn't require new gems nor does it depend on APIs. It only depends on the database schema.


## What do I need to use it?

The following command-line tools on **any** OS which has them:

 * sh
 * mkdir
 * rm
 * wc
 * curl
 * psql (for PostgreSQL) or sqlite3 (for SQLite)

It is tested and works flawlessly on Windows 8.1 (with [msysgit](http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git) and [pgAdmin](http://www.pgadmin.org/download/windows.php)) and on Ubuntu 13.10.


## But I use MySQL/SQL Server!

I don't use them thus I can't test them, so patches are welcome. All it would take is just writing and testing one query in `report.sh` and another one in `new_report.sh`.

If it's feasible in your setup, you may also try to [migrate](http://vault-tec.info/post/68670739052/installing-migrating-upgrading-redmine-with-ldap-o) to PostgreSQL.


## How do I use this?

 * Rename `config.sh.example` to `config.sh` and set it up correctly.
 * Run `new_report.sh` to create a new report config, it should be self-explanatory.
 * If needed, open `data/<report_name>` and modify the query (`WHERE` statement) accordingly.
 * Send a report with `./report.sh <report_name> <subject>`. `<report_name>` is the name of the report as in the `data` folder and `<subject>` will be added to the email subject.


## How do I send daily reports automatically?

Add cronjobs, see `crontab.example` for examples.


## Why no release?

Because this is just a bunch of shell scripts. You can safely use the [Git version](https://github.com/bviktor/redmine-digest/archive/master.zip).


## More info?

Check out the scripts, they should be straightforward to admins.


## Alternatives?

https://gist.github.com/takus/4177475
http://www.redmine.org/plugins/digest
https://github.com/drewkeller/redmine_digest
