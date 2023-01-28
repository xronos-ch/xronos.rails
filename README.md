![Website](https://img.shields.io/website?url=https%3A%2F%2Fxronos.ch)
![Tests](https://github.com/xronos-ch/xronos.rails/actions/workflows/verify.yml/badge.svg)
[![Docker pulls](https://img.shields.io/docker/pulls/xronos/xronos.rails)](https://hub.docker.com/r/xronos/xronos.rails/)
![GitHub issues](https://img.shields.io/github/issues/xronos-ch/xronos.rails)
![GitHub pull requests](https://img.shields.io/github/issues-pr/xronos-ch/xronos.rails)
![GitHub last commit](https://img.shields.io/github/last-commit/xronos-ch/xronos.rails)
[![codecov](https://codecov.io/gh/xronos-ch/xronos.rails/branch/master/graph/badge.svg?token=0E7SVSFTVI)](https://codecov.io/gh/xronos-ch/xronos.rails)

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
**docker-compose.yml**: The `docker-compose.yml` file in this repository.  
**env_variables.env**: A file with environment variables.

```
# Database credentials
POSTGRES_DB=...
POSTGRES_USER=...
POSTGRES_PASSWORD=...
# Rails Master Key (used to decrypt config/credentials.yml.enc)
RAILS_MASTER_KEY=...
# Google Recaptcha tokens
RECAPTCHA_SITE_KEY=...
RECAPTCHA_SECRET_KEY=...
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
