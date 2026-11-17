require "test_helper"

class DuplicableTest < ActiveSupport::TestCase
  # Disposable subclass to exercise options without changing production.
  class OptionTestSite < Site
  end

  setup do
    OptionTestSite.exact_duplicates_attrs_list.clear
    OptionTestSite.potential_duplicates_attrs_list.clear
    # Disable the Mergeable auto-merge callback (inherited from Site)
    # for this test subclass — these tests assert that records with
    # identical keys remain in the database.
    OptionTestSite.skip_callback(:save, :after, :merge_exact_duplicates)
    # Same rationale for `validate :no_exact_duplicate, on: :create`
    # declared on Site: the tests deliberately create pairs of records
    # that share every exact-duplicate key.
    OptionTestSite.skip_callback(:validate, :before, :no_exact_duplicate, on: :create)
  end

  teardown do
    # Re-enable the callback for other tests in the suite.
    OptionTestSite.set_callback(:save, :after, :merge_exact_duplicates)
    OptionTestSite.set_callback(:validate, :before, :no_exact_duplicate, on: :create)
  end

  #
  # Exact duplicates
  #

  test "exact_duplicates_on stores attribute names" do
    OptionTestSite.exact_duplicates_on :name, :country_code
    assert_equal [:name, :country_code], OptionTestSite.exact_duplicates_attrs
  end

  test "exact_duplicates finds records with identical values" do
    OptionTestSite.exact_duplicates_on :name, :country_code
    a = OptionTestSite.create!(name: "Same", country_code: "DE")
    b = OptionTestSite.create!(name: "Same", country_code: "DE")
    OptionTestSite.create!(name: "Same", country_code: "FR")
    OptionTestSite.create!(name: "Other", country_code: "DE")

    assert_includes a.exact_duplicates, b
  end

  test "exact_duplicates default: nil != nil" do
    OptionTestSite.exact_duplicates_on :name, :country_code
    a = OptionTestSite.create!(name: "Same", country_code: nil)
    b = OptionTestSite.create!(name: "Same", country_code: nil)

    # nil != nil: the two records are not considered duplicates.
    assert_not_includes a.exact_duplicates, b
  end

  test "exact_duplicates matches nil values for nil_matches_nil attributes" do
    OptionTestSite.exact_duplicates_on :name, { country_code: [:nil_matches_nil] }
    a = OptionTestSite.create!(name: "Same", country_code: nil)
    b = OptionTestSite.create!(name: "Same", country_code: nil)
    OptionTestSite.create!(name: "Same", country_code: "DE")

    assert_includes a.exact_duplicates, b
  end

  test "exact_duplicates still distinguishes nil from non-nil for nil_matches_nil" do
    OptionTestSite.exact_duplicates_on :name, { country_code: [:nil_matches_nil] }
    a = OptionTestSite.create!(name: "Same", country_code: nil)
    OptionTestSite.create!(name: "Same", country_code: "DE")

    # nil matches nil, but nil does NOT match a non-nil value.
    # `a` (country_code: nil) has no other nil-country_code sibling, so count is 0.
    assert_equal 0, a.exact_duplicates.count
  end

  test "exact_duplicates: attributes without nil_matches_nil still use nil != nil" do
    # Use a model without name validation so we can test nil names.
    test_class = Class.new(ApplicationRecord) do
      self.table_name = 'sites'
      include Duplicable
    end
    test_class.exact_duplicates_attrs_list.clear
    test_class.exact_duplicates_on :name, { country_code: [:nil_matches_nil] }

    a = test_class.create!(name: "Same", country_code: "DE")
    b = test_class.create!(name: "Same", country_code: "DE")
    nil_a = test_class.new(name: nil, country_code: "DE")
    nil_a.save(validate: false)
    nil_b = test_class.new(name: nil, country_code: "DE")
    nil_b.save(validate: false)

    # Two records with matching non-nil values ARE duplicates.
    assert_includes a.exact_duplicates, b
    # Two records with nil :name (no nil_matches_nil opt-in) are NOT duplicates.
    assert_not_includes nil_a.exact_duplicates, nil_b
  end

  test "find_exact_duplicate default: returns nil when an attribute is nil" do
    OptionTestSite.exact_duplicates_on :name, :country_code
    OptionTestSite.create!(name: "Same", country_code: nil)
    OptionTestSite.create!(name: "Same", country_code: nil)

    record = OptionTestSite.find_by(name: "Same", country_code: nil)
    assert_nil record.find_exact_duplicate
  end

  test "find_exact_duplicate returns matching record for nil_matches_nil" do
    OptionTestSite.exact_duplicates_on :name, { country_code: [:nil_matches_nil] }
    a = OptionTestSite.create!(name: "Same", country_code: nil)
    OptionTestSite.create!(name: "Same", country_code: nil)

    other = OptionTestSite.where.not(id: a.id).first
    assert_equal other.id, a.find_exact_duplicate.id
  end

  test "is_exact_duplicate? returns true when exact duplicates exist" do
    OptionTestSite.exact_duplicates_on :name
    site = OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "Other")

    assert site.is_exact_duplicate?
  end

  test "is_exact_duplicate? returns false when no exact duplicates exist" do
    OptionTestSite.exact_duplicates_on :name
    OptionTestSite.create!(name: "Unique1")
    OptionTestSite.create!(name: "Unique2")

    refute OptionTestSite.first.is_exact_duplicate?
  end

  #
  # Potential duplicates
  #

  test "potential_duplicates_on stores attribute names and options" do
    OptionTestSite.potential_duplicates_on :name, { country_code: [:null] }
    assert_equal [:name, :country_code], OptionTestSite.potential_duplicates_attrs
    assert_equal({ country_code: [:null] }, OptionTestSite.potential_duplicates_attrs_with_options)
  end

  test "potential_duplicates intersects (AND) filters across declared attributes" do
    OptionTestSite.potential_duplicates_on :name, :country_code
    site = OptionTestSite.create!(name: "MATCH-NAME", country_code: "DE")
    both = OptionTestSite.create!(name: "MATCH-NAME", country_code: "DE")
    OptionTestSite.create!(name: "MATCH-NAME", country_code: "FR")
    OptionTestSite.create!(name: "OTHER", country_code: "DE")

    duplicates = site.potential_duplicates.distinct
    assert_includes duplicates, both
    assert_equal 2, duplicates.count
  end

  test "potential_duplicates with :whitespace option matches records with whitespace substituted by %" do
    OptionTestSite.potential_duplicates_on({ name: [:whitespace] })
    site = OptionTestSite.create!(name: "Camel Case")
    matching = OptionTestSite.create!(name: "Camel%Case")
    OptionTestSite.create!(name: "XyZ")

    duplicates = site.potential_duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, OptionTestSite.find_by(name: "XyZ")
  end

  test "potential_duplicates with :mojibake option matches records with non-ASCII substituted by %" do
    OptionTestSite.potential_duplicates_on({ name: [:mojibake] })
    site = OptionTestSite.create!(name: "Cöthen")
    matching = OptionTestSite.create!(name: "C%then")
    OptionTestSite.create!(name: "Abc")

    duplicates = site.potential_duplicates.distinct
    assert_includes duplicates, matching
    assert_not_includes duplicates, OptionTestSite.find_by(name: "Abc")
  end

  test "potential_duplicates with :ci option matches records case-insensitively" do
    OptionTestSite.potential_duplicates_on({ name: [:ci] })
    site = OptionTestSite.create!(name: "UPPERCASE")
    OptionTestSite.create!(name: "uppercase")
    OptionTestSite.create!(name: "Different")

    duplicates = site.potential_duplicates.distinct
    assert_equal 2, duplicates.count
    assert_not_includes duplicates, OptionTestSite.find_by(name: "Different")
  end

  test "potential_duplicates with :null option finds records with attr IS NULL for non-nil attr" do
    OptionTestSite.potential_duplicates_on({ country_code: [:null] })
    site = OptionTestSite.create!(name: "Site1", country_code: "DE")
    null_country = OptionTestSite.create!(name: "Site2", country_code: nil)
    OptionTestSite.create!(name: "Site3", country_code: "FR")

    assert_includes site.potential_duplicates, null_country
  end

  test "potential_duplicates with :null option finds records with attr IS NOT NULL for nil attr" do
    OptionTestSite.potential_duplicates_on({ country_code: [:null] })
    null_site = OptionTestSite.create!(name: "Site1", country_code: nil)
    non_null_site = OptionTestSite.create!(name: "Site2", country_code: "DE")

    assert_includes null_site.potential_duplicates, non_null_site
  end

  test "potential_duplicates raises on unknown options" do
    OptionTestSite.potential_duplicates_on({ name: [:bogus] })
    site = OptionTestSite.create!(name: "Site1")

    assert_raises(RuntimeError) { site.potential_duplicates }
  end

  test "is_potential_duplicate? returns true when potential duplicates exist" do
    OptionTestSite.potential_duplicates_on :name
    site = OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "DupName")
    OptionTestSite.create!(name: "Other")

    assert site.is_potential_duplicate?
  end

  test "is_potential_duplicate? returns false when no potential duplicates exist" do
    OptionTestSite.potential_duplicates_on :name
    OptionTestSite.create!(name: "Unique1")
    OptionTestSite.create!(name: "Unique2")

    refute OptionTestSite.first.is_potential_duplicate?
  end

  #
  # match_conditions — SQL form of the per-attr nil-handling rule
  # (see `attr_matches?`).
  #

  test "match_conditions emits IS NOT DISTINCT FROM for :nil_matches_nil attrs" do
    OptionTestSite.exact_duplicates_on :name, country_code: :nil_matches_nil
    quote = ->(c) { c } # pass-through so the assertion is readable

    conds = OptionTestSite.match_conditions(
      attrs: [:name, :country_code], current_alias: 'c1', other_alias: 'c2', quote: quote
    )

    assert_equal ['c2.name = c1.name AND c1.name IS NOT NULL',
                  'c2.country_code IS NOT DISTINCT FROM c1.country_code'], conds
  end
end
