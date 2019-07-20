require "application_system_test_case"

class TypochronologicalUnitsTest < ApplicationSystemTestCase
  setup do
    @typochronological_unit = typochronological_units(:one)
  end

  test "visiting the index" do
    visit typochronological_units_url
    assert_selector "h1", text: "Typochronological Units"
  end

  test "creating a Typochronological unit" do
    visit typochronological_units_url
    click_on "New Typochronological Unit"

    fill_in "Approx end time", with: @typochronological_unit.approx_end_time
    fill_in "Approx start time", with: @typochronological_unit.approx_start_time
    fill_in "Name", with: @typochronological_unit.name
    click_on "Create Typochronological unit"

    assert_text "Typochronological unit was successfully created"
    click_on "Back"
  end

  test "updating a Typochronological unit" do
    visit typochronological_units_url
    click_on "Edit", match: :first

    fill_in "Approx end time", with: @typochronological_unit.approx_end_time
    fill_in "Approx start time", with: @typochronological_unit.approx_start_time
    fill_in "Name", with: @typochronological_unit.name
    click_on "Update Typochronological unit"

    assert_text "Typochronological unit was successfully updated"
    click_on "Back"
  end

  test "destroying a Typochronological unit" do
    visit typochronological_units_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Typochronological unit was successfully destroyed"
  end
end
