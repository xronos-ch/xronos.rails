# frozen_string_literal: true

require 'test_helper'

class FunctionalClassificationsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # attributes_for returns assignable + category association objects;
  # the controller's strong params require assignable_type/assignable_id
  # and functional_classification_category_id.
  smoke_tests(
    actions: %i[index create update destroy],
    param_key: :functional_classification,
    query_params: { format: :json },
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
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
end
