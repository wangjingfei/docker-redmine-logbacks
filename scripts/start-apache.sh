#!/bin/bash
set -e

DB_HOST=${DB_HOST:-"192.168.1.2"}
DB_NAME=${DB_NAME:-"redmine_production"}
DB_USER=${DB_USER:-"redmine"}
DB_PASS=${DB_PASS:-"redmine"}

## Create database configuration file if not exist.
if [ ! -f $REDMINE_HOME/config/database.yml ]; then
  cat >> $REDMINE_HOME/config/database.yml <<EOF
production:
  adapter: mysql2
  database: ${DB_NAME}
  host: ${DB_HOST}
  username: ${DB_USER}
  password: "${DB_PASS}"
  encoding: utf8
EOF

  RAILS_ENV=production bundle exec rake db:migrate
  bundle exec rake generate_secret_token
  bundle exec rake redmine:backlogs:install
fi

## Start the apache server in foreground
source /etc/apache2/envvars 
/usr/sbin/apache2 -DFOREGROUND

