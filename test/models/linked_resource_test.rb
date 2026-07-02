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
end
