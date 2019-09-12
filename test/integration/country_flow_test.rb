require 'test_helper'

class PostFlowTest < Capybara::Rails::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @country1 = FactoryBot.create(:country)
    @country2 = FactoryBot.create(:country)
    @admin = FactoryBot.create(:user)
  end

  test 'country index' do
    visit countries_path
    assert page.has_content?(@country1.name)
    assert page.has_content?(@country2.name)
  end

  test 'creating a new country' do
    sign_in @admin
    visit countries_path

    click_on 'New Country'

    fill_in 'Name', with: 'Tolles Land'

    click_on 'Create Country'

    assert_current_path country_path(Country.last)
    assert page.has_content?('Tolles Land')
  end

end
