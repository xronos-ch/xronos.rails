require "test_helper"

class VersionedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # after_destroy_commit must fire
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

        create_table :snapshot_parents, force: true do |t|
          t.string :name
          t.timestamps
        end

        create_table :snapshot_peripherals, force: true do |t|
          t.integer :snapshot_parent_id
          t.string :name
          t.timestamps
        end
      end
    end
  end

  #
  # Test-only models
  #
  class SnapshotParent < ApplicationRecord
    self.table_name = "snapshot_parents"

    include Versioned

    has_many :peripherals,
      class_name: "VersionedTest::SnapshotPeripheral",
      foreign_key: :snapshot_parent_id,
      dependent: :destroy

    has_snapshot_children do
      instance = self.class.includes(:peripherals).find(id)
      { peripherals: instance.peripherals }
    end
  end

  class SnapshotPeripheral < ApplicationRecord
    self.table_name = "snapshot_peripherals"

    belongs_to :parent,
      class_name: "VersionedTest::SnapshotParent",
      foreign_key: :snapshot_parent_id,
      touch: true
  end

  class VersionedParent < ApplicationRecord
    self.table_name = "versioned_parents"

    include Versioned

    has_many :children,
      class_name: "VersionedTest::VersionedChild",
      foreign_key: :versioned_parent_id,
      dependent: :destroy

    has_one :single,
      class_name: "VersionedTest::VersionedSingle",
      foreign_key: :versioned_parent_id,
      dependent: :destroy

    has_many :unversioned_children,
      class_name: "VersionedTest::UnversionedChild",
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
      class_name: "VersionedTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  class VersionedSingle < ApplicationRecord
    self.table_name = "versioned_singles"

    include Versioned

    belongs_to :parent,
      class_name: "VersionedTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  # NOTE: intentionally does NOT include Versioned
  class UnversionedChild < ApplicationRecord
    self.table_name = "unversioned_children"

    belongs_to :parent,
      class_name: "VersionedTest::VersionedParent",
      foreign_key: :versioned_parent_id
  end

  #
  # Tests
  #

  test "revision_comment propagates for dependent: :destroy (has_many and has_one)" do
    parent = VersionedParent.create!

    child  = VersionedChild.create!(parent: parent)
    single = VersionedSingle.create!(parent: parent)

    parent.revision_comment = "Sync delete parent"
    parent.destroy

    assert_equal "Sync delete parent", child.versions.last.revision_comment
    assert_equal "Sync delete parent", single.versions.last.revision_comment
  end

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

  test "create_peripheral_snapshot stores snapshot_id on create" do
    with_versioning do
      parent = SnapshotParent.create!(name: "original")
      version = parent.versions.last

      assert version.snapshot_id.present?,
        "Expected snapshot_id on create version"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      assert_equal "VersionedTest::SnapshotParent", snapshot.item_type
      assert_equal parent.id, snapshot.item_id
    end
  end

  test "create_peripheral_snapshot stores snapshot_id on update" do
    with_versioning do
      parent = SnapshotParent.create!(name: "original")
      parent.update!(name: "updated")
      version = parent.versions.last

      assert version.snapshot_id.present?,
        "Expected snapshot_id on update version"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      peripheral_items = snapshot.snapshot_items.where.not(child_group_name: nil)
      assert_equal 0, peripheral_items.size, "Expected no peripheral items yet"
    end
  end

  test "peripheral create triggers parent version with snapshot" do
    with_versioning do
      parent = SnapshotParent.create!(name: "test")
      peripheral = SnapshotPeripheral.create!(parent: parent, name: "child")

      version = parent.versions.reorder(created_at: :desc).first
      assert version.snapshot_id.present?,
        "Expected snapshot_id after peripheral create"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      items = snapshot.snapshot_items.where(child_group_name: "peripherals")
      assert_equal 1, items.size
      assert_equal "child", items.first.object["name"]
    end
  end

  test "peripheral update triggers parent version with snapshot" do
    with_versioning do
      parent = SnapshotParent.create!(name: "test")
      peripheral = SnapshotPeripheral.create!(parent: parent, name: "child")

      peripheral.update!(name: "updated child")

      version = parent.versions.reorder(created_at: :desc).first
      assert version.snapshot_id.present?,
        "Expected snapshot_id after peripheral update"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      items = snapshot.snapshot_items.where(child_group_name: "peripherals")
      assert_equal 1, items.size
      assert_equal "updated child", items.first.object["name"]
    end
  end

  test "model without has_snapshot_children has nil snapshot_id" do
    with_versioning do
      # VersionedParent does not define has_snapshot_children
      parent = VersionedParent.create!
      version = parent.versions.last

      assert_nil version.snapshot_id,
        "Expected nil snapshot_id for model without has_snapshot_children"
    end
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
