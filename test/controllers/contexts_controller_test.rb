# frozen_string_literal: true

require 'test_helper'

class ContextsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # attributes_for(:context) returns {site: <Site>, ...} but the
  # controller's strong params require :site_id.
  smoke_tests(
    param_key: :context,
    statuses: {
      index: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      show: { not_signed_in: :success, signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :not_acceptable },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  test 'shows active measurements and their references for an unnamed context' do
    site = create(:site)
    context = create(:context, site: site, name: nil)
    sample = create(:sample, context: context)
    date = create(:c14, sample: sample, lab_identifier: 'OxA-123', bp: 4110, std: 85)
    other_date = create(:c14, sample: create(:sample, context: create(:context, site: site)))
    reference = create(:reference, short_ref: 'Excavation report')
    create(:citation, citing: date, reference: reference)

    get context_path(context)

    assert_response :success
    assert_dom 'h1', text: "Unnamed context ##{context.id}"
    assert_dom "a[href='#{c14_path(date)}']", text: 'OxA-123'
    assert_dom 'td', text: '4110 ± 85 BP'
    assert_dom "a[href='#{reference_path(reference)}']", text: 'Excavation report'
    assert_dom "a[href='#{c14_path(other_date)}']", count: 0
  end

  def smoke_payload_for(_action)
    attributes_for(:context).except(:site).merge(site_id: create(:site).id)
  end
end
