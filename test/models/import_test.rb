require "test_helper"

class ImportTest < ActiveSupport::TestCase
  test "factory builds a valid import" do
    import = build(:import)
    assert import.valid?
  end

  test "requires source" do
    import = build(:import, source: nil)
    assert_not import.valid?
    assert_includes import.errors[:source], "must exist"
  end

  test "records_created_total sums values" do
    import = build(:import, records_created: { "site" => 3, "c14" => 5 })
    assert_equal 8, import.records_created_total
  end

  test "records_created_total returns 0 for empty hash" do
    import = build(:import, records_created: {})
    assert_equal 0, import.records_created_total
  end

  test "records_updated_total sums values" do
    import = build(:import, records_updated: { "site" => 2, "reference" => 1 })
    assert_equal 3, import.records_updated_total
  end

  test "records_updated_total returns 0 for empty hash" do
    import = build(:import, records_updated: {})
    assert_equal 0, import.records_updated_total
  end

  test "summary includes created and updated counts" do
    source = build(:source, name: "my_project", version: "v1")
    import = build(:import, source: source,
                  records_created: { "site" => 3, "c14" => 5 },
                  records_updated: { "site" => 1 })
    expected = "my_project (v1): 3 site, 5 c14 created, 1 site updated"
    assert_equal expected, import.summary
  end

  test "summary omits updated when empty" do
    source = build(:source, :api, name: "my_api")
    import = build(:import, source: source,
                  records_created: { "c14" => 10 },
                  records_updated: {})
    expected = "my_api: 10 c14 created"
    assert_equal expected, import.summary
  end

  test "default success is false" do
    import = Import.new
    assert_not import.success
  end
end
