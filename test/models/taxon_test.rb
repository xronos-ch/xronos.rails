# == Schema Information
#
# Table name: taxons
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  gbif_id    :integer
#
# Indexes
#
#  index_taxons_on_gbif_id  (gbif_id)
#  index_taxons_on_name     (name)
#
require "test_helper"

class TaxonTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
  end

  #
  # VALIDATIONS
  #
  test "is invalid without a name" do
    taxon = Taxon.new(name: nil)
    assert_not taxon.valid?
  end

  #
  # CALLBACK: enqueue job on create
  #
  test "enqueues GBIF sync on create with name" do
    assert_enqueued_with(job: SyncTaxonWithGbifJob) do
      Taxon.create!(name: "Quercus robur")
    end
  end

  #
  # CALLBACK: enqueue job on update
  #
  test "enqueues GBIF sync on update" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur")

    clear_enqueued_jobs

    assert_enqueued_with(job: SyncTaxonWithGbifJob) do
      taxon.update!(name: "Fagus sylvatica")
    end
  end

  #
  # CALLBACK GUARD
  #
  test "does not enqueue when name and gbif_id are blank" do
    assert_no_enqueued_jobs do
      taxon = Taxon.new(name: nil, gbif_id: nil)
      assert_not taxon.save
    end
  end

  #
  # CALLBACK: gbif_id present even without name
  #
  test "enqueues when gbif_id present even if name blank" do
    taxon = Taxon.new(name: nil, gbif_id: 123)

    # bypass validation to isolate callback behaviour
    taxon.save(validate: false)

    assert_enqueued_with(job: SyncTaxonWithGbifJob)
  end

  #
  # gbif_id? helper
  #
  test "gbif_id? returns true when present" do
    taxon = Taxon.new(name: "Test", gbif_id: 123)
    assert taxon.gbif_id?
  end

  test "gbif_id? returns false when blank" do
    taxon = Taxon.new(name: "Test", gbif_id: nil)
    assert_not taxon.gbif_id?
  end

  #
  # usage
  #
  test "usage returns TaxonUsage when gbif_id present" do
    taxon = Taxon.new(name: "Test", gbif_id: 2877951)

    usage = taxon.usage

    assert_instance_of TaxonUsage, usage
    assert_equal 2877951, usage.id
  end

  test "usage returns nil when gbif_id blank" do
    taxon = Taxon.new(name: "Test", gbif_id: nil)
    assert_nil taxon.usage
  end

  #
  # unknown_taxon
  #
  test "unknown_taxon? true when gbif_id nil" do
    taxon = Taxon.new(name: "Test", gbif_id: nil)
    assert taxon.unknown_taxon?
  end

  test "unknown_taxon? false when gbif_id present" do
    taxon = Taxon.new(name: "Test", gbif_id: 123)
    assert_not taxon.unknown_taxon?
  end

  test "unknown_taxon scope returns only records without gbif_id" do
    t1 = FactoryBot.create(:taxon, gbif_id: nil)
    t2 = FactoryBot.create(:taxon, gbif_id: 123)

    assert_includes Taxon.unknown_taxon, t1
    assert_not_includes Taxon.unknown_taxon, t2
  end

  #
  # long_taxon
  #
  test "long_taxon? true when name longer than 64 chars" do
    taxon = Taxon.new(name: "a" * 65)
    assert taxon.long_taxon?
  end

  test "long_taxon? false when name short" do
    taxon = Taxon.new(name: "Quercus robur")
    assert_not taxon.long_taxon?
  end

  test "long_taxon scope returns only long names" do
    short = FactoryBot.create(:taxon, name: "Short name")
    long  = FactoryBot.create(:taxon, name: "a" * 65)

    assert_includes Taxon.long_taxon, long
    assert_not_includes Taxon.long_taxon, short
  end

  #
  # destroy_if_orphaned
  #
  test "destroy_if_orphaned destroys taxon with no samples" do
    taxon = FactoryBot.create(:taxon)

    assert_difference("Taxon.count", -1) do
      taxon.destroy_if_orphaned
    end
  end

  test "destroy_if_orphaned does not destroy if samples exist" do
    taxon = FactoryBot.create(:taxon)
    FactoryBot.create(:sample, taxon: taxon)

    assert_no_difference("Taxon.count") do
      taxon.destroy_if_orphaned
    end
  end

  #
  # Search
  #
  test ".search_with_gbif combines local and gbif results" do
    local = FactoryBot.build_stubbed(:taxon, name: "Localus taxon", gbif_id: 1)

    gbif_response = {
      "results" => [
        { "canonicalName" => "Gbifus taxon", "key" => 2 }
      ]
    }

    Taxon.stub(:search, [local]) do
      GBIF::Species.stub(:search, gbif_response) do
        results = Taxon.search_with_gbif("test")

        assert_equal 2, results.length
        assert_includes results.map(&:name), "Localus taxon"
        assert_includes results.map(&:name), "Gbifus taxon"
      end
    end
  end

  test ".search_with_gbif deduplicates by gbif_id" do
    local = FactoryBot.build_stubbed(:taxon, name: "Same", gbif_id: 1)

    gbif_response = {
      "results" => [
        { "canonicalName" => "Same", "key" => 1 }
      ]
    }

    Taxon.stub(:search, [local]) do
      GBIF::Species.stub(:search, gbif_response) do
        results = Taxon.search_with_gbif("test")

        assert_equal 1, results.length
      end
    end
  end

  test ".search_with_gbif deduplicates by name when gbif_id is nil" do
    local = FactoryBot.build_stubbed(:taxon, name: "Quercus robur", gbif_id: nil)

    gbif_response = {
      "results" => [
        { "canonicalName" => "Quercus robur", "key" => nil }
      ]
    }

    Taxon.stub(:search, [local]) do
      GBIF::Species.stub(:search, gbif_response) do
        results = Taxon.search_with_gbif("Quercus robur")

        # Only one result despite duplicate from GBIF + local
        assert_equal 1, results.count { |t| t.name == "Quercus robur" }
      end
    end
  end

  test ".search_with_gbif builds unsaved Taxon objects from gbif results" do
    gbif_response = {
      "results" => [
        {
          "canonicalName" => "Fagus sylvatica",
          "key" => 12345
        }
      ]
    }

    Taxon.stub(:search, []) do
      GBIF::Species.stub(:search, gbif_response) do
        results = Taxon.search_with_gbif("Fagus")

        result = results.find { |t| t.name == "Fagus sylvatica" }

        assert_not_nil result
        assert_equal 12345, result.gbif_id

        # Ensure no record was persisted
        assert_predicate result, :new_record?
        assert_not Taxon.exists?(name: "Fagus sylvatica")
      end
    end
  end

  test ".search_with_gbif returns empty array when no matches" do
    Taxon.stub(:search, []) do
      GBIF::Species.stub(:search, { "results" => [] }) do
        results = Taxon.search_with_gbif("test")

        assert_equal [], results
      end
    end
  end

  test ".search_with_gbif returns empty array for blank query" do
    assert_equal [], Taxon.search_with_gbif(nil)
    assert_equal [], Taxon.search_with_gbif("")
  end

  test ".search_with_gbif excludes unknown taxa when matched_only is true" do
    matched   = FactoryBot.build_stubbed(:taxon, name: "Matched", gbif_id: 1)
    unmatched = FactoryBot.build_stubbed(:taxon, name: "Unmatched", gbif_id: nil)

    gbif_response = { "results" => [] }

    Taxon.stub(:search, [matched, unmatched]) do
      GBIF::Species.stub(:search, gbif_response) do
        results = Taxon.search_with_gbif("test", matched_only: true)

        names = results.map(&:name)

        assert_includes names, "Matched"
        assert_not_includes names, "Unmatched"
      end
    end
  end

end

