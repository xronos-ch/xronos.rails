require 'test_helper'

class PostFlowTest < Capybara::Rails::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = FactoryBot.create(:user, :admin)
  end

  test 'creating a new arch_object' do
    sign_in @admin
    visit arch_objects_path

    click_on 'New Arch Object'

    #fill_in 'Name', with: 'Tolles Land'

    #click_on 'Create Country'

    #assert_current_path country_path(Country.last)
    #assert page.has_content?('Tolles Land')
  end

end
