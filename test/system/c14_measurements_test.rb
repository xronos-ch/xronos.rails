require "application_system_test_case"

class C14MeasurementsTest < ApplicationSystemTestCase
  setup do
    @c14_measurement = c14_measurements(:one)
  end

  test "visiting the index" do
    visit c14_measurements_url
    assert_selector "h1", text: "C14 Measurements"
  end

  test "creating a C14 measurement" do
    visit c14_measurements_url
    click_on "New C14 Measurement"

    fill_in "Bp", with: @c14_measurement.bp
    fill_in "Delta c13", with: @c14_measurement.delta_c13
    fill_in "Delta c13 std", with: @c14_measurement.delta_c13_std
    fill_in "Method", with: @c14_measurement.method
    fill_in "Std", with: @c14_measurement.std
    click_on "Create C14 measurement"

    assert_text "C14 measurement was successfully created"
    click_on "Back"
  end

  test "updating a C14 measurement" do
    visit c14_measurements_url
    click_on "Edit", match: :first

    fill_in "Bp", with: @c14_measurement.bp
    fill_in "Delta c13", with: @c14_measurement.delta_c13
    fill_in "Delta c13 std", with: @c14_measurement.delta_c13_std
    fill_in "Method", with: @c14_measurement.method
    fill_in "Std", with: @c14_measurement.std
    click_on "Update C14 measurement"

    assert_text "C14 measurement was successfully updated"
    click_on "Back"
  end

  test "destroying a C14 measurement" do
    visit c14_measurements_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "C14 measurement was successfully destroyed"
  end
end
