# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id            :bigint           not null, primary key
#  country_code  :string
#  lat           :decimal(, )
#  lng           :decimal(, )
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
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

  test "destroying a site destroys its lod links" do
    site = create(:site, :with_lod_links, lod_links_count: 2)

    assert_dependent_destroy(site, :lod_links, count: 2)
  end

  test "site update creates version with peripheral snapshot" do
    with_versioning do
      site = create(:site, name: "original")
      site.update!(name: "updated")

      version = site.versions.last
      assert version.snapshot_id.present?,
        "Expected snapshot_id on site update version"
    end
  end

  test "site update snapshot captures peripherals" do
    with_versioning do
      site = create(:site, :with_site_names, :with_lod_links)
      site.update!(name: "renamed")

      version = site.versions.last
      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)

      site_name_items = snapshot.snapshot_items.where(child_group_name: "site_names")
      assert_equal site.site_names.count, site_name_items.size,
        "Expected snapshot to capture site_names"

      lod_link_items = snapshot.snapshot_items.where(child_group_name: "lod_links")
      assert_equal site.lod_links.count, lod_link_items.size,
        "Expected snapshot to capture lod_links"
    end
  end

  test "site name create triggers site version with snapshot" do
    with_versioning do
      site = create(:site)
      create(:site_name, site: site, name: "New Name")

      version = site.versions.reorder(created_at: :desc).first
      assert version.snapshot_id.present?,
        "Expected snapshot_id after site_name create"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      items = snapshot.snapshot_items.where(child_group_name: "site_names")
      assert_equal 1, items.size
      assert_equal "New Name", items.first.object["name"]
    end
  end

  test "lod link create triggers linkable version with snapshot" do
    with_versioning do
      site = create(:site)
      create(:lod_link, linkable: site, source: "Wikidata", external_id: "12345")

      version = site.versions.reorder(created_at: :desc).first
      assert version.snapshot_id.present?,
        "Expected snapshot_id after lod_link create"

      snapshot = ActiveSnapshot::Snapshot.find(version.snapshot_id)
      items = snapshot.snapshot_items.where(child_group_name: "lod_links")
      assert_equal 1, items.size
      assert_equal "Wikidata", items.first.object["source"]
      assert_equal "12345", items.first.object["external_id"]
    end
  end

end
