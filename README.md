# codeship-pro-google-cloud-rails

A Docker image and deployment script for deploying a Rails application that uses Google Cloud SQL to Google App Engine using Codeship Pro.

## What this repository includes

- A [Dockerfile](./Dockerfile), which builds a Docker image containing:
  - Ruby
  - Bundler
  - All the gems specified in your application's `Gemfile`
  - The Google Cloud command-line tool `gcloud`
  - The [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy)
- [deploy.sh](./deploy.sh), which:
  - Authenticates with Google Cloud
  - Deploys your application to Google App Engine
  - Starts the Cloud SQL Proxy to connect to your application's production database
  - Runs `rake db:migrate` against the production database
- [test-deploy.sh](./deploy.sh), which:
  - Authenticates with Google Cloud
  - Tests static asset compilation
  - Starts the Cloud SQL Proxy to connect to your application's production database
  - Runs `rake db:version` to test the connection to the production database
  - Runs `rake db:migrate --dry-run` to test pending database migrations

## How to use this repository

Add [deploy.sh](./deploy.sh) and [test-deploy.sh](./deploy.sh) to a directory of your choosing within your Rails project, e.g. `bin`.

Add the [Dockerfile](./Dockerfile) to a directory of your choosing with your Rails project, e.g. `docker/deploy`. Unfortunately, if you place this file in the root of your project, Google App Engine will interpret it as a custom image for running your application.

Encrypt your Google Cloud credentials [as described by Codeship](https://documentation.codeship.com/pro/continuous-deployment/google-cloud/#authentication) and add the resulting file to your project.

If you haven't done so already, create a file called `codeship-services.yml` in the root folder of your project. Add the following to this file:

```yaml
# Create a Codeship service called deploy. This is the environment in which
# your application's deployment step will run.
deploy:

  # Build a Docker image
  build:

    # The path to the Dockerfile that you added to your project earlier.
    # TODO: update this path.
    dockerfile: path/to/Dockerfile

  # Replace path/to/encrypted/credentials with the relative path of the
  # encrypted Google Cloud credentials file you created earlier.
  # TODO: update this path.
  encrypted_env_file: path/to/encrypted/credentials

  # Mount the current directory (i.e. your Rails project) at /deploy within the
  # Docker container from which your application will be deployed
  volumes: ./:/deploy

  # Cache the Docker images generated by Codeship to speed up future deploys.
  cached: true
```

If you haven't done so already, create a file called `codeship-steps.yml` in the root folder of your project. Add the following to this file:

```yaml
# Create a Codeship step that deploys your application.
- name: deploy

  # Run this step within the deploy environment you just specified in
  # codeship-services.yml.
  service: deploy

  # Only run this step on builds for the master branch.
  tag: master

  # Run the deploy script that you added to your project earlier.
  # TODO: update this path.
  command: /deploy/path/to/deploy.sh

- name: test-deploy
  service: deploy

  # Run this step on builds for all branches except for master.
  exclude: master

  # Run the test deploy script that you added to your project earlier.
  # TODO: update this path.
  command: /deploy/path/to/test-deploy.sh
```

Merge these changes into the `master` branch of your application's shared Git repository. Sit back and watch as Codeship deploys your application to Google App Engine and migrates your Google Cloud SQL database!