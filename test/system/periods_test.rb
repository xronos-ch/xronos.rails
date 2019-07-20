require "application_system_test_case"

class PeriodsTest < ApplicationSystemTestCase
  setup do
    @period = periods(:one)
  end

  test "visiting the index" do
    visit periods_url
    assert_selector "h1", text: "Periods"
  end

  test "creating a Period" do
    visit periods_url
    click_on "New Period"

    fill_in "Approx end time", with: @period.approx_end_time
    fill_in "Approx start time", with: @period.approx_start_time
    fill_in "Name", with: @period.name
    click_on "Create Period"

    assert_text "Period was successfully created"
    click_on "Back"
  end

  test "updating a Period" do
    visit periods_url
    click_on "Edit", match: :first

    fill_in "Approx end time", with: @period.approx_end_time
    fill_in "Approx start time", with: @period.approx_start_time
    fill_in "Name", with: @period.name
    click_on "Update Period"

    assert_text "Period was successfully updated"
    click_on "Back"
  end

  test "destroying a Period" do
    visit periods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Period was successfully destroyed"
  end
end
