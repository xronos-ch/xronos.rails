# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id           :bigint           not null, primary key
#  country_code :string
#  lat          :decimal(, )
#  lng          :decimal(, )
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_sites_on_country_code  (country_code)
#  index_sites_on_name          (name)
#
require 'test_helper'

class SiteTest < ActiveSupport::TestCase

  test "has a valid factory" do
    assert FactoryBot.build(:site).save
  end

  test "is invalid without a name" do
    assert_not FactoryBot.build(:site, name: nil).save
  end

  test "is valid without a unique name" do
    FactoryBot.build(:site, name: "Test123").save
    assert FactoryBot.build(:site, name: "Test123").save
  end

  test "destroying a site destroys its contexts" do
    site = create(:site)
    create_list(:context, 3, site: site)

    assert_dependent_destroy(site, :contexts, count: 3)
  end

  test "destroying a site destroys its site names" do
    site = create(:site, :with_site_names, site_names_count: 2)
    assert_dependent_destroy(site, :site_names, count: 2)
  end

  test "destroying a site destroys its citations" do
    site = create(:site, :with_citations, citations_count: 2)
    assert_dependent_destroy(site, :citations, count: 2)
  end

  test "destroying a site destroys its linked resources" do
    site = create(:site, :with_linked_resources, linked_resources_count: 2)

    assert_dependent_destroy(site, :linked_resources, count: 2)
  end

  test "superseded site is hidden from default scope but findable via unscoped" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert_includes Site.all, canonical
    assert_not_includes Site.all, superseded
    assert_equal superseded, Site.unscoped.find(superseded.id)
  end

end
