# frozen_string_literal: true

require 'test_helper'

class FunctionalClassificationsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # The controller's #index declares only `format.json` in its
  # respond_to, so the default-HTML smoke test gets 406. create /
  # update / destroy have no respond_to at all — they unconditionally
  # `redirect_to return_location` — so the status is the same
  # regardless of format.
  #
  # attributes_for returns assignable + category association objects;
  # the controller's strong params require assignable_type/assignable_id
  # and functional_classification_category_id.
  smoke_tests(
    actions: %i[index create update destroy],
    param_key: :functional_classification,
    statuses: {
      index: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      create: { not_signed_in: :not_found, signed_in: :found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  def smoke_payload_for(_action)
    attributes_for(:functional_classification)
      .except(:assignable, :functional_classification_category)
      .merge(
        assignable_type: 'Context',
        assignable_id: create(:context).id,
        functional_classification_category_id: create(:functional_classification_category).id
      )
  end

  test 'unauthenticated users cannot create functional classifications' do
    context = create(:context)
    category = create(:functional_classification_category)

    assert_no_difference('FunctionalClassification.count') do
      post functional_classifications_path, params: {
        functional_classification: {
          assignable_type: 'Context',
          assignable_id: context.id,
          functional_classification_category_id: category.id,
          confidence: 'certain',
          source: 'manual',
          note: 'Unauthorized test'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
end