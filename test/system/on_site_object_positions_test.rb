require "application_system_test_case"

class OnSiteObjectPositionsTest < ApplicationSystemTestCase
  setup do
    @on_site_object_position = on_site_object_positions(:one)
  end

  test "visiting the index" do
    visit on_site_object_positions_url
    assert_selector "h1", text: "On Site Object Positions"
  end

  test "creating a On site object position" do
    visit on_site_object_positions_url
    click_on "New On Site Object Position"

    fill_in "Coord x", with: @on_site_object_position.coord_X
    fill_in "Coord y", with: @on_site_object_position.coord_Y
    fill_in "Coord z", with: @on_site_object_position.coord_Z
    fill_in "Coord reference system", with: @on_site_object_position.coord_reference_system
    fill_in "Feature", with: @on_site_object_position.feature
    fill_in "Site grid square", with: @on_site_object_position.site_grid_square
    click_on "Create On site object position"

    assert_text "On site object position was successfully created"
    click_on "Back"
  end

  test "updating a On site object position" do
    visit on_site_object_positions_url
    click_on "Edit", match: :first

    fill_in "Coord x", with: @on_site_object_position.coord_X
    fill_in "Coord y", with: @on_site_object_position.coord_Y
    fill_in "Coord z", with: @on_site_object_position.coord_Z
    fill_in "Coord reference system", with: @on_site_object_position.coord_reference_system
    fill_in "Feature", with: @on_site_object_position.feature
    fill_in "Site grid square", with: @on_site_object_position.site_grid_square
    click_on "Update On site object position"

    assert_text "On site object position was successfully updated"
    click_on "Back"
  end

  test "destroying a On site object position" do
    visit on_site_object_positions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "On site object position was successfully destroyed"
  end
end
