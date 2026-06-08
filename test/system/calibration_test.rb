# test/system/calibration_test.rb

require "application_system_test_case"

class CalibrationTest < ApplicationSystemTestCase
  test "shows calibration for regular date" do
    c14 = create(:c14)

    visit c14_path(c14)

    assert_selector "div.vega-embed"
  end

  test "does not show calibration for date with bp too low" do
    c14 = create(:c14, bp: 170, std: 170)

    visit c14_path(c14)

    assert_text "Can not be calculated"
  end

  test "shows calibration for date with bp too high" do
    c14 = create(:c14, bp: 100_000, std: 1_000)

    visit c14_path(c14)

    assert_selector "div.vega-embed"
  end
end