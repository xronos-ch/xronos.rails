# test/services/miaard/c14_exporter_test.rb
# frozen_string_literal: true

require "test_helper"

module Miaard
  class C14ExporterTest < ActiveSupport::TestCase
    test "exports core MIaaRD fields from a C14 record" do
      site = Site.create!(
        name: "Test Site",
        lat: 54.323,
        lng: 10.122,
        country_code: "DE"
      )

      context = Context.create!(
        name: "Test Context",
        site: site
      )

      taxon = Taxon.create!(
        name: "Homo sapiens",
        gbif_id: 2436436
      )

      sample = Sample.create!(
        context: context,
        taxon: taxon
      )

      c14 = C14.create!(
        sample: sample,
        lab_identifier: "OxA-12345",
        bp: 4500,
        std: 30,
        method: "AMS",
        delta_c13: -19.5,
        delta_c13_std: 0.2
      )

      export = C14Exporter.new(c14).as_json

      assert_equal C14Exporter::MIAARD_FIELDS, export.keys
      assert_not_includes export.keys, :delta_15_n

      assert_equal "oxa", export[:lab_code]
      assert_equal "12345", export[:lab_id]
      assert_equal 4500, export[:conventional_age]
      assert_equal 30, export[:conventional_age_error]

      assert_in_delta Math.exp(-4500.0 / C14Exporter::LIBBY_MEAN_LIFE),
                      export[:f14c],
                      0.0000001

      assert_in_delta export[:f14c] * 30.0 / C14Exporter::LIBBY_MEAN_LIFE,
                      export[:f14c_error],
                      0.0000001

      assert_nil export[:delta_13_c_calculation_method]

      assert_equal ["OxA-12345", "xronos:c14:#{c14.id}", "xronos:sample:#{sample.id}"],
                   export[:sample_ids]

      assert_nil export[:sample_material]
      assert_equal ["gbif:2436436"], export[:sample_taxon_id]
      assert_equal true, export[:sample_taxon_id_confidence]
      assert_equal "Homo sapiens", export[:sample_taxon_scientific_name]
      assert_nil export[:sample_anatomical_part]
      assert_nil export[:suspected_sample_contamination]
      assert_nil export[:suspected_sample_contamination_description]

      assert_equal "Test Site", export[:sample_location]
      assert_equal 54.323, export[:decimal_latitude]
      assert_equal 10.122, export[:decimal_longitude]
      assert_nil export[:coordinate_precision]

      assert_nil export[:pretreatment_methods]
      assert_nil export[:pretreatment_method_description]
      assert_nil export[:pretreatment_method_protocol]

      assert_equal "AMS", export[:measurement_method]

      assert_nil export[:sample_starting_weight]
      assert_nil export[:pretreatment_yield]
      assert_nil export[:pretreatment_proportion_yield]
      assert_nil export[:carbon_proportion]

      assert_equal(-19.5, export[:delta_13_c])
      assert_equal 0.2, export[:delta_13_c_error]
      assert_nil export[:delta_13_c_method]
      assert_nil export[:suspected_reservoir_effect]
    end

    test "reports MIaaRD-required fields that are unavailable in XRONOS" do
      site = Site.create!(name: "Test Site")
      context = Context.create!(site: site)
      sample = Sample.create!(context: context)

      c14 = C14.create!(
        sample: sample,
        lab_identifier: "OxA-12345",
        bp: 4500,
        std: 30
      )

      report = C14Exporter.new(c14).completeness_report

      assert_equal false, report[:valid_against_current_miaard_required_fields]
      assert_includes report[:missing_required_fields], :sample_material
      assert_includes report[:missing_required_fields], :sample_taxon_id
      assert_includes report[:missing_required_fields], :sample_taxon_id_confidence
      assert_includes report[:missing_required_fields], :pretreatment_methods
      assert_includes report[:missing_required_fields], :pretreatment_method_description
      assert_includes report[:missing_required_fields], :pretreatment_method_protocol
      assert_includes report[:missing_required_fields], :measurement_method
      assert_includes report[:missing_required_fields], :sample_starting_weight
      assert_includes report[:missing_required_fields], :pretreatment_yield
      assert_includes report[:missing_required_fields], :carbon_proportion
      assert_includes report[:missing_required_fields], :suspected_reservoir_effect

      assert_not_includes report[:missing_required_fields], :lab_code
      assert_not_includes report[:missing_required_fields], :lab_id
      assert_not_includes report[:missing_required_fields], :f14c
      assert_not_includes report[:missing_required_fields], :f14c_error
      assert_not_includes report[:missing_required_fields], :sample_ids

      assert_includes report[:derived_fields], :f14c
      assert_includes report[:derived_fields], :f14c_error
    end
  end
end