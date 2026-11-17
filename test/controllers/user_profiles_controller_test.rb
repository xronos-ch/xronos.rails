# frozen_string_literal: true

require 'test_helper'

class UserProfilesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # attributes_for(:user_profile) returns {user: <User>, ...}; the
  # controller's strong params permit :user_id.
  smoke_tests(
    actions: %i[new create edit update destroy],
    param_key: :user_profile,
    statuses: {
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  def smoke_payload_for(_action)
    attributes_for(:user_profile).except(:user).merge(user_id: create(:user).id)
  end

  test 'show includes both PaperTrail versions and SupersessionEvents for the user' do
    profile = create(:user_profile)
    user = profile.user
    sign_in create(:user, :admin)

    with_versioning do
      PaperTrail.request.whodunnit = user.id.to_s
      PaperTrail.request.controller_info = { whodunnit_user_email: user.email }
      3.times do
        site = build(:site)
        site.revision_comment = "Version by #{user.email}"
        site.save!
      end
    end

    3.times do
      SupersessionEvent.create!(
        event_type: 'supersede',
        superseded: create(:site),
        superseded_by: create(:site),
        whodunnit_user: user
      )
    end

    get contributor_path(profile)

    assert_response :success
    assert_includes response.body, "Version by #{user.email}"
    assert_includes response.body, 'Superseded by'
  end

  test 'show paginates user changelog entries' do
    profile = create(:user_profile)
    user = profile.user
    sign_in create(:user, :admin)

    with_versioning do
      PaperTrail.request.whodunnit = user.id.to_s
      PaperTrail.request.controller_info = { whodunnit_user_email: user.email }
      15.times { create(:site) }
    end

    12.times do
      SupersessionEvent.create!(
        event_type: 'supersede',
        superseded: create(:site),
        superseded_by: create(:site),
        whodunnit_user: user
      )
    end

    get contributor_path(profile)

    assert_response :success
    assert_includes response.body, 'pagy'
  end
end
