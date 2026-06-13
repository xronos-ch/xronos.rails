require "test_helper"

class SyncTaxonWithGbifJobTest < ActiveJob::TestCase
  #
  # sets gbif_id from exact match
  #
  test "sets gbif_id from exact match" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: nil)

    match = { "matchType" => "EXACT" }
    usage = { "key" => "123", "canonicalName" => "Quercus robur" }

    GBIF::Species.stub(:match, match) do
      GBIF::Species.stub(:accepted_usage, usage) do
        SyncTaxonWithGbifJob.perform_now(taxon.id)

        assert_equal 123, taxon.reload.gbif_id
      end
    end
  end

  #
  # does not set gbif_id for non-exact match
  #
  test "does not set gbif_id for non-exact match" do
    taxon = FactoryBot.create(:taxon, name: "Quercus", gbif_id: nil)

    match = { "matchType" => "FUZZY" }

    GBIF::Species.stub(:match, match) do
      SyncTaxonWithGbifJob.perform_now(taxon.id)

      assert_nil taxon.reload.gbif_id
    end
  end

  #
  # uses accepted usage when synonym returned
  #
  test "uses accepted usage over synonym" do
    taxon = FactoryBot.create(:taxon, name: "Scirpus maritimus", gbif_id: nil)

    match = { "matchType" => "EXACT" }

    accepted = {
      "key" => "2718307",
      "canonicalName" => "Bolboschoenus maritimus"
    }

    GBIF::Species.stub(:match, match) do
      GBIF::Species.stub(:accepted_usage, accepted) do
        SyncTaxonWithGbifJob.perform_now(taxon.id)

        taxon.reload
        assert_equal 2718307, taxon.gbif_id
        assert_equal "Bolboschoenus maritimus", taxon.name
      end
    end
  end

  #
  # does nothing if accepted usage missing
  #
  test "does nothing if accepted usage missing" do
    taxon = FactoryBot.create(:taxon, name: "Unknown", gbif_id: nil)

    match = { "matchType" => "EXACT" }

    GBIF::Species.stub(:match, match) do
      GBIF::Species.stub(:accepted_usage, nil) do
        SyncTaxonWithGbifJob.perform_now(taxon.id)

        taxon.reload
        assert_nil taxon.gbif_id
        assert_equal "Unknown", taxon.name
      end
    end
  end

  #
  # enforces canonical name when gbif_id already present
  #
  test "updates name to canonical when gbif_id already present" do
    taxon = FactoryBot.create(:taxon, name: "Old name", gbif_id: "123")

    usage = {
      "key" => "123",
      "canonicalName" => "Canonical name"
    }

    GBIF::Species.stub(:usage, usage) do
      SyncTaxonWithGbifJob.perform_now(taxon.id)

      assert_equal "Canonical name", taxon.reload.name
    end
  end

  #
  # does not update name if already canonical
  #
  test "does not update name if already canonical" do
    taxon = FactoryBot.create(:taxon, name: "Canonical name", gbif_id: "123")

    usage = {
      "key" => "123",
      "canonicalName" => "Canonical name"
    }

    GBIF::Species.stub(:usage, usage) do
      SyncTaxonWithGbifJob.perform_now(taxon.id)

      assert_equal "Canonical name", taxon.reload.name
    end
  end

  #
  # handles missing taxon safely
  #
  test "does nothing when taxon not found" do
    assert_nothing_raised do
      SyncTaxonWithGbifJob.perform_now(-1)
    end
  end

  #
  # reuses match within job (no second API call)
  #
  test "reuses match when enforcing canonical name" do
    taxon = FactoryBot.create(:taxon, name: "Foo", gbif_id: nil)

    match = { "matchType" => "EXACT" }
    usage = { "key" => "42", "canonicalName" => "Bar" }

    GBIF::Species.stub(:match, match) do
      GBIF::Species.stub(:accepted_usage, usage) do
        GBIF::Species.stub(:usage, ->(*) { flunk "usage should not be called" }) do
          SyncTaxonWithGbifJob.perform_now(taxon.id)
        end
      end
    end

    assert_equal "Bar", taxon.reload.name
  end
end
