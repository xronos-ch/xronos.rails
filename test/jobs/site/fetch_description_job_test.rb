# frozen_string_literal: true

require 'test_helper'

class Site::FetchDescriptionJobTest < ActiveJob::TestCase # rubocop:disable Style/ClassAndModuleChildren
  setup do
    Rails.cache.clear
    @site = FactoryBot.create(:site)
    @linked_resource = FactoryBot.create(:linked_resource,
                                         linkable: @site,
                                         source: 'Wikidata',
                                         external_id: 123,
                                         status: 'approved')
  end

  test 'enqueues with the site id' do
    assert_enqueued_with(job: Site::FetchDescriptionJob, args: [@site.id]) do
      Site::FetchDescriptionJob.perform_later(@site.id)
    end
  end

  test 'pre-warms the description cache' do
    description = Site::Description.new(linked_resource: @linked_resource)
    called = false
    description.define_singleton_method(:data) { called = true }

    Site::Description.stub :new, description do
      Site::FetchDescriptionJob.perform_now(@site.id)
    end

    assert called, 'expected description.data to be called'
  end

  test 'returns silently when the site does not exist' do
    called = false
    Site::Description.stub :new, ->(**) { called = true } do
      Site::FetchDescriptionJob.perform_now(-1)
    end
    refute called
  end

  test 'returns silently when the site has no approved Wikidata link' do
    site = FactoryBot.create(:site)
    called = false
    Site::Description.stub :new, ->(**) { called = true } do
      Site::FetchDescriptionJob.perform_now(site.id)
    end
    refute called
  end

  test 'returns silently when the linked_resource is pending' do
    site = FactoryBot.create(:site)
    FactoryBot.create(:linked_resource,
                      linkable: site,
                      source: 'Wikidata',
                      external_id: 456,
                      status: 'pending')

    called = false
    Site::Description.stub :new, ->(**) { called = true } do
      Site::FetchDescriptionJob.perform_now(site.id)
    end
    refute called
  end

  test 'raises on internal errors so the job retries' do
    Site::Description.stub :new, ->(**) { raise 'boom' } do
      assert_raises(StandardError) do
        Site::FetchDescriptionJob.perform_now(@site.id)
      end
    end
  end
end
