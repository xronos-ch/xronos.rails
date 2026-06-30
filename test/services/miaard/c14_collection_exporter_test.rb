# frozen_string_literal: true

require "test_helper"

module Miaard
  class C14CollectionExporterTest < ActiveSupport::TestCase
    test "exports C14 records as MIaaRD collection entries" do
      site = Site.create!(name: "Test Site")
      context = Context.create!(site: site)
      sample = Sample.create!(context: context)

      first = C14.create!(
        sample: sample,
        lab_identifier: "OxA-12345",
        bp: 4500,
        std: 30
      )

      second = C14.create!(
        sample: sample,
        lab_identifier: "Beta-67890",
        bp: 3200,
        std: 25
      )

      export = C14CollectionExporter.new([first, second]).as_json

      assert_equal [:entries], export.keys
      assert_equal 2, export[:entries].length
      assert_equal "oxa", export[:entries].first[:lab_code]
      assert_equal "beta", export[:entries].second[:lab_code]
    end
  end
end