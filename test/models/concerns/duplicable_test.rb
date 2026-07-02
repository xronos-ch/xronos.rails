require "test_helper"

class DuplicableTest < ActiveSupport::TestCase
  # Use a disposable subclass so we can exercise the option syntax without
  # permanently changing the production Site declaration.
  class OptionTestSite < Site
    def self.duplicable_attrs
      @@duplicable_attrs
    end

    def self.duplicable_attrs_without_options
      @@duplicable_attrs.map { |x| x.is_a?(Hash) ? x.keys : x }.flatten
    end

    def self.duplicable_attrs_with_options
      @@duplicable_attrs.filter { |x| x.is_a?(Hash) }.reduce({}, :merge)
    end

    def self.reset_duplicable_attrs!
      @@duplicable_attrs = []
    end
  end

  setup do
    OptionTestSite.reset_duplicable_attrs!
  end

  test "duplicable_attrs returns the declared list" do
    OptionTestSite.duplicable :name, :country_code
    assert_equal [:name, :country_code], OptionTestSite.duplicable_attrs
  end

  test "duplicable_attrs_without_options flattens hashes to symbol names" do
    OptionTestSite.duplicable :name, { country_code: [:null] }
    assert_equal [:name, :country_code], OptionTestSite.duplicable_attrs_without_options
  end

  test "duplicable_attrs_with_options merges hash declarations into one map" do
    OptionTestSite.duplicable :name, { country_code: [:null] }
    assert_equal({ country_code: [:null] }, OptionTestSite.duplicable_attrs_with_options)
  end

  test "duplicates intersects (AND) filters across declared attributes" do
    OptionTestSite.duplicable :name, :country_code
    site = create(:site, name: "MATCH-NAME", country_code: "DE")
    # Matches both :name and :country_code — should be in duplicates.
    both = create(:site, name: "MATCH-NAME", country_code: "DE")
    # Matches only :name.
    create(:site, name: "MATCH-NAME", country_code: "FR")
    # Matches only :country_code.
    create(:site, name: "OTHER", country_code: "DE")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, both
    assert_equal 2, duplicates.count
  end

  test "duplicates with :whitespace option matches records with whitespace substituted by %" do
    OptionTestSite.duplicable({ name: [:whitespace] })
    # Source value contains whitespace; the filter substitutes each space with %.
    site = create(:site, name: "Camel Case")
    # Target has a literal % where the source had whitespace, so it matches the pattern.
    matching = create(:site, name: "Camel%Case")
    # No space and no % — should NOT match the Camel-Case pattern.
    nonmatch = create(:site, name: "XyZ")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, nonmatch
  end

  test "duplicates with :mojibake option matches records with non-ASCII substituted by %" do
    OptionTestSite.duplicable({ name: [:mojibake] })
    # Source value contains non-ASCII; the filter substitutes it with %.
    site = create(:site, name: "Cöthen")
    # Target has a literal % where the source had ö, so it matches the pattern.
    matching = create(:site, name: "C%then")
    # No non-ASCII and no % — should NOT match the Cöthen pattern.
    nonmatch = create(:site, name: "Abc")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, nonmatch
  end

  test "duplicates with :ci option matches records case-insensitively" do
    OptionTestSite.duplicable({ name: [:ci] })
    site = create(:site, name: "UPPERCASE")
    matching = create(:site, name: "uppercase")
    nonmatch = create(:site, name: "Different")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, nonmatch
  end

  test "duplicates with :null option finds records with attr IS NULL for non-nil attr" do
    OptionTestSite.duplicable({ country_code: [:null] })
    site = create(:site, country_code: "DE")
    null_country = create(:site, country_code: nil)
    create(:site, country_code: "FR")

    assert_includes site.duplicates, null_country
  end

  test "duplicates with :null option finds records with attr IS NOT NULL for nil attr" do
    OptionTestSite.duplicable({ country_code: [:null] })
    null_site = create(:site, country_code: nil)
    non_null_site = create(:site, country_code: "DE")

    assert_includes null_site.duplicates, non_null_site
  end

  test "duplicates raises on unknown options" do
    OptionTestSite.duplicable({ name: [:bogus] })
    site = create(:site)

    assert_raises(RuntimeError) { site.duplicates }
  end

  test "exact_duplicates finds records with identical values for all attributes" do
    OptionTestSite.duplicable :name, { country_code: [:ci] }
    site = create(:site, name: "SameName", country_code: "DE")
    # Same values exactly — should be found by exact_duplicates.
    exact = create(:site, name: "SameName", country_code: "DE")
    # Case-different on country_code — should NOT be found by exact_duplicates,
    # only by the option-aware duplicates path.
    create(:site, name: "SameName", country_code: "de")

    assert_includes site.exact_duplicates, exact
    assert_equal 2, site.exact_duplicates.count
  end

  test "is_duplicated? returns true when exact duplicates exist" do
    OptionTestSite.duplicable :name
    site = create(:site, name: "DupName")
    create(:site, name: "DupName")
    create(:site, name: "Other")

    assert site.is_duplicated?
  end

  test "is_duplicated? returns false when no exact duplicates exist" do
    OptionTestSite.duplicable :name
    create(:site, name: "Unique1")
    create(:site, name: "Unique2")

    refute Site.first.is_duplicated?
  end
end
