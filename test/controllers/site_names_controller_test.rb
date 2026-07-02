# frozen_string_literal: true

require 'test_helper'

class SiteNamesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # NOTE: this controller is missing load_and_authorize_resource. The
  # not_signed_in status for mutating actions is expected to be in
  # REJECTED_STATUSES (302/303/404/422); if the test fails, that's a
  # surfacing of the auth-bypass finding.
  smoke_tests(
    actions: %i[new create edit update destroy],
    param_key: :site_name,
    parent: { site_id: :smoke_site_id },
    statuses: {
      new: { not_signed_in: :success, signed_in: :success },
      create: { not_signed_in: :redirect, signed_in: :found },
      edit: { not_signed_in: :success, signed_in: :success },
      update: { not_signed_in: :redirect, signed_in: :found },
      destroy: { not_signed_in: :redirect, signed_in: :found }
    }
  )

  # Override smoke_record so it shares the same parent site as the
  # parent params (otherwise @site.site_names.find would 404).
  def smoke_record
    @smoke_record ||= create(:site_name, site_id: smoke_site_id)
  end

  def smoke_site_id
    @smoke_site_id ||= create(:site).id
  end

  # attributes_for(:site_name) returns {site: <Site>, ...}; the
  # controller's strong params accept site_id only via the parent URL
  # helper, not the body.
  def smoke_payload_for(_action)
    attributes_for(:site_name).except(:site)
  end
end
