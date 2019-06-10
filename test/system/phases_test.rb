require "application_system_test_case"

class PhasesTest < ApplicationSystemTestCase
  setup do
    @phase = phases(:one)
  end

  test "visiting the index" do
    visit phases_url
    assert_selector "h1", text: "Phases"
  end

  test "creating a Phase" do
    visit phases_url
    click_on "New Phase"

    fill_in "Approx end time", with: @phase.approx_end_time
    fill_in "Approx start ime", with: @phase.approx_start_ime
    fill_in "Name", with: @phase.name
    click_on "Create Phase"

    assert_text "Phase was successfully created"
    click_on "Back"
  end

  test "updating a Phase" do
    visit phases_url
    click_on "Edit", match: :first

    fill_in "Approx end time", with: @phase.approx_end_time
    fill_in "Approx start ime", with: @phase.approx_start_ime
    fill_in "Name", with: @phase.name
    click_on "Update Phase"

    assert_text "Phase was successfully updated"
    click_on "Back"
  end

  test "destroying a Phase" do
    visit phases_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Phase was successfully destroyed"
  end
end
