# frozen_string_literal: true

require 'test_helper'
require 'rake'

class XronosSearchCleanupTest < ActiveSupport::TestCase
  setup do
    task_name = 'xronos:search:cleanup'
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    @task = Rake::Task[task_name]
  end

  test 'repeated cleanup removes stale documents and preserves current ones' do
    active = create(:site)
    superseded = create(:site)
    superseded.supersede!(active)
    superseded_document = PgSearch::Document.create!(searchable: superseded, content: superseded.name)
    missing = create(:site)
    missing_document = missing.pg_search_document
    missing.delete

    2.times do
      @task.reenable
      capture_io { @task.invoke }

      assert_not PgSearch::Document.exists?(superseded_document.id)
      assert_not PgSearch::Document.exists?(missing_document.id)
      assert PgSearch::Document.exists?(searchable: active)
    end
  end
end
