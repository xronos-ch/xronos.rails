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

  # use this driver if you want to see the test happen in front of your eyes
  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new(args: %w[no-sandbox headless disable-gpu disable-dev-shm-usage])
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :headless_chrome

  Capybara.configure do |config|
    config.default_max_wait_time = 10 # seconds
    config.default_driver        = :headless_chrome
  end
end

# in test/test_helper.rb
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