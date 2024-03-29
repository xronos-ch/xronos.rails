# XRONOS web app

![Website](https://img.shields.io/website?url=https%3A%2F%2Fxronos.ch)
![Tests](https://github.com/xronos-ch/xronos.rails/actions/workflows/verify.yml/badge.svg)
[![Test coverage](https://codecov.io/gh/xronos-ch/xronos.rails/branch/master/graph/badge.svg?token=0E7SVSFTVI)](https://codecov.io/gh/xronos-ch/xronos.rails)
[![Docker pulls](https://img.shields.io/docker/pulls/xronos/xronos.rails)](https://hub.docker.com/r/xronos/xronos.rails/)
![GitHub issues](https://img.shields.io/github/issues/xronos-ch/xronos.rails)
![GitHub pull requests](https://img.shields.io/github/issues-pr/xronos-ch/xronos.rails)
![GitHub last commit](https://img.shields.io/github/last-commit/xronos-ch/xronos.rails)

This repository contains the source code for the web application at the core of [XRONOS](https://xronos.ch), an open infrastructure for chronometric data from archaeological contexts worldwide.
It uses [Ruby on Rails](https://rubyonrails.org/), [Hotwire](https://hotwired.dev/) and [Bootstrap 5](https://getbootstrap.com/).

XRONOS is an open source project and contributions to this repository are welcome from anyone.
If you find a bug or have a suggestion to improve XRONOS, please create an [issue](https://github.com/xronos-ch/xronos.rails/issues).

## Server setup

### Start the system

Create a directory with the following content

```
your_directory
|- db
|- docker-compose.yml
|- env_variables.env
```

**db**: An empty directory that will contain the database.  
**docker-compose.yml**: A `docker-compose.yml` file ([example](https://github.com/xronos-ch/xronos.rails/blob/f4049a7eb0ee2a6311a72ef5616e4692aa2cad52/docker-compose.yml))  
**env_variables.env**: A file with environment variables.

```
# Database credentials
POSTGRES_DB=...
POSTGRES_USER=...
POSTGRES_PASSWORD=...
# Passphrase the users must know to register
REGISTRATION_PASSPHRASE=...
```

Inside of this directory you can then run

```
docker-compose up -d
```

For the first start the database migrations have to be run. This has to be done within the container. Change into the container with

```
docker exec -it xronos_rails_app /bin/bash
```

Then inside of the container run

```
rails db:migrate
```

Leave the container with

```
exit
```

### Update the system

```
docker pull xronos/xronos.rails
docker-compose up -d --no-deps --build web
```

### Stop the system

```
docker-compose stop
```

### Stop and delete the system

```
docker-compose down
```

## Development

For development, you will need to run the XRONOS rails app directly (without docker):

1. Clone this repository
2. Ensure ruby, bundler, yarn, and postgresql are installed on your system
    * Using [rbenv](https://github.com/rbenv/rbenv) or a similar solution to manage ruby versions is highly recommended
3. Create a postgresql user for xronos with CREATEDB privileges
4. Create a `.env` file in the root of the repository (see above for a template)
5. Run `bundle && yarn` to install gem and javascript dependencies respectively
6. Run `bin/rails db:setup` to set up and seed the database
7. Start a dev server with `bin/dev`. This watches for changes in CSS and JS files.
    * If you get an error about foreman being missing, try restarting your terminal.

