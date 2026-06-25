# == Schema Information
#
# Table name: imports
# Database name: primary
#
#  id              :bigint           not null, primary key
#  error           :text
#  records_created :jsonb
#  records_skipped :jsonb
#  success         :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source_id       :bigint           not null
#
# Indexes
#
#  index_imports_on_source_id  (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
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

  test "summary includes created counts" do
    source = build(:source, name: "my_project", version: "v1")
    import = build(:import, source: source,
                  records_created: { "site" => 3, "c14" => 5 })
    expected = "my_project (v1): 3 site, 5 c14 created"
    assert_equal expected, import.summary
  end

  test "default success is false" do
    import = Import.new
    assert_not import.success
  end
end
