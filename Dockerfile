# base image
FROM ruby:2.6.3
MAINTAINER Martin Hinz <martin.hinz@ufg.uni-kiel.de>

# install javascript runtime
RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# change workdir
WORKDIR /application

# gemfile into container
RUN mkdir -p .
ADD Gemfile .
ADD Gemfile.lock .

# update bundler
RUN gem install bundler:2.0.1

# bundle install
RUN bundle install --system

# copy app into container
ADD . .

# initialize log
RUN mkdir -p ./log
RUN cat /dev/null > ./log/production.log
RUN chmod -R a+w ./log

# Port
EXPOSE 3000

# set environment variables
ENV RAILS_ENV=production

# permission management
RUN chmod +x ./entrypoint.sh
RUN mkdir -p ./tmp
RUN chown -R nobody:nogroup ./tmp

# define entrypoint
ENTRYPOINT ./entrypoint.sh
