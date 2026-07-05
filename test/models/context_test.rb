# == Schema Information
#
# Table name: contexts
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_id           :integer
#
# Indexes
#
#  index_contexts_on_name                 (name)
#  index_contexts_on_site_id              (site_id)
#  index_contexts_one_null_name_per_site  (site_id) UNIQUE WHERE (name IS NULL)
#  index_contexts_unique_name_per_site    (site_id,name) UNIQUE WHERE (name IS NOT NULL)
#
require 'test_helper'

class ContextTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
  end

  test "destroying a context destroys its samples" do
    context = create(:context)
    create_list(:sample, 2, context: context)

    assert_dependent_destroy(context, :samples, count: 2)
  end

  test "blank names are normalised to nil" do
    context = Context.create!(site: @site, name: "   ")
    assert_nil context.name
  end

  test "allows one blank context per site" do
    create(:context, site: @site, name: nil)

    second = Context.new(site: @site, name: nil)
    assert_not second.valid?
    assert_includes second.errors[:name], "can only be blank once per site"
  end

  test "allows blank contexts on different sites" do
    create(:context, site: @site, name: nil)

    other_site = create(:site)
    context = Context.new(site: other_site, name: nil)

    assert context.valid?
  end

  test "disallows duplicate names per site" do
    create(:context, site: @site, name: "Trench A")

    duplicate = Context.new(site: @site, name: "Trench A")
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "allows same name on different sites" do
    create(:context, site: @site, name: "Trench A")

    other_site = create(:site)
    context = Context.new(site: other_site, name: "Trench A")

    assert context.valid?
  end

  #
  # Deduplication
  #
  # Context's model-level uniqueness validations and DB unique index
  # already prevent new duplicates from being created. The Mergeable
  # framework is here to power Site#reassign_contexts!: when two sites
  # are merged, contexts that share a name under both sites are
  # explicitly merged via `merge_into!` to preserve all chronological
  # data (samples, C14s, typos, functional classifications).
  #
  # These tests verify the merge framework's behaviour directly.
  # find_exact_duplicate detection is covered by the framework's
  # own tests in test/models/concerns/duplicable_test.rb.
  #

  test "reassigns samples to the canonical on merge" do
    canonical = create(:context, site: @site, name: "Trench A")
    dupe = create(:context, site: @site, name: "Trench B")
    sample = create(:sample, context: dupe)

    dupe.merge_into!(canonical)

    assert_predicate dupe, :destroyed?
    assert_equal canonical.id, sample.reload.context_id
  end

  test "reassigns non-colliding functional_classifications to the canonical on merge" do
    canonical = create(:context, site: @site, name: "Trench A")
    dupe = create(:context, site: @site, name: "Trench B")
    category = create(:functional_classification_category)
    create(:functional_classification, assignable: dupe, functional_classification_category: category)

    dupe.merge_into!(canonical)

    assert_predicate dupe, :destroyed?
    assert_equal 0, FunctionalClassification.where(assignable_type: "Context", assignable_id: dupe.id).count
    assert_equal 1, FunctionalClassification.where(assignable_type: "Context", assignable_id: canonical.id).count
  end

  test "destroys colliding functional_classifications on merge" do
    canonical = create(:context, site: @site, name: "Trench A")
    dupe = create(:context, site: @site, name: "Trench B")
    category = create(:functional_classification_category)
    create(:functional_classification, assignable: canonical, functional_classification_category: category)
    create(:functional_classification, assignable: dupe,      functional_classification_category: category)

    assert_difference "FunctionalClassification.count", -1 do
      dupe.merge_into!(canonical)
    end

    # Canonical's classification remains; dupe's collision is destroyed
    assert_equal 1, FunctionalClassification.where(assignable_type: "Context", assignable_id: canonical.id).count
    assert_equal 0, FunctionalClassification.where(assignable_type: "Context", assignable_id: dupe.id).count
  end

  test "hard-destroys the dupe (Context is not Supersedable)" do
    canonical = create(:context, site: @site, name: "Trench A")
    dupe = create(:context, site: @site, name: "Trench B")

    dupe.merge_into!(canonical)

    assert_predicate dupe, :destroyed?
    # The canonical still exists
    assert Context.exists?(canonical.id)
  end
end
