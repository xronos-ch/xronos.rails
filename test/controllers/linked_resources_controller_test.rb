# frozen_string_literal: true

require 'test_helper'

# Ensure Devise mappings are loaded before any sign_in call; the test
# environment does not eager-load routes by default.
Rails.application.routes.eager_load!

class LinkedResourcesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @site = create(:site)
    @linked_resource = create(:linked_resource, linkable: @site, source: 'Wikidata', external_id: 12_345)
    @admin = create(:user, :admin)
  end

  # --- show ---

  test 'show renders the linked_resource partial' do
    get linked_resource_path(@linked_resource)

    assert_response :success
    assert_match @linked_resource.qcode, response.body
    assert_match @linked_resource.source, response.body
  end

  # --- destroy ---

  test 'destroy as admin removes the record and redirects to the parent' do
    sign_in @admin

    assert_difference 'LinkedResource.count', -1 do
      delete linked_resource_path(@linked_resource)
    end
    assert_redirected_to @site
  end

  test 'destroy returns a turbo stream that removes the frame when other linked_resources remain' do
    create(:linked_resource, linkable: @site, source: 'Wikidata', external_id: 67_890)
    sign_in @admin

    delete linked_resource_path(@linked_resource),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

    assert_response :success
    assert_match(/<turbo-stream action="remove" target="linked_resource_#{@linked_resource.id}">/, response.body)
  end

  test 'destroy replaces the section with the empty state when the last linked_resource is removed' do
    sign_in @admin

    delete linked_resource_path(@linked_resource),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

    assert_response :success
    assert_match(/<turbo-stream action="replace" target="site-external-links-content">/, response.body)
    assert_match 'There is no linked data available', response.body
  end

  test 'destroy as a non-admin user returns not found' do
    sign_in create(:user)

    delete linked_resource_path(@linked_resource)

    assert_response :not_found
    assert LinkedResource.exists?(@linked_resource.id)
  end
end
