require "application_system_test_case"

class SpeciesTest < ApplicationSystemTestCase
  setup do
    @species = species(:one)
  end

  test "visiting the index" do
    visit species_url
    assert_selector "h1", text: "Species"
  end

  test "creating a Species" do
    visit species_url
    click_on "New Species"

    fill_in "Family", with: @species.family
    fill_in "Genus", with: @species.genus
    fill_in "Species", with: @species.species
    fill_in "Subspecies", with: @species.subspecies
    click_on "Create Species"

    assert_text "Species was successfully created"
    click_on "Back"
  end

  test "updating a Species" do
    visit species_url
    click_on "Edit", match: :first

    fill_in "Family", with: @species.family
    fill_in "Genus", with: @species.genus
    fill_in "Species", with: @species.species
    fill_in "Subspecies", with: @species.subspecies
    click_on "Update Species"

    assert_text "Species was successfully updated"
    click_on "Back"
  end

  test "destroying a Species" do
    visit species_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Species was successfully destroyed"
  end
end
