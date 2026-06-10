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

end
