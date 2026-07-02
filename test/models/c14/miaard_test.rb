# frozen_string_literal: true

require 'test_helper'

class C14
  class MIAARDTest < ActiveSupport::TestCase
    test 'exports core MIaaRD fields from a C14 record' do
      site = create(
        :site,
        name: 'Test Site',
        lat: 54.323,
        lng: 10.122,
        country_code: 'DE'
      )

      context = create(
        :context,
        name: 'Test Context',
        site: site
      )

      taxon = create(
        :taxon,
        name: 'Homo sapiens',
        gbif_id: 2_436_436
      )

      material = create(
        :material,
        name: 'Charcoal'
      )

      sample = create(
        :sample,
        context: context,
        taxon: taxon,
        material: material
      )

      c14 = create(
        :c14,
        sample: sample,
        lab_identifier: 'OxA-12345',
        bp: 4500,
        std: 30,
        method: 'AMS',
        delta_c13: -19.5,
        delta_c13_std: 0.2
      )

      export = C14::MIAARD.new(c14).to_h

      assert_equal C14::MIAARD::FIELDS, export.keys
      assert_not_includes export.keys, :delta_15_n

      assert_equal 'OxA', export[:lab_code]
      assert_equal '12345', export[:lab_id]
      assert_equal 4500, export[:conventional_age]
      assert_equal 30, export[:conventional_age_error]

      assert_in_delta c14.f14c,
                      export[:f14c],
                      0.0000001
      assert_in_delta c14.f14c_error,
                      export[:f14c_error],
                      0.0000001

      assert_nil export[:delta_13_c_calculation_method]

      assert_nil export[:sample_ids]
      assert_equal 'Charcoal', export[:sample_material]
      assert_equal 'gbif:2436436', export[:sample_taxon_id]
      assert_equal true, export[:sample_taxon_id_confidence]
      assert_equal 'Homo sapiens', export[:sample_taxon_scientific_name]
      assert_nil export[:sample_anatomical_part]
      assert_nil export[:suspected_sample_contamination]
      assert_nil export[:suspected_sample_contamination_description]

      assert_equal 'Test Site', export[:sample_location]
      assert_equal 54.323, export[:decimal_latitude]
      assert_equal 10.122, export[:decimal_longitude]
      assert_nil export[:coordinate_precision]

      assert_nil export[:pretreatment_methods]
      assert_nil export[:pretreatment_method_description]
      assert_nil export[:pretreatment_method_protocol]

      assert_equal 'AMS', export[:measurement_method]

      assert_nil export[:sample_starting_weight]
      assert_nil export[:pretreatment_yield]
      assert_nil export[:pretreatment_proportion_yield]
      assert_nil export[:carbon_proportion]

      assert_equal(-19.5, export[:delta_13_c])
      assert_equal 0.2, export[:delta_13_c_error]
      assert_nil export[:delta_13_c_method]
      assert_nil export[:suspected_reservoir_effect]
    end

    test 'collection wraps C14 records as MIAARD instances' do
      site = create(:site, name: 'Test Site')
      context = create(:context, site: site)
      sample = create(:sample, context: context)

      first = create(
        :c14,
        sample: sample,
        lab_identifier: 'OxA-12345',
        bp: 4500,
        std: 30
      )

      second = create(
        :c14,
        sample: sample,
        lab_identifier: 'Beta-67890',
        bp: 3200,
        std: 25
      )

      wrappers = C14::MIAARD.collection([first, second])

      assert_equal 2, wrappers.length
      assert_kind_of C14::MIAARD, wrappers.first
      assert_equal first, wrappers.first.source
      assert_equal 'OxA', wrappers.first.to_h[:lab_code]
      assert_equal 'Beta', wrappers.second.to_h[:lab_code]
    end
  end
end