require 'test_helper'

class CountriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @country = FactoryBot.create(:country)
    @admin = FactoryBot.create(:user, :admin)
  end

  test "should get index" do
    get countries_url
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get new_country_url
    assert_response :success
  end

  test "should create country" do
    sign_in @admin
    assert_difference('Country.count') do
      post countries_url, params: { country: { name: "Testland1" } }
    end
    assert_redirected_to country_url(Country.last)
  end

  test "should show country" do
    get country_url(@country)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_country_url(@country)
    assert_response :success
  end

  test "should update country" do
    sign_in @admin
    patch country_url(@country), params: { country: { name: "Testland2" } }
    assert_redirected_to country_url(@country)
  end

  test "should destroy country" do
    sign_in @admin
    assert_difference('Country.count', -1) do
      delete country_url(@country)
    end
    assert_redirected_to countries_url
  end

end
