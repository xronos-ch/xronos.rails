require "application_system_test_case"

class MeasurementsTest < ApplicationSystemTestCase
  setup do
    @measurement = measurements(:one)
  end

  test "visiting the index" do
    visit measurements_url
    assert_selector "h1", text: "Measurements"
  end

  test "creating a Measurement" do
    visit measurements_url
    click_on "New Measurement"

    fill_in "Lab", with: @measurement.lab_id
    fill_in "Labnr", with: @measurement.labnr
    fill_in "Sample", with: @measurement.sample_id
    fill_in "Year", with: @measurement.year
    click_on "Create Measurement"

    assert_text "Measurement was successfully created"
    click_on "Back"
  end

  test "updating a Measurement" do
    visit measurements_url
    click_on "Edit", match: :first

    fill_in "Lab", with: @measurement.lab_id
    fill_in "Labnr", with: @measurement.labnr
    fill_in "Sample", with: @measurement.sample_id
    fill_in "Year", with: @measurement.year
    click_on "Update Measurement"

    assert_text "Measurement was successfully updated"
    click_on "Back"
  end

  test "destroying a Measurement" do
    visit measurements_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Measurement was successfully destroyed"
  end
end
