# frozen_string_literal: true

require 'test_helper'

class CurateControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'dashboard includes Dendro totals and links to its issue lists' do
    sign_in create(:user)
    create(:dendro, waney_edge: nil)

    get curate_path

    assert_response :success
    assert_dom 'tbody tr', text: /Dendrochronological series\s+1/
    assert_dom "a[href='#{issues_dendros_path}/missing_waney_edge_info']", text: '1'
  end
end
