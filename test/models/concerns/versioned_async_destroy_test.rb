require "test_helper"

class VersionedAsyncDestroyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # after_destroy_commit must fire for async destroy tests
  self.use_transactional_tests = false

  #
  # Disposable schema for this test only
  #
  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :versioned_parents, force: true do |t|
          t.timestamps
        end

        create_table :versioned_children, force: true do |t|
          t.integer :versioned_parent_id
          t.timestamps
        end

        create_table :versioned_singles, force: true do |t|
          t.integer :versioned_parent_id
          t.timestamps
        end

        create_table :unversioned_children, force: true do |t|
          t.integer :versioned_parent_id
          t.timestamps
        end
      end
    end
  end

  teardown do
    PaperTrail::Version.where(item_type: [
      "VersionedAsyncDestroyTest::VersionedParent",
      "VersionedAsyncDestroyTest::VersionedChild",
      "VersionedAsyncDestroyTest::VersionedSingle"
    ]).delete_all

    # Use safe_constantize to avoid errors if classes aren't loaded
    %w[
      VersionedAsyncDestroyTest::VersionedSingle
      VersionedAsyncDestroyTest::VersionedChild
      VersionedAsyncDestroyTest::VersionedParent
      VersionedAsyncDestroyTest::UnversionedChild
    ].each do |class_name|
      class_name.safe_constantize&.delete_all
    end
  end

  #
  # Test-only models
  #
  class VersionedParent < ApplicationRecord
    self.table_name = "versioned_parents"

    include Versioned

    has_many :children,
      class_name: "VersionedAsyncDestroyTest::VersionedChild",
      foreign_key: :versioned_parent_id,
      dependent: :destroy

    has_one :single,
      class_name: "VersionedAsyncDestroyTest::VersionedSingle",
      foreign_key: :versioned_parent_id,
      dependent: :destroy

    has_many :unversioned_children,
      class_name: "VersionedAsyncDestroyTest::UnversionedChild",
      foreign_key: :versioned_parent_id,
      dependent: :destroy

    destroy_async_with_paper_trail :children
    destroy_async_with_paper_trail :single
    destroy_async_with_paper_trail :unversioned_children
  end

  class VersionedChild < ApplicationRecord
    self.table_name = "versioned_children"

    include Versioned

    belongs_to :parent,
      class_name: "VersionedAsyncDestroyTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  class VersionedSingle < ApplicationRecord
    self.table_name = "versioned_singles"

    include Versioned

    belongs_to :parent,
      class_name: "VersionedAsyncDestroyTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  # NOTE: intentionally does NOT include Versioned
  class UnversionedChild < ApplicationRecord
    self.table_name = "unversioned_children"

    belongs_to :parent,
      class_name: "VersionedAsyncDestroyTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  #
  # Tests
  #

  test "revision_comment propagates for async dependent destroy (has_many and has_one)" do
    parent = VersionedParent.create!

    child  = VersionedChild.create!(parent: parent)
    single = VersionedSingle.create!(parent: parent)

    parent.revision_comment = "Async delete parent"

    perform_enqueued_jobs do
      parent.destroy
    end

    assert_not VersionedChild.exists?(child.id)
    assert_not VersionedSingle.exists?(single.id)

    assert_equal "Async delete parent", child.versions.last.revision_comment
    assert_equal "Async delete parent", single.versions.last.revision_comment
  end

  test "non-Versioned children are skipped gracefully" do
    parent = VersionedParent.create!

    unversioned = UnversionedChild.create!(parent: parent)

    parent.revision_comment = "Delete parent"

    perform_enqueued_jobs do
      parent.destroy
    end

    assert_not UnversionedChild.exists?(unversioned.id),
      "Expected unversioned child to be destroyed"

    # No PaperTrail versions should exist for unversioned models
    assert_raises(NoMethodError) do
      unversioned.versions
    end
  end
end
