# frozen_string_literal: true

require 'test_helper'

class LinkedResourcesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # LinkedResource has a polymorphic linkable + a (linkable_type,
  # linkable_id, source) unique index. attributes_for returns the
  # linkable association; the smoke payload needs linkable_type and
  # linkable_id, plus a fresh source/external_id to avoid unique
  # violations across test runs.
  smoke_tests(
    actions: %i[show new create edit update destroy],
    param_key: :linked_resource,
    requires_admin: false,
    statuses: {
      show: { not_signed_in: :success, signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :bad_request },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  def smoke_payload_for(_action)
    site = create(:site)
    source = LinkedResource::Source.all.first&.name || 'Wikidata'
    {
      linkable_type: 'Site',
      linkable_id: site.id,
      source: source,
      external_id: "Q#{SecureRandom.random_number(10**8)}",
      status: 'pending'
    }
  end

  test 'unauthenticated users cannot create linked resources' do
    site = create(:site)

    assert_no_difference('LinkedResource.count') do
      post linked_resources_path, params: {
        linked_resource: {
          linkable_type: 'Site',
          linkable_id: site.id,
          source: 'Wikidata',
          external_id: "Q#{SecureRandom.random_number(10**8)}",
          status: 'pending'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end