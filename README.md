[![Travis-CI Build
Status](https://travis-ci.com/nevrome/xronos.rails.svg?token=vxsQ9RjxoGASGtX4Q8jc&branch=master)](https://travis-ci.com/nevrome/xronos.rails)

# README

Ideas for the Deployment procedure:

1. Building the app image on dockerhub
2. Running docker compose on the server

The compose yaml has to be changed for this setup: Instead of building the app container, the already build image has to be downloaded. Environment variables in docker_env_variables + master.key have to be available when the entrypoint script runs. 
