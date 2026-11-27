# test/application_system_test_case.rb

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def after_teardown
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => error
    # Chrome 158 rejects the wildcard origin used by Capybara 3.40's reset.
    raise unless error.message.include?("* is not a valid URL")

    begin
      page.raise_server_error!
    ensure
      page.quit
    end
  end

  def assert_no_browser_errors
    logs = page.driver.browser.logs.get(:browser)
    severe = logs.select { |log| log.level == "SEVERE" && log.message.exclude?("favicon") }
    assert_equal 0, severe.size, "Browser console errors:\n#{severe.map(&:message).join("\n")}"
  end
end
