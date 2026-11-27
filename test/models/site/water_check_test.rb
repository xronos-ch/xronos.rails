# frozen_string_literal: true

require 'test_helper'

class SiteWaterCheckTest < ActiveSupport::TestCase
  teardown do
    Rails.cache.delete(Site::WaterCheck::CACHE_KEY)
  end

  test 'changing coordinates clears a mark set after the site was loaded' do
    site = create(:site, lat: 4, lng: 1)
    Site.find(site.id).update!(submerged: true)

    site.update!(lng: 2)

    assert_not site.reload.submerged?
  end

  test 'a dry run leaves the previous report intact and stale findings are hidden' do
    offshore = create(:site, lat: 4, lng: 1)
    create(:site, lat: 4, lng: 2)
    create(:site, lat: 4, lng: 3)
    reference = Object.new
    def reference.distance_to_shore(lng, _lat)
      { 1 => 4000, 2 => 500 }.fetch(lng.to_i, nil)
    end
    check = Site::WaterCheck.new(reference: reference)

    check.run(persist: true)
    report = Site::WaterCheck.report
    assert_equal [offshore.id], report.fetch(:findings).keys

    offshore.update!(lng: 3)
    assert_empty check.run
    assert_equal report, Site::WaterCheck.report
    assert_not_includes offshore.reload.issues, :coordinates_in_water
    assert_not Site.coordinates_in_water.exists?(offshore.id)
  end
end
