require "application_system_test_case"

class DendroMeasurementsTest < ApplicationSystemTestCase
  setup do
    @dendro_measurement = dendro_measurements(:one)
  end

  test "visiting the index" do
    visit dendro_measurements_url
    assert_selector "h1", text: "Dendro Measurements"
  end

  test "creating a Dendro measurement" do
    visit dendro_measurements_url
    click_on "New Dendro Measurement"

    fill_in "Age", with: @dendro_measurement.age
    fill_in "Dating quality estimation category", with: @dendro_measurement.dating_quality_estimation_category
    fill_in "End age deviation", with: @dendro_measurement.end_age_deviation
    fill_in "Start age deviation", with: @dendro_measurement.start_age_deviation
    click_on "Create Dendro measurement"

    assert_text "Dendro measurement was successfully created"
    click_on "Back"
  end

  test "updating a Dendro measurement" do
    visit dendro_measurements_url
    click_on "Edit", match: :first

    fill_in "Age", with: @dendro_measurement.age
    fill_in "Dating quality estimation category", with: @dendro_measurement.dating_quality_estimation_category
    fill_in "End age deviation", with: @dendro_measurement.end_age_deviation
    fill_in "Start age deviation", with: @dendro_measurement.start_age_deviation
    click_on "Update Dendro measurement"

    assert_text "Dendro measurement was successfully updated"
    click_on "Back"
  end

  test "destroying a Dendro measurement" do
    visit dendro_measurements_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Dendro measurement was successfully destroyed"
  end
end
