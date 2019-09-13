ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require "minitest/rails/capybara"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #fixtures :all
  # Add more helper methods to be used by all tests here...

  include FactoryBot::Syntax::Methods

end

class ActionDispatch::IntegrationTest
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.javascript_driver = :chrome

  Capybara.configure do |config|
    config.default_max_wait_time = 10 # seconds
    config.default_driver        = :selenium
  end
end
