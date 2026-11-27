# frozen_string_literal: true

require 'test_helper'

class SitesSubmersionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @site = create(:site, lat: 4, lng: 1)
    @coordinates = { lat: '4.0', lng: '1.0' }
    @path = site_path(@site)
    publish_finding
  end

  teardown do
    Rails.cache.delete(Site::WaterCheck::CACHE_KEY)
  end

  test 'an editor can mark a site as submerged until its coordinates change' do
    editor = create(:user, :admin)
    sign_in editor
    get issues_sites_path(issue: :coordinates_in_water)
    assert_dom "form[action='#{@path}'] button", text: 'Mark as submerged'
    assert_dom "form[action='#{@path}'] input[name='_method'][value='patch']"

    with_versioning do
      post @path, params: { _method: 'patch', water_check_coordinates: @coordinates }, as: :turbo_stream
    end

    assert_redirected_to issues_sites_path(issue: :coordinates_in_water)
    assert @site.reload.submerged?
    assert_equal editor.id.to_s, @site.versions.last.whodunnit
    assert_not Site.coordinates_in_water.exists?(@site.id)

    patch @path, params: { site: { lng: '2', submerged: '1' } }
    assert_response :redirect
    assert_not @site.reload.submerged?
    publish_finding
    assert Site.coordinates_in_water.exists?(@site.id)
  end

  test 'an editor cannot confirm a finding from a stale form' do
    sign_in create(:user, :admin)
    @site.update!(lng: 2)
    publish_finding

    assert_no_changes -> { @site.reload.submerged? } do
      patch @path, params: { water_check_coordinates: @coordinates }
    end
  end

  test 'a user without site editing permission cannot confirm a finding' do
    sign_in create(:user)

    assert_no_changes -> { @site.reload.submerged? } do
      patch @path, params: { water_check_coordinates: @coordinates }
    end
    assert_response :not_found
  end

  private

  def publish_finding
    finding = { site_id: @site.id, lat: @site.lat, lng: @site.lng, distance_meters: 4000 }
    Rails.cache.write(Site::WaterCheck::CACHE_KEY, { checked_at: Time.current, findings: { @site.id => finding } })
  end
end
