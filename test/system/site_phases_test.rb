require "application_system_test_case"

class SitePhasesTest < ApplicationSystemTestCase
  setup do
    @site_phase = site_phases(:one)
  end

  test "visiting the index" do
    visit site_phases_url
    assert_selector "h1", text: "Site Phases"
  end

  test "creating a Site phase" do
    visit site_phases_url
    click_on "New Site Phase"

    fill_in "Approx end time", with: @site_phase.approx_end_time
    fill_in "Approx start time", with: @site_phase.approx_start_time
    fill_in "Name", with: @site_phase.name
    click_on "Create Site phase"

    assert_text "Site phase was successfully created"
    click_on "Back"
  end

  test "updating a Site phase" do
    visit site_phases_url
    click_on "Edit", match: :first

    fill_in "Approx end time", with: @site_phase.approx_end_time
    fill_in "Approx start time", with: @site_phase.approx_start_time
    fill_in "Name", with: @site_phase.name
    click_on "Update Site phase"

    assert_text "Site phase was successfully updated"
    click_on "Back"
  end

  test "destroying a Site phase" do
    visit site_phases_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Site phase was successfully destroyed"
  end
end
