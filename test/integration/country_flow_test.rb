require 'test_helper'

class CountryFlowTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @country1 = FactoryBot.create(:country)
    @country2 = FactoryBot.create(:country)
    @admin = FactoryBot.create(:user, :admin)
  end

#  test 'country index' do
#    visit countries_path
#    click_on "left_window_nav_general"
#    assert has_content?(@country1.name)
#    assert has_content?(@country2.name)
#  end

#  test 'creating a new country' do
#    sign_in @admin
#    visit countries_path
#    click_on "left_window_nav_general"

#    click_on 'New Country'

#    fill_in 'Name', with: 'Tolles Land'

#    click_on 'Create Country'

#    assert_current_path country_path(Country.last)
#    assert has_content?('Tolles Land')
#  end

end
