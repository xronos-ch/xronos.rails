require "application_system_test_case"

class LabsTest < ApplicationSystemTestCase
  setup do
    @lab = labs(:one)
  end

  test "visiting the index" do
    visit labs_url
    assert_selector "h1", text: "Labs"
  end

  test "creating a Lab" do
    visit labs_url
    click_on "New Lab"

    check "Active" if @lab.active
    fill_in "Name", with: @lab.name
    click_on "Create Lab"

    assert_text "Lab was successfully created"
    click_on "Back"
  end

  test "updating a Lab" do
    visit labs_url
    click_on "Edit", match: :first

    check "Active" if @lab.active
    fill_in "Name", with: @lab.name
    click_on "Update Lab"

    assert_text "Lab was successfully updated"
    click_on "Back"
  end

  test "destroying a Lab" do
    visit labs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Lab was successfully destroyed"
  end
end
