#!/bin/bash

set -e

# Authenticate with the Google Services
codeship_google authenticate
export GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json

# switch to the directory containing your app.yml (or similar) configuration file
# note that your repository is mounted as a volume to the /deploy directory
cd /deploy/

# test static asset precompilation
RAILS_ENV=production bundle exec rake assets:precompile

# start the Google Cloud SQL proxy
cloud-sql-proxy -dir /cloudsql > log/cloudsql.log 2>&1 &
(tail -f log/cloudsql.log &) | sed '/Ready for new connections/q'

# test the connection to the database
RAILS_ENV=production rake db:version

# test migrating the database
DB_ADMIN=true RAILS_ENV=production rake db:migrate --dry-run
