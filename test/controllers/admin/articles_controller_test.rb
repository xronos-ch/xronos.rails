# frozen_string_literal: true

require 'test_helper'

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index new create edit update destroy],
    param_key: :article,
    requires_admin: true,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success },
      new: { not_signed_in: :redirect, signed_in: :success },
      create: { not_signed_in: :redirect, signed_in: :see_other },
      edit: { not_signed_in: :redirect, signed_in: :success },
      update: { not_signed_in: :redirect, signed_in: :see_other },
      destroy: { not_signed_in: :redirect, signed_in: :see_other }
    }
  )

  def smoke_payload_for(_action)
    attributes_for(:article).except(:user).merge(user_id: create(:user).id)
  end
end
