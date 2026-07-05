# frozen_string_literal: true

# == Schema Information
#
# Table name: linked_resources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  data          :jsonb
#  linkable_type :string           not null
#  source        :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string           not null
#  linkable_id   :bigint           not null
#
# Indexes
#
#  index_linked_resources_on_linkable_and_source            (linkable_type,linkable_id,source) UNIQUE
#  index_linked_resources_on_linkable_type_and_linkable_id  (linkable_type,linkable_id)
#
require 'test_helper'

class LinkedResourceTest < ActiveSupport::TestCase
  test 'has a valid factory' do
    assert FactoryBot.build(:linked_resource).save
  end

  test 'external_url returns the registered URL for a known source' do
    linked_resource = build(:linked_resource, source: 'Wikidata', external_id: 'Q12345')
    assert_equal 'https://www.wikidata.org/wiki/Q12345', linked_resource.external_url
  end

  test 'external_url returns nil for an unknown source' do
    linked_resource = build(:linked_resource, source: 'OpenStreetMap', external_id: 'Q12345')
    assert_nil linked_resource.external_url
  end

  test 'validates external_id against the source id_pattern' do
    linked_resource = build(:linked_resource, source: 'Wikidata', external_id: 'abc')
    refute linked_resource.valid?
    assert_includes linked_resource.errors[:external_id],
                    'does not match the expected format for Wikidata'
  end

  test 'rejects an unknown source name' do
    linked_resource = build(:linked_resource, source: 'NotASource', external_id: 'Q12345')
    refute linked_resource.valid?
    assert_includes linked_resource.errors[:source],
                    'is not a known linked resource source'
  end

  test 'accepts a non-integer id from a source with no id_pattern' do
    LinkedResource::Source.register :freeform_source, name: 'Freeform',
                                                      url_template: 'https://freeform.example/%<id>s'
    begin
      linked_resource = build(:linked_resource, source: 'Freeform', external_id: 'anything goes')
      assert linked_resource.valid?
    ensure
      LinkedResource::Source.registry.delete(:freeform_source)
    end
  end

  test 'rejects two records with the same (linkable, source) but different external_ids' do
    site = create(:site)
    create(:linked_resource, linkable: site, source: 'Wikidata', external_id: 'Q111')
    duplicate = build(:linked_resource, linkable: site, source: 'Wikidata', external_id: 'Q222')

    refute duplicate.valid?
    assert_includes duplicate.errors[:source], 'has already been taken'
  end

  test 'allows the same source on a different linkable' do
    site_a = create(:site)
    site_b = create(:site)
    create(:linked_resource, linkable: site_a, source: 'Wikidata', external_id: 'Q111')
    other = build(:linked_resource, linkable: site_b, source: 'Wikidata', external_id: 'Q111')

    assert other.valid?
  end

  test 'allows different sources on the same linkable' do
    site = create(:site)
    create(:linked_resource, linkable: site, source: 'Wikidata', external_id: 'Q111')
    other = build(:linked_resource, linkable: site, source: 'Pleiades', external_id: '111')

    assert other.valid?
  end

  #
  # LinkedResource.reassign_all_to!
  #

  test 'reassign_all_to! moves linked_resources from one Site to another' do
    canonical = create(:site)
    dupe      = create(:site)
    create(:linked_resource, linkable: dupe, source: 'Wikidata', external_id: 'Q111')

    result = LinkedResource.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 0, result[:destroyed_collisions]
    assert_equal 0, LinkedResource.where(linkable_type: 'Site', linkable_id: dupe.id).count
    assert_equal 1, LinkedResource.where(linkable_type: 'Site', linkable_id: canonical.id).count
  end

  test 'reassign_all_to! destroys collisions on source (a Site has at most one link per source)' do
    canonical = create(:site)
    dupe      = create(:site)
    # Same source on both — dupe's row is destroyed regardless of external_id
    # (the unique index is on (linkable_type, linkable_id, source), not external_id).
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q111')
    create(:linked_resource, linkable: dupe,      source: 'Wikidata', external_id: 'Q222')

    result = LinkedResource.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 0, result[:reassigned]
    assert_equal 1, result[:destroyed_collisions]
    # Canonical's link remains
    assert_equal 1, LinkedResource.where(linkable_type: 'Site', linkable_id: canonical.id).count
    # Dupe's link is destroyed (not reassigned)
    assert_equal 0, LinkedResource.where(linkable_type: 'Site', linkable_id: dupe.id).count
  end

  test 'reassign_all_to! mixes reassignment and destruction' do
    canonical = create(:site)
    dupe      = create(:site)
    # Wikidata is on the canonical — dupe's Wikidata link (any external_id) is destroyed
    create(:linked_resource, linkable: canonical, source: 'Wikidata', external_id: 'Q111')
    create(:linked_resource, linkable: dupe,      source: 'Wikidata', external_id: 'Q222')
    # Pleiades is unique to the dupe — will be reassigned
    create(:linked_resource, linkable: dupe,      source: 'Pleiades', external_id: '333')

    result = LinkedResource.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 1, result[:destroyed_collisions]
    assert_equal 2, LinkedResource.where(linkable_type: 'Site', linkable_id: canonical.id).count
    assert_equal 0, LinkedResource.where(linkable_type: 'Site', linkable_id: dupe.id).count
  end

  test 'reassign_all_to! is a no-op when there are no linked_resources' do
    canonical = create(:site)
    dupe      = create(:site)

    assert_no_difference 'LinkedResource.count' do
      result = LinkedResource.reassign_all_to!(from: dupe, to: canonical)
      assert_equal 0, result[:reassigned]
      assert_equal 0, result[:destroyed_collisions]
    end
  end

  test 'reassign_all_to! raises when from and to are different classes' do
    site = create(:site)
    reference = create(:reference)

    assert_raises(ArgumentError) { LinkedResource.reassign_all_to!(from: site, to: reference) }
  end

  test 'reassign_all_to! raises when to is not persisted' do
    site = create(:site)
    new_site = Site.new

    assert_raises(ArgumentError) { LinkedResource.reassign_all_to!(from: site, to: new_site) }
  end

  test 'reassign_all_to! raises when from and to are the same record' do
    site = create(:site)

    assert_raises(ArgumentError) { LinkedResource.reassign_all_to!(from: site, to: site) }
  end
end
