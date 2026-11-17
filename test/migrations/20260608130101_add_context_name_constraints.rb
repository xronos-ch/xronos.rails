require "test_helper"
require Rails.root.join(
  "db/migrate/20260608130101_add_context_name_constraints.rb"
)

class MergeDuplicateContextsTest < ActiveSupport::TestCase
  setup do
    @migration = AddContextNameConstraints.new
    @site = create(:site)
  end

  test "merges duplicate blank contexts and moves associations" do
    c1 = create(:context, site: @site, name: nil)
    c2 = create(:context, site: @site, name: "")

    sample = create(:sample, context: c2)
    classification = create(:functional_classification, assignable: c2)

    @migration.up

    contexts = Context.where(site: @site, name: nil)
    assert_equal 1, contexts.count

    canonical = contexts.first

    assert_equal canonical.id, sample.reload.context_id
    assert_equal canonical.id, classification.reload.context_id
  end

  test "merges duplicate named contexts per site" do
    c1 = create(:context, site: @site, name: "Trench B")
    c2 = create(:context, site: @site, name: "Trench B")

    sample = create(:sample, context: c2)

    @migration.up

    contexts = Context.where(site: @site, name: "Trench B")
    assert_equal 1, contexts.count

    canonical = contexts.first
    assert_equal canonical.id, sample.reload.context_id
  end

  test "does not merge same names across different sites" do
    site2 = create(:site)

    create(:context, site: @site,  name: "Area 1")
    create(:context, site: site2, name: "Area 1")

    @migration.up

    assert_equal 1, Context.where(site: @site,  name: "Area 1").count
    assert_equal 1, Context.where(site: site2, name: "Area 1").count
  end
end
