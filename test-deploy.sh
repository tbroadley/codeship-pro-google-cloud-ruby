#!/bin/bash

# Exit immediately if any of the following commands exits with a non-zero
# status. This means that the Codeship build will fail as soon as one of the
# commands below fails.
set -e

# Authenticate with Google Cloud using the credentials stored in your
# application's repository.
codeship_google authenticate

# `codeship_google authenticate` writes the decrypted Google Cloud credentials
# to /keyconfig.json. We specify the GOOGLE_APPLICATION_CREDENTIALS environment
# variable so that the Cloud SQL Proxy can connect to your application's
# production database.
export GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json

# Switch directories to /deploy, which contains your application (including
# app.yaml, the Google App Engine configuration file).
cd /deploy

# Running `gcloud app deploy` causes your application's static assets to be
# compiled. We test this command here.
bundle exec rake assets:precompile RAILS_ENV=production

# Start the Cloud SQL Proxy, writing logs to a log file.
cloud-sql-proxy -dir /cloudsql > log/cloudsql.log 2>&1 &

# Read the Cloud SQL Proxy log file until a line containing "Ready for new
# connections" is found. Then, continue to the next line.
(tail -f log/cloudsql.log &) | sed '/Ready for new connections/q'

# Try to connect to the production database.
RAILS_ENV=production rake db:version

# Set the DB_ADMIN environment variable to indicate that the command should
# connect to the database using a user that has sufficient privileges to migrate
# the database:
# http://jldbasa.github.io/blog/2014/02/14/mysql-user-minimum-required-privileges-for-rails/
DB_ADMIN=true RAILS_ENV=production rake db:version

# Perform a dry run of the pending migrations against the production database.
DB_ADMIN=true RAILS_ENV=production rake db:migrate --dry-run
