require "application_system_test_case"

class SiteTypesTest < ApplicationSystemTestCase
  setup do
    @site_type = site_types(:one)
  end

  test "visiting the index" do
    visit site_types_url
    assert_selector "h1", text: "Site Types"
  end

  test "creating a Site type" do
    visit site_types_url
    click_on "New Site Type"

    fill_in "Description", with: @site_type.description
    fill_in "Name", with: @site_type.name
    click_on "Create Site type"

    assert_text "Site type was successfully created"
    click_on "Back"
  end

  test "updating a Site type" do
    visit site_types_url
    click_on "Edit", match: :first

    fill_in "Description", with: @site_type.description
    fill_in "Name", with: @site_type.name
    click_on "Update Site type"

    assert_text "Site type was successfully updated"
    click_on "Back"
  end

  test "destroying a Site type" do
    visit site_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Site type was successfully destroyed"
  end
end
