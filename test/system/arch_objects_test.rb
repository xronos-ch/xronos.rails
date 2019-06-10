require "application_system_test_case"

class ArchObjectsTest < ApplicationSystemTestCase
  setup do
    @arch_object = arch_objects(:one)
  end

  test "visiting the index" do
    visit arch_objects_url
    assert_selector "h1", text: "Arch Objects"
  end

  test "creating a Arch object" do
    visit arch_objects_url
    click_on "New Arch Object"

    click_on "Create Arch object"

    assert_text "Arch object was successfully created"
    click_on "Back"
  end

  test "updating a Arch object" do
    visit arch_objects_url
    click_on "Edit", match: :first

    click_on "Update Arch object"

    assert_text "Arch object was successfully updated"
    click_on "Back"
  end

  test "destroying a Arch object" do
    visit arch_objects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Arch object was successfully destroyed"
  end
end
