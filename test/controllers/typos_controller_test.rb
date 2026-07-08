# frozen_string_literal: true

require 'test_helper'

include ControllerSmokeTest

class TyposControllerTest < ActionDispatch::IntegrationTest  
  # Typo belongs to Sample via :sample_id. attributes_for returns the
  # Sample object; strong params require :sample_id.
  smoke_tests(
    actions: %i[index new create edit update destroy],
    param_key: :typo,
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  def smoke_payload_for(_action)
    attributes_for(:typo).except(:sample).merge(sample_id: create(:sample).id)
  end

  test 'unauthenticated users cannot create typos' do
    assert_no_difference('Typo.count') do
      post typos_path, params: {
        typo: {
          name: 'Unauthorized Typo'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end
  
  test 'show redirects to the site of the typo' do
    site = create(:site)
    sample = create(:sample, context: create(:context, site: site))
    typo = create(:typo, sample: sample)

    get typo_path(typo)

    assert_response :moved_permanently
    assert_equal site_url(site), response.location
  end

  test 'show redirects to the site of the canonical typo when the typo is superseded' do
    site = create(:site)
    sample = create(:sample, context: create(:context, site: site))
    canonical = create(:typo, sample: sample)
    superseded = create(:typo, :superseded_by, canonical: canonical, sample: sample)

    get typo_path(superseded)

    assert_response :moved_permanently
    assert_equal site_url(site), response.location
  end

  test 'show follows a re-pointed chain to the site of the ultimate canonical' do
    site = create(:site)
    sample = create(:sample, context: create(:context, site: site))
    canonical = create(:typo, sample: sample)
    middle = create(:typo, sample: sample)
    leaf = create(:typo, sample: sample)

    leaf.supersede!(middle)
    middle.supersede!(canonical)

    get typo_path(leaf)

    assert_response :moved_permanently
    assert_equal site_url(site), response.location
  end
end
