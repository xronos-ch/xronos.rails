require "test_helper"

class DuplicableTest < ActiveSupport::TestCase
  # Disposable subclass to exercise options without changing production.
  class OptionTestSite < Site
  end

  setup do
    OptionTestSite._duplicable_attrs_list = []
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
    site = OptionTestSite.create!(name: "MATCH-NAME", country_code: "DE")
    both = OptionTestSite.create!(name: "MATCH-NAME", country_code: "DE")
    OptionTestSite.create!(name: "MATCH-NAME", country_code: "FR")
    OptionTestSite.create!(name: "OTHER", country_code: "DE")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, both
    assert_equal 2, duplicates.count
  end

  test "duplicates with :whitespace option matches records with whitespace substituted by %" do
    OptionTestSite.duplicable({ name: [:whitespace] })
    site = OptionTestSite.create!(name: "Camel Case")
    matching = OptionTestSite.create!(name: "Camel%Case")
    OptionTestSite.create!(name: "XyZ")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, OptionTestSite.find_by(name: "XyZ")
  end

  test "duplicates with :mojibake option matches records with non-ASCII substituted by %" do
    OptionTestSite.duplicable({ name: [:mojibake] })
    site = OptionTestSite.create!(name: "Cöthen")
    matching = OptionTestSite.create!(name: "C%then")
    OptionTestSite.create!(name: "Abc")

    duplicates = site.duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, OptionTestSite.find_by(name: "Abc")
  end

  test "duplicates with :ci option matches records case-insensitively" do
    OptionTestSite.duplicable({ name: [:ci] })
    site = OptionTestSite.create!(name: "UPPERCASE")
    OptionTestSite.create!(name: "uppercase")
    OptionTestSite.create!(name: "Different")

    duplicates = site.duplicates.distinct
    assert_equal 2, duplicates.count
    assert_not_includes duplicates, OptionTestSite.find_by(name: "Different")
  end

  test "duplicates with :null option finds records with attr IS NULL for non-nil attr" do
    OptionTestSite.duplicable({ country_code: [:null] })
    site = OptionTestSite.create!(name: "Site1", country_code: "DE")
    null_country = OptionTestSite.create!(name: "Site2", country_code: nil)
    OptionTestSite.create!(name: "Site3", country_code: "FR")

    assert_includes site.duplicates, null_country
  end

  test "duplicates with :null option finds records with attr IS NOT NULL for nil attr" do
    OptionTestSite.duplicable({ country_code: [:null] })
    null_site = OptionTestSite.create!(name: "Site1", country_code: nil)
    non_null_site = OptionTestSite.create!(name: "Site2", country_code: "DE")

    assert_includes null_site.duplicates, non_null_site
  end

  test "duplicates raises on unknown options" do
    OptionTestSite.duplicable({ name: [:bogus] })
    site = OptionTestSite.create!(name: "Site1")

    assert_raises(RuntimeError) { site.duplicates }
  end

  test "exact_duplicates finds records with identical values for all attributes" do
    OptionTestSite.duplicable :name, { country_code: [:ci] }
    site = OptionTestSite.create!(name: "SameName", country_code: "DE")
    exact = OptionTestSite.create!(name: "SameName", country_code: "DE")
    OptionTestSite.create!(name: "SameName", country_code: "de")

    assert_includes site.exact_duplicates, exact
    assert_equal 2, site.exact_duplicates.count
  end

  test "is_duplicated? returns true when exact duplicates exist" do
    OptionTestSite.duplicable :name
    site = OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "Other")

    assert site.is_duplicated?
  end

  test "is_duplicated? returns false when no exact duplicates exist" do
    OptionTestSite.duplicable :name
    OptionTestSite.create!(name: "Unique1")
    OptionTestSite.create!(name: "Unique2")

    refute OptionTestSite.first.is_duplicated?
  end
end
