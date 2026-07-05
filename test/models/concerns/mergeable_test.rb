require 'test_helper'

class MergeableTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  #
  # Disposable schema for this test only
  #
  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :mergeable_things, force: true do |t|
          t.string :name
          t.string :category
          t.timestamps
        end

        create_table :mergeable_children, force: true do |t|
          t.references :mergeable_thing
          t.string :name
          t.timestamps
        end
      end
    end
  end

  # Setup model: Duplicable only (detection, no merge).
  class SetupThing < ApplicationRecord
    self.table_name = 'mergeable_things'

    include Duplicable
    exact_duplicates_on :name, :category
  end

  # Same, but with Supersedable's default scope.
  class SupersedableSetupThing < ApplicationRecord
    self.table_name = 'mergeable_things'

    include Duplicable
    include Supersedable
    exact_duplicates_on :name, :category
  end

  # Peripheral model with auto-merge on save.
  class MergeableThing < ApplicationRecord
    self.table_name = 'mergeable_things'

    include Mergeable

    exact_duplicates_on :name, :category

    has_many :children,
             class_name: 'MergeableTest::MergeableChild',
             foreign_key: :mergeable_thing_id,
             dependent: :destroy

    after_save :merge_exact_duplicates

    before_merge :reassign_children!

    def reassign_children!
      target_id = merged_into_id
      MergeableChild.where(mergeable_thing_id: id)
                    .update_all(mergeable_thing_id: target_id)
    end
  end

  # Raises in before_merge to test rollback.
  class RaisingMergeableThing < MergeableThing
    before_merge ->(*) { raise 'boom' }
  end

  # Includes Mergeable but does not opt in to auto-merge.
  class NoAutoMergeThing < ApplicationRecord
    self.table_name = 'mergeable_things'

    include Mergeable

    exact_duplicates_on :name, :category
  end

  class MergeableChild < ApplicationRecord
    self.table_name = 'mergeable_children'

    # optional: true so the test can assign any parent class
    belongs_to :mergeable_thing, optional: true
  end

  # Core model (Supersedable + Mergeable) with auto-merge on save.
  class SupersedableMergeable < ApplicationRecord
    self.table_name = 'mergeable_things'

    include Supersedable
    include Mergeable

    exact_duplicates_on :name, :category

    has_many :children,
             class_name: 'MergeableTest::MergeableChild',
             foreign_key: :mergeable_thing_id,
             dependent: :destroy

    after_save :merge_exact_duplicates

    before_merge :reassign_children!

    def reassign_children!
      target_id = merged_into_id
      MergeableChild.where(mergeable_thing_id: id)
                    .update_all(mergeable_thing_id: target_id)
    end
  end

  # Create N setup records in order (oldest first).
  def create_things(model, count, **attrs)
    Array.new(count) do |i|
      model.create!(attrs.merge(created_at: (count - i).minutes.ago,
                                updated_at: (count - i).minutes.ago))
    end
  end

  test 'find_exact_duplicate returns the oldest non-superseded record with the same duplicate keys' do
    create_things(SetupThing, 3, name: 'foo', category: 'a')
    all = MergeableThing.order(:created_at).to_a
    newest = all.last
    oldest_id = all.first.id

    assert_equal oldest_id, newest.find_exact_duplicate.id
  end

  test 'find_exact_duplicate returns nil when no other record matches' do
    create_things(SetupThing, 2, name: 'foo', category: 'a')
    SetupThing.create!(name: 'bar', category: 'a')

    bar = MergeableThing.find_by(name: 'bar')
    assert_nil bar.find_exact_duplicate
  end

  test 'find_exact_duplicate honours the Supersedable default scope' do
    create_things(SupersedableSetupThing, 2, name: 'foo', category: 'a')

    canonical = SupersedableMergeable.order(:created_at).first
    dupe      = SupersedableMergeable.order(:created_at).last

    dupe.supersede!(canonical, 'test setup')

    # dupe is hidden by the default scope, so no exact duplicate found.
    assert_nil canonical.reload.find_exact_duplicate
  end

  test 'merge_duplicates! picks the oldest record as canonical by default' do
    create_things(SetupThing, 3, name: 'foo', category: 'a')
    oldest_id = SetupThing.order(:created_at).first.id

    canonical = MergeableThing.merge_duplicates!(MergeableThing.all.to_a)
    assert_equal oldest_id, canonical.id
  end

  test 'merge_duplicates! honours an explicit canonical' do
    create_things(SetupThing, 3, name: 'foo', category: 'a')
    middle = SetupThing.order(:created_at).offset(1).first

    canonical = MergeableThing.merge_duplicates!(MergeableThing.all.to_a, canonical: middle)
    assert_equal middle.id, canonical.id
  end

  test 'merge_duplicates! returns the canonical' do
    create_things(SetupThing, 3, name: 'foo', category: 'a')
    oldest_id = SetupThing.order(:created_at).first.id

    assert_equal oldest_id, MergeableThing.merge_duplicates!(MergeableThing.all.to_a).id
  end

  test 'merge_duplicates! raises on an empty list' do
    assert_raises(ArgumentError) { MergeableThing.merge_duplicates!([]) }
  end

  test 'merge_duplicates! rolls back on a mid-batch failure' do
    create_things(SetupThing, 3, name: 'foo', category: 'a')
    initial_count = SetupThing.count

    call_count = 0
    MergeableThing.class_eval do
      alias_method :_orig_merge_into!, :merge_into!
      define_method(:merge_into!) do |canonical|
        call_count += 1
        raise 'boom' if call_count == 2

        _orig_merge_into!(canonical)
      end
    end

    assert_raises(RuntimeError) do
      MergeableThing.merge_duplicates!(MergeableThing.all.to_a)
    end

    assert_equal initial_count, SetupThing.count
  end

  test 'merge_into! sets merged_into_id on the in-memory record' do
    a, b = create_things(SetupThing, 2, name: 'foo', category: 'a')
    canonical = MergeableThing.find(a.id)
    dupe      = MergeableThing.find(b.id)

    dupe.merge_into!(canonical)

    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'merge_into! raises on self' do
    a = create_things(SetupThing, 1, name: 'foo', category: 'a').first
    only = MergeableThing.find(a.id)

    assert_raises(ArgumentError) { only.merge_into!(only) }
  end

  test 'merge_into! raises on a nil canonical' do
    a = create_things(SetupThing, 1, name: 'foo', category: 'a').first
    only = MergeableThing.find(a.id)

    assert_raises(ArgumentError) { only.merge_into!(nil) }
  end

  test 'peripheral merge destroys the dupe after the before_merge callback runs' do
    a, b = create_things(SetupThing, 2, name: 'foo', category: 'a')
    canonical = MergeableThing.find(a.id)
    dupe      = MergeableThing.find(b.id)

    b_child = MergeableChild.create!(mergeable_thing_id: dupe.id, name: 'b-child')
    a_child = MergeableChild.create!(mergeable_thing_id: canonical.id, name: 'a-child')

    dupe.merge_into!(canonical)

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, b_child.reload.mergeable_thing_id
    assert_equal canonical.id, a_child.reload.mergeable_thing_id
  end

  test 'peripheral merge rolls back when a before_merge callback raises' do
    a, b = create_things(SetupThing, 2, name: 'foo', category: 'a')

    b_child = MergeableChild.create!(mergeable_thing_id: b.id, name: 'b-child')

    dupe = RaisingMergeableThing.find(b.id)
    canonical = MergeableThing.find(a.id)

    assert_raises(RuntimeError) { dupe.merge_into!(canonical) }

    assert SetupThing.exists?(b.id)
    assert_equal b.id, b_child.reload.mergeable_thing_id
  end

  test 'core merge dispatches to supersede! and creates a SupersessionEvent' do
    a, b = create_things(SupersedableSetupThing, 2, name: 'foo', category: 'a')
    canonical = SupersedableMergeable.find(a.id)
    dupe      = SupersedableMergeable.find(b.id)

    assert_difference -> { Supersession.count } => 1,
                      -> { SupersessionEvent.count } => 1 do
      dupe.merge_into!(canonical)
    end

    assert dupe.superseded?
    assert_equal canonical, dupe.ultimately_superseded_by
  end

  test 'core merge runs the before_merge callback before supersede!' do
    a, b = create_things(SupersedableSetupThing, 2, name: 'foo', category: 'a')
    canonical = SupersedableMergeable.find(a.id)
    dupe      = SupersedableMergeable.find(b.id)

    b_child = MergeableChild.create!(mergeable_thing_id: dupe.id, name: 'b-child')

    dupe.merge_into!(canonical)

    assert_equal canonical.id, b_child.reload.mergeable_thing_id
    assert dupe.superseded?
    assert_equal canonical, dupe.ultimately_superseded_by
  end

  test "core merge does not destroy the dupe (it's soft-deleted via supersession)" do
    a, b = create_things(SupersedableSetupThing, 2, name: 'foo', category: 'a')
    canonical = SupersedableMergeable.find(a.id)
    dupe      = SupersedableMergeable.find(b.id)

    dupe.merge_into!(canonical)

    assert_not dupe.destroyed?
    assert dupe.superseded?
    assert_equal 2, SupersedableMergeable.unscoped.where(name: 'foo').count
  end

  test 'after_save auto-merges a newly created dupe into the existing canonical' do
    canonical = SetupThing.create!(name: 'foo', category: 'a')

    dupe = MergeableThing.create!(name: 'foo', category: 'a')

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, dupe.merged_into_id
    assert_equal 1, MergeableThing.count
  end

  test 'after_save auto-merges when an update makes the record match an existing one' do
    a = SetupThing.create!(name: 'foo', category: 'a')
    b = MergeableThing.create!(name: 'bar', category: 'a')

    b.update!(name: 'foo')

    assert_predicate b, :destroyed?
    assert_equal a.id, b.merged_into_id
    assert_equal 1, MergeableThing.where(name: 'foo').count
  end

  test 'after_save is a no-op when no duplicate exists' do
    MergeableThing.create!(name: 'foo', category: 'a')
    b = MergeableThing.create!(name: 'bar', category: 'a')

    assert_not b.destroyed?
    assert_nil b.merged_into_id
    assert_equal 2, MergeableThing.count
  end

  test 'after_save auto-merges a newly created dupe into a Supersedable canonical' do
    canonical = SupersedableSetupThing.create!(name: 'foo', category: 'a')

    dupe = SupersedableMergeable.create!(name: 'foo', category: 'a')

    assert_not dupe.destroyed?
    assert dupe.superseded?
    assert_equal canonical.id, dupe.ultimately_superseded_by.id
    assert_equal canonical.id, dupe.merged_into_id
    assert_equal 1, SupersedableMergeable.where(name: 'foo').count
  end

  test 'a model that includes Mergeable but does not opt in to auto-merge does not auto-merge on save' do
    canonical = NoAutoMergeThing.create!(name: 'foo', category: 'a')
    dupe      = NoAutoMergeThing.create!(name: 'foo', category: 'a')

    assert_not dupe.destroyed?
    assert_nil dupe.merged_into_id
    assert_equal 2, NoAutoMergeThing.count

    dupe.merge_into!(canonical)
    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'a model that includes only Duplicable has detection but not merge methods' do
    record = SetupThing.create!(name: 'foo', category: 'a')

    assert record.respond_to?(:find_exact_duplicate)
    assert record.respond_to?(:exact_duplicates)
    assert record.respond_to?(:is_exact_duplicate?)
    assert record.respond_to?(:potential_duplicates)
    assert record.respond_to?(:is_potential_duplicate?)

    refute record.respond_to?(:merge_into!)
    refute record.respond_to?(:merge_duplicates!)
    refute record.respond_to?(:merge_exact_duplicates)

    assert SetupThing.respond_to?(:exact_duplicates_on)
    assert SetupThing.respond_to?(:potential_duplicates_on)
    refute SetupThing.respond_to?(:merge_duplicates!)
  end

  test 'a model that includes Mergeable gets Duplicable transitively' do
    assert NoAutoMergeThing.respond_to?(:exact_duplicates_on)
    assert NoAutoMergeThing.respond_to?(:exact_duplicates_attrs)
    assert NoAutoMergeThing.respond_to?(:potential_duplicates_on)
    assert NoAutoMergeThing.respond_to?(:merge_duplicates!)
  end
end
