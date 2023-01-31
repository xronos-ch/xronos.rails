# make calibrator
cd vendor/calibrator
make clean
make
rm bin/calibrator_linux
mv bin/calibrator bin/calibrator_linux
cd ../..

# migrate the database
# bundle exec rake db:create db:migrate

# compile the assets
bundle exec rake assets:precompile

# start the server
bundle exec rails server