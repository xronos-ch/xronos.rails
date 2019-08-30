#!/bin/bash

eval $(cat docker_env_variables.env | sed 's/^/export /')
