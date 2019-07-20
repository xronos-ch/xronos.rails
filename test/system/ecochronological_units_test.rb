require "application_system_test_case"

class EcochronologicalUnitsTest < ApplicationSystemTestCase
  setup do
    @ecochronological_unit = ecochronological_units(:one)
  end

  test "visiting the index" do
    visit ecochronological_units_url
    assert_selector "h1", text: "Ecochronological Units"
  end

  test "creating a Ecochronological unit" do
    visit ecochronological_units_url
    click_on "New Ecochronological Unit"

    fill_in "Approx end time", with: @ecochronological_unit.approx_end_time
    fill_in "Approx start time", with: @ecochronological_unit.approx_start_time
    fill_in "Name", with: @ecochronological_unit.name
    click_on "Create Ecochronological unit"

    assert_text "Ecochronological unit was successfully created"
    click_on "Back"
  end

  test "updating a Ecochronological unit" do
    visit ecochronological_units_url
    click_on "Edit", match: :first

    fill_in "Approx end time", with: @ecochronological_unit.approx_end_time
    fill_in "Approx start time", with: @ecochronological_unit.approx_start_time
    fill_in "Name", with: @ecochronological_unit.name
    click_on "Update Ecochronological unit"

    assert_text "Ecochronological unit was successfully updated"
    click_on "Back"
  end

  test "destroying a Ecochronological unit" do
    visit ecochronological_units_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ecochronological unit was successfully destroyed"
  end
end
