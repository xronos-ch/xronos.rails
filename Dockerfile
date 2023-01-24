# base image
FROM ruby:3.0.4
MAINTAINER Martin Hinz <martin.hinz@iaw.unibe.ch>

# install node and yarn
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y --no-install-recommends build-essential nodejs
RUN corepack enable

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# change workdir
WORKDIR /application

# gemfile into container
RUN mkdir -p .
ADD Gemfile .
ADD Gemfile.lock .

# update bundler
RUN gem install bundler

# bundle install
RUN bundle config set --local system 'true'
RUN bundle install 

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
