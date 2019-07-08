# migrate the database
bundle exec rake db:create db:migrate

# compile the assets
bundle exec rake assets:precompile

# start the server
bundle exec rails server