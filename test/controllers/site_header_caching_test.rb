# frozen_string_literal: true

require 'test_helper'

class SiteHeaderCachingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.eager_load!
    @previous_caching = SitesController.perform_caching
    @previous_cache_store = SitesController.cache_store
    SitesController.perform_caching = true
    SitesController.cache_store = ActiveSupport::Cache::MemoryStore.new
    @site = create(:site)
    @admin = create(:user, :admin)
  end

  teardown do
    SitesController.perform_caching = @previous_caching
    SitesController.cache_store = @previous_cache_store
  end

  test 'anonymous cache warmup does not hide editing from an admin' do
    get site_path(@site)
    assert_response :success
    assert_dom "a[href='#{edit_site_path(@site)}']", count: 0

    sign_in @admin
    assert_site_fragment_hit do
      get site_path(@site)
    end
    assert_response :success
    assert_dom "a[href='#{edit_site_path(@site)}'][data-turbo-frame='remote_modal']", count: 1
  end

  test 'admin cache warmup does not expose editing to anonymous or ordinary users' do
    sign_in @admin
    get site_path(@site)
    assert_response :success
    assert_dom "a[href='#{edit_site_path(@site)}']", count: 1

    sign_out @admin
    assert_site_fragment_hit do
      get site_path(@site)
    end
    assert_response :success
    assert_dom "a[href='#{edit_site_path(@site)}']", count: 0

    sign_in create(:user)
    assert_site_fragment_hit do
      get site_path(@site)
    end
    assert_response :success
    assert_dom "a[href='#{edit_site_path(@site)}']", count: 0
    assert_dom "a[href='#{new_site_site_name_path(@site)}']", count: 1
  end

  private

  def assert_site_fragment_hit(&block)
    hits = []
    subscriber = lambda do |event|
      hits << event.payload if event.payload[:hit] && event.payload[:key].to_s.include?('site_header')
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'cache_read.active_support', &block)
    assert_not_empty hits, 'Expected the site fragment to be served from cache'
  end
end
