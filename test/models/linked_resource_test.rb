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
#  index_linked_resources_on_linkable_type_and_linkable_id       (linkable_type,linkable_id)
#  index_linked_resources_on_polymorphic_source_and_external_id  (linkable_type,linkable_id,source,external_id) UNIQUE
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
      url_template: 'https://freeform.example/%{id}'
    begin
      linked_resource = build(:linked_resource, source: 'Freeform', external_id: 'anything goes')
      assert linked_resource.valid?
    ensure
      LinkedResource::Source.registry.delete(:freeform_source)
    end
  end
end
