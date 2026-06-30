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

  test 'qcode returns Q-prefixed external id' do
    linked_resource = build(:linked_resource, external_id: 12_345)
    assert_equal 'Q12345', linked_resource.qcode
  end

  test 'external_url returns the registered URL for a known source' do
    linked_resource = build(:linked_resource, source: 'Wikidata', external_id: 12_345)
    assert_equal 'https://www.wikidata.org/wiki/Q12345', linked_resource.external_url
  end

  test 'external_url returns nil for an unknown source' do
    linked_resource = build(:linked_resource, source: 'OpenStreetMap', external_id: 12_345)
    assert_nil linked_resource.external_url
  end
end
