# frozen_string_literal: true

require 'test_helper'

class Curate::RecentChangesControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    requires_admin: false,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success }
    }
  )

  test "index renders paginated changelog" do
    sign_in create(:user, :admin)

    create_list(:site, 25)

    get curate_recent_changes_path

    assert_response :success
    assert_includes response.body, "pagy"
    assert_includes response.body, "series-nav"
  end

  test "index shows message when no changes" do
    sign_in create(:user, :admin)

    get curate_recent_changes_path

    assert_response :success
    assert_includes response.body, "No recent changes"
  end
end
