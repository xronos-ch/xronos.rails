# frozen_string_literal: true

require 'test_helper'

# Ensure Devise mappings are loaded before any sign_in call; the test
# environment does not eager-load routes by default.
Rails.application.routes.eager_load!

class LodLinksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @site = create(:site)
    @lod_link = create(:lod_link, linkable: @site, source: 'Wikidata', external_id: 12_345)
    @admin = create(:user, :admin)
  end

  # --- show ---

  test 'show renders the lod_link partial' do
    get lod_link_path(@lod_link)

    assert_response :success
    assert_match @lod_link.qcode, response.body
    assert_match @lod_link.source, response.body
  end

  # --- destroy ---

  test 'destroy as admin removes the record and redirects to the parent' do
    sign_in @admin

    assert_difference 'LodLink.count', -1 do
      delete lod_link_path(@lod_link)
    end
    assert_redirected_to @site
  end

  test 'destroy returns a turbo stream that removes the frame when other lod_links remain' do
    create(:lod_link, linkable: @site, source: 'Wikidata', external_id: 67_890)
    sign_in @admin

    delete lod_link_path(@lod_link),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

    assert_response :success
    assert_match(/<turbo-stream action="remove" target="lod_link_#{@lod_link.id}">/, response.body)
  end

  test 'destroy replaces the section with the empty state when the last lod_link is removed' do
    sign_in @admin

    delete lod_link_path(@lod_link),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

    assert_response :success
    assert_match(/<turbo-stream action="replace" target="site-external-links-content">/, response.body)
    assert_match 'There is no linked data available', response.body
  end

  test 'destroy as a non-admin user returns not found' do
    sign_in create(:user)

    delete lod_link_path(@lod_link)

    assert_response :not_found
    assert LodLink.exists?(@lod_link.id)
  end
end
