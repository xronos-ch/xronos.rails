# test/application_system_test_case.rb

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def assert_no_browser_errors
    logs = page.driver.browser.logs.get(:browser)
    severe = logs.select { |log| log.level == "SEVERE" && log.message.exclude?("favicon") }
    assert_equal 0, severe.size, "Browser console errors:\n#{severe.map(&:message).join("\n")}"
  end
end