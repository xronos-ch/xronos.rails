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

  test 'index renders paginated changelog' do
    sign_in create(:user, :admin)

    create_list(:site, 25)

    get curate_recent_changes_path

    assert_response :success
    assert_includes response.body, 'pagy'
    assert_includes response.body, 'series-nav'
  end

  test 'index includes both PaperTrail versions and SupersessionEvents' do
    sign_in create(:user, :admin)

    with_versioning do
      site = build(:site)
      site.revision_comment = 'Created test site'
      site.save!
    end

    superseded = create(:site)
    canonical = create(:site)
    SupersessionEvent.create!(
      event_type: 'supersede',
      superseded: superseded,
      superseded_by: canonical,
      whodunnit_user: create(:user)
    )

    get curate_recent_changes_path

    assert_response :success
    assert_includes response.body, 'Created test site'
    assert_includes response.body, 'Superseded by'
  end

  test 'index paginates mixed changelog entries' do
    sign_in create(:user, :admin)

    with_versioning do
      15.times { create(:site) }
    end

    12.times do
      SupersessionEvent.create!(
        event_type: 'supersede',
        superseded: create(:site),
        superseded_by: create(:site),
        whodunnit_user: create(:user)
      )
    end

    get curate_recent_changes_path, params: { page: 1 }

    assert_response :success
    assert_includes response.body, 'pagy'
    assert_includes response.body, 'series-nav'
  end

  test 'index shows message when no changes' do
    sign_in create(:user, :admin)

    get curate_recent_changes_path

    assert_response :success
    assert_includes response.body, 'No recent changes'
  end
end
