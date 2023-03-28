source 'https://rubygems.org'
git_source(:github) { |repo| 'https://github.com/#{repo}.git' }


# CORE ------------------------------------------------------------------------

# Ruby on Rails
ruby '3.0.4'
gem 'rails', '~> 7.0.0'

# Database for Active Record
gem 'pg'

# App server
gem 'puma'

# In-memory cache (also required for Turbo broadcasts and ActionCable)
gem 'redis', '~> 4.0'

# Reduce boot times through caching (required in config/boot.rb)
# gem 'bootsnap', '>= 1.1.0', require: false

# Compress responses to speed up page loads
gem "rack-brotli"

# Write cron jobs
gem "whenever", require: false

# ASSET PIPELINE --------------------------------------------------------------

gem 'propshaft', '>= 0.6.2'

# JavaScript bundling
gem 'jsbundling-rails'

# CSS bundling
gem 'cssbundling-rails'

# Compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'


# APIs ------------------------------------------------------------------------

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Fast JSON serialisation
gem 'oj'

# XML sitemap
gem 'sitemap_generator'

# FRONTEND FRAMEWORKS ---------------------------------------------------------

# Bootstrap forms
gem 'bootstrap_form', '~> 5.0'

# FontAwesome 4.7 icons
#gem 'font-awesome-rails'

# Hotwire JS framework
gem 'turbo-rails'
gem 'stimulus-rails'


# USERS & PERMISSIONS ---------------------------------------------------------

# User management
gem 'devise', '>= 4.7.1'

# Authorizations management
gem 'cancancan'

# Oauth2 API
gem 'doorkeeper'

# MODEL HELPERS ---------------------------------------------------------------

# Versioning
gem 'paper_trail'

# Search
gem 'pg_search'

# File uploads
gem 'carrierwave', '~> 2.0'

# Validation
gem 'validate_url'

# ISO codes
gem 'countries'
gem 'country_select'
gem 'i18n_data'

# Bibliographic data
gem 'bibtex-ruby'
gem 'citeproc-ruby'
gem 'csl-styles'

# Session store backed by an Active Record class to avoid cookie overflow with 
# lasso
gem 'activerecord-session_store'

# EXTERNAL APIS ---------------------------------------------------------------

gem 'faraday', '>= 2.5.2'

# Geocoding
gem 'geocoder'

# GBIF (Backbone Taxonomy)
gem 'gbifrb'

# Wikidata & Wikipedia
gem 'wikidata-client', require: 'wikidata'
gem 'wikipedia-client', require: 'wikipedia'

# VIEW HELPERS ----------------------------------------------------------------

# Pagination
gem 'pagy'

# Use Postgres COPY for efficient CSV exports
gem "postgres-copy"

# Breadcrumbs
gem 'breadcrumbs'

# Markdown rendering
gem 'kramdown'

# Maps
gem 'leaflet-rails'

# Charts
gem 'vega'

# Get posts from blog.xronos.ch
gem 'feedjira'
gem 'httparty'

# DATABASE --------------------------------------------------------------------

gem 'scenic' 

# DEVELOPMENT -----------------------------------------------------------------

# Syntax checking/linting
gem 'rubocop', require: false
gem 'rubocop-rails', require: false

# Progress bar (for rake tasks etc.)
gem 'ruby-progressbar'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger 
  # console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # Load environment variables
  gem 'dotenv-rails'
end

group :development do

  # Watch for file changes
  gem 'listen'

  # Access an interactive console on exception pages or by calling 'console' 
  # anywhere in the code.
  gem 'web-console', '>= 3.3.0'

  # Spring speeds up development by keeping your application running in the 
  # background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

  # Annotate models etc. with current schema
  gem 'annotate'

  # Watch for N+1 queries and unused eager loading
  gem 'bullet'

end


# TESTING ---------------------------------------------------------------------

group :development, :test do

  # RSpec for testing
  gem 'rspec-rails', '~> 4.0.1'

  # Generate test data from model specs
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'guard-rspec'

end

group :test do

  # Unit testing
  gem 'minitest'

  # Schema testing
  gem 'json-schema'

  # Acceptance testing
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'capybara-selenium'
  gem 'launchy'

  # Measure test coverage
  gem 'simplecov', require: false
  gem 'simplecov-cobertura'

end


# COMPATIBILITY ---------------------------------------------------------------

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

