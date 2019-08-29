[![Travis-CI Build
Status](https://travis-ci.org/xronos-ch/xronos.rails.svg?branch=master)](https://travis-ci.org/xronos-ch/xronos.rails)
[![Docker Pulls](https://img.shields.io/docker/pulls/xronos/xronos.rails)](https://hub.docker.com/r/xronos/xronos.rails/)

## Server setup

### Start the system

Create a directory with the following content

```
your_directory
|- db
|- docker-compose.yml
|- docker_env_variables.env
```

**db**: An empty directory that will contain the database.  
**docker-compose.yml**: The `docker-compose.yml` file in this repository.  
**docker_env_variables.env**: A file with environment variables.

```
POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_DB=...
RAILS_MASTER_KEY=...
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

