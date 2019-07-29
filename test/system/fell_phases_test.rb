require "application_system_test_case"

class FellPhasesTest < ApplicationSystemTestCase
  setup do
    @fell_phase = fell_phases(:one)
  end

  test "visiting the index" do
    visit fell_phases_url
    assert_selector "h1", text: "Fell Phases"
  end

  test "creating a Fell phase" do
    visit fell_phases_url
    click_on "New Fell Phase"

    fill_in "End time", with: @fell_phase.end_time
    fill_in "Name", with: @fell_phase.name
    fill_in "Site", with: @fell_phase.site_id
    fill_in "Start time", with: @fell_phase.start_time
    click_on "Create Fell phase"

    assert_text "Fell phase was successfully created"
    click_on "Back"
  end

  test "updating a Fell phase" do
    visit fell_phases_url
    click_on "Edit", match: :first

    fill_in "End time", with: @fell_phase.end_time
    fill_in "Name", with: @fell_phase.name
    fill_in "Site", with: @fell_phase.site_id
    fill_in "Start time", with: @fell_phase.start_time
    click_on "Update Fell phase"

    assert_text "Fell phase was successfully updated"
    click_on "Back"
  end

  test "destroying a Fell phase" do
    visit fell_phases_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Fell phase was successfully destroyed"
  end
end
