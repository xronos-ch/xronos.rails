# make calibrator
cd vendor/calibrator
make clean
make
rm bin/calibrator_linux
mv bin/calibrator bin/calibrator_linux
cd ../..

# update cron jobs
bundle exec whenever --update-crontab

# install/update dependencies
bundle && yarn

# run database migrations
bundle exec rails db:migrate

# precompile assets
bundle exec rails assets:precompile

# start server
bundle exec rails server
