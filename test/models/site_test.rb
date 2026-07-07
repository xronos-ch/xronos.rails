# frozen_string_literal: true

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
  test 'has a valid factory' do
    assert FactoryBot.build(:site).save
  end

  test 'is invalid without a name' do
    assert_not FactoryBot.build(:site, name: nil).save
  end

  test 'is valid without a unique name' do
    FactoryBot.build(:site, name: 'Test123').save
    assert FactoryBot.build(:site, name: 'Test123').save
  end

  test 'destroying a site destroys its contexts' do
    site = create(:site)
    create_list(:context, 3, site: site)

    assert_dependent_destroy(site, :contexts, count: 3)
  end

  test 'destroying a site destroys its site names' do
    site = create(:site, :with_site_names, site_names_count: 2)
    assert_dependent_destroy(site, :site_names, count: 2)
  end

  test 'destroying a site destroys its citations' do
    site = create(:site, :with_citations, citations_count: 2)
    assert_dependent_destroy(site, :citations, count: 2)
  end

  test 'destroying a site destroys its linked resources' do
    site = create(:site, :with_linked_resources, linked_resources_count: 2)

    assert_dependent_destroy(site, :linked_resources, count: 2)
  end

  test 'superseded site is hidden from default scope but findable via unscoped' do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert_includes Site.all, canonical
    assert_not_includes Site.all, superseded
    assert_equal superseded, Site.unscoped.find(superseded.id)
  end

  #
  # Deduplication
  #

  test 'auto-merges on create when all key attrs match' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    # Bypass `validate :no_exact_duplicate, on: :create` to exercise
    # the after_save merge path in isolation.
    dupe = build(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    dupe.save(validate: false)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges on update when an update creates a duplicate' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    other = create(:site, name: 'Sigiriya', lat: 7.95, lng: 80.75, country_code: 'LK')

    other.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0)

    assert_predicate other, :superseded?
    assert_equal canonical.id, other.merged_into_id
  end

  test 'does not auto-merge when name is unique' do
    create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    other = create(:site, name: 'Sigiriya', lat: 7.95, lng: 80.75, country_code: 'LK')

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when name matches but lat differs' do
    create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    other = create(:site, name: 'Anuradhapura', lat: 7.95, lng: 80.0, country_code: 'LK')

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when name matches but one has lat and other has nil lat' do
    create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    other = create(:site, name: 'Anuradhapura', lat: nil, lng: nil, country_code: nil)

    # nil != 8.0 (strict nil default) — they don't match
    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'auto-merges when all lat/lng/country_code are nil on both sides (nil_matches_nil)' do
    create(:site, name: 'Anuradhapura', lat: nil, lng: nil, country_code: nil)

    # Bypass `validate :no_exact_duplicate, on: :create` to exercise
    # the after_save merge path in isolation.
    other = build(:site, name: 'Anuradhapura', lat: nil, lng: nil, country_code: nil)
    other.save(validate: false)

    assert_predicate other, :superseded?
  end

  #
  # Linked-resource-aware duplicate detection
  #

  test 'does not auto-merge when linked_resources conflict (same source, different external_id)' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q1')

    dupe = create(:site)
    create(:linked_resource, linkable: dupe, source: 'Wikidata', external_id: 'Q2')
    dupe.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    assert_not dupe.superseded?
    assert_nil dupe.merged_into_id
  end

  test 'auto-merges when linked_resources have the same source and external_id' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q1')

    dupe = create(:site)
    create(:linked_resource, linkable: dupe, source: 'Wikidata', external_id: 'Q1')
    dupe.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges when linked_resources are from different sources (no overlap)' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q1')

    dupe = create(:site)
    create(:linked_resource, linkable: dupe, source: 'Pleiades', external_id: '12345')
    dupe.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges when only canonical has linked_resources (no conflict)' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q1')

    dupe = create(:site)
    dupe.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges when only dupe has linked_resources (no conflict)' do
    canonical = create(:site, name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    dupe = create(:site)
    create(:linked_resource, linkable: dupe, source: 'Wikidata', external_id: 'Q1')
    dupe.update!(name: 'Anuradhapura', lat: 8.0, lng: 80.0, country_code: 'LK')

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'reassigns non-colliding contexts to canonical on merge' do
    canonical = create(:site)
    canonical_context = create(:context, site: canonical, name: 'Trench A')
    # Create the dupe with a unique name first to avoid auto-merge
    # on create. Then attach a child, then update to match.
    dupe = create(:site)
    dupe_context = create(:context, site: dupe, name: 'Trench B')

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe_context.reload.site_id
    assert_equal canonical.id, canonical_context.reload.site_id
  end

  test 'merges contexts on name collision (uses Context Mergeable)' do
    canonical = create(:site)
    canonical_context = create(:context, site: canonical, name: 'Trench A')
    # Create the dupe with a unique name first
    dupe = create(:site)
    dupe_context = create(:context, site: dupe, name: 'Trench A')
    sample = create(:sample, context: dupe_context)
    dupe_context_id = dupe_context.id

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    # The dupe's context is destroyed (merged into the canonical's)
    assert_not Context.exists?(dupe_context_id)
    # The canonical's context still exists with the dupe's sample reassigned
    assert Context.exists?(canonical_context.id)
    assert_equal canonical_context.id, sample.reload.context_id
  end

  test 'reassigns site_names to canonical on merge' do
    canonical = create(:site, :with_site_names, site_names_count: 1)
    dupe = create(:site, :with_site_names, site_names_count: 1)
    dupe_site_name = dupe.site_names.first

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe_site_name.reload.site_id
  end

  test 'reassigns non-colliding citations to canonical on merge' do
    canonical = create(:site, :with_citations, citations_count: 2)
    dupe = create(:site, :with_citations, citations_count: 2)
    dupe_citation_count = dupe.citations.count
    canonical_citation_count_before = canonical.citations.count

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    assert_equal 0, dupe.citations.count
    # The dupe's citations have been reassigned to the canonical
    assert_equal canonical_citation_count_before + dupe_citation_count,
                 canonical.citations.count
  end

  test 'reassigns non-colliding linked_resources to canonical on merge' do
    canonical = create(:site)
    dupe = create(:site)
    # Use different sources so there's no collision.
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q111')
    create(:linked_resource, linkable: dupe,      source: 'Pleiades', external_id: '222')
    dupe_link = dupe.linked_resources.first

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    assert_equal 0, dupe.linked_resources.count
    # The dupe's link is now on the canonical
    assert_equal canonical.id, LinkedResource.find(dupe_link.id).linkable_id
  end

  test 'reassigns site_types to canonical on merge (HABTM, AR <<)' do
    canonical = create(:site)
    # The site factory assigns one site_type to each site
    canonical_types = canonical.site_types.to_a
    dupe = create(:site)
    dupe_types = dupe.site_types.to_a

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    # Reload canonical to get fresh data (its in-memory site_types
    # association may be stale).
    canonical.reload
    # The canonical retains its original site types
    canonical_types.each do |site_type|
      assert_includes canonical.site_types, site_type
    end
    # The dupe's site types are now on the canonical
    dupe_types.each do |site_type|
      assert_includes canonical.site_types, site_type
    end
    # The dupe's join table rows are gone
    assert_equal 0, dupe.site_types.count
  end

  test 'reassigns functional_classifications to canonical on merge' do
    canonical = create(:site)
    dupe = create(:site)
    category = create(:functional_classification_category)
    create(:functional_classification, assignable: dupe, functional_classification_category: category)

    dupe.update!(name: canonical.name, lat: canonical.lat, lng: canonical.lng, country_code: canonical.country_code)

    assert_predicate dupe, :superseded?
    assert_equal 0, FunctionalClassification.where(assignable_type: 'Site', assignable_id: dupe.id).count
    assert_equal 1, FunctionalClassification.where(assignable_type: 'Site', assignable_id: canonical.id).count
  end
end
