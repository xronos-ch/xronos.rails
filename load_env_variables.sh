#!/bin/bash

eval $(cat env_variables.env | sed 's/^/export /')
