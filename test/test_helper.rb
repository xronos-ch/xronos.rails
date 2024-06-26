ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
#require "minitest/rails/capybara"
require 'capybara/rails'
require 'capybara/minitest'

class ActionDispatch::IntegrationTest
  
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  # use this driver if you want to see the test happen in front of your eyes
  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.register_driver :headless_chrome do |app|
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: capabilities # change keyword
    )
  end

  Capybara.javascript_driver = :selenium_chrome_headless

  Capybara.configure do |config|
    config.default_max_wait_time = 10 # seconds
    config.default_driver        = :selenium_chrome_headless
  end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #fixtures :all
  # Add more helper methods to be used by all tests here...

  include FactoryBot::Syntax::Methods

  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_request = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.request.enabled = was_enabled_for_request
    end
  end
end
