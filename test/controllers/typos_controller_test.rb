# frozen_string_literal: true

require 'test_helper'

class TyposControllerTest < ActionDispatch::IntegrationTest
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
