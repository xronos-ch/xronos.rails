# This file should contain all the record creation needed to seed the database with its default values.
require 'factory_bot'

# Load all files in db/seeds/
Dir[Rails.root.join("db/seeds/**/*.rb")].sort.each { |f| require f }

FactoryBot.create_list(:c14, 100)
