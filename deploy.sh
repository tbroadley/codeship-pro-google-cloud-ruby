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

# Deploy the application to Google App Engine. The --quiet option is passed to
# prevent `gcloud` from prompting for input during the execution of the
# command.
gcloud app deploy --quiet

# Start the Cloud SQL Proxy, writing logs to a log file.
cloud-sql-proxy -dir /cloudsql > log/cloudsql.log 2>&1 &

# Set cloud_sql_proxy_pid to the PID of the last command, i.e. running
# cloud-sql-proxy.
cloud_sql_proxy_pid=$!

# Time out after 10 seconds.
for (( i = 0; i < 10; i++ )); do

  # If the Cloud SQL Proxy log file contains 'Ready for new connections', the
  # Cloud SQL Proxy is ready to access the production database.
  if cat log/cloudsql.log | grep -q 'Ready for new connections'; then

    echo "Ready to connect to the production database."

    # Migrate the production database. Set the DB_ADMIN environment variable to
    # indicate that the command should connect to the database using a user that
    # has sufficient privileges to migrate the database:
    # http://jldbasa.github.io/blog/2014/02/14/mysql-user-minimum-required-privileges-for-rails/
    DB_ADMIN=true RAILS_ENV=production rake db:migrate

    exit 0

  fi

  sleep 1

done

echo "Cloud SQL Proxy didn't connect to the production database within 10 seconds. Timing out..."

# If the Cloud SQL Proxy exited, indicate that there is an error.
exit 1
