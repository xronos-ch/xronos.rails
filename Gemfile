source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4.1'
# gem 'rails', '~> 5.2.6'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '< 6'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # RSpec for testing
  gem 'rspec-rails', '~> 4.0.1'
  # Generating test data for models
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
#  gem 'minitest-rails-capybara'
  gem 'minitest'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'capybara-selenium'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# irb for bootsnap: rails console
gem 'irb', require: false

# To use controller variables as javascript variables
gem 'gon'

# leaflet
gem 'leaflet-rails'

# jquery for ajax calls
gem 'jquery-rails'

# hotwire javascript
gem 'turbo-rails'
gem 'stimulus-rails'

# user management
gem 'devise', ">= 4.7.1"

# authorizations management
gem 'cancancan'

# menu
gem 'simple-navigation'

# fontawesome symbols
gem 'font-awesome-rails'

# datatables
gem 'jquery-datatables'
gem 'ajax-datatables-rails'

# postgres adapter for the production mode
group :production do
  gem 'pg'
end

# pagination
gem "pagy"

# forms
gem "bootstrap_form", "~> 5.0"
gem "cocoon"

# ISO-based countries
gem "countries"
gem "country_select"

# Geocoding
gem "geocoder"

# autocomplete in forms
gem 'jquery-ui-rails'
gem 'rails-jquery-autocomplete'

# in place editing
gem "best_in_place", git: "https://github.com/mmotherwell/best_in_place"

# rabl for the api
gem 'rabl'

# a session store backed by an Active Record class to avoid cookie overflow with lasso
gem 'activerecord-session_store'

# recaptcha for user registration
gem "recaptcha"

# Oj for json serialisation
gem 'oj'

# yajl for json serialisation in datatables
gem 'yajl-ruby', require: 'yajl'

# Dotenv for Management Environmental Variables
gem 'dotenv-rails', groups: [:development, :test]

# Rubocop for code checking
gem 'rubocop', require: false
gem 'rubocop-rails', require: false

# Paper Trail for versioning
gem 'paper_trail'

# Door Keeper for Oauth2-api
gem 'doorkeeper'

# WebPacker for up-to-date asset serving
gem 'webpacker'

# Eye Candy
gem 'bootstrap', '~> 5.1'

# Getting the blog posts from blog.xronos.ch
gem "feedjira"
gem "httparty"

# Markdown static pages
gem "kramdown"
