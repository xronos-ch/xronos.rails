# == Schema Information
#
# Table name: sources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  access_date   :date
#  file_manifest :jsonb
#  license       :string
#  name          :string           not null
#  notes         :text
#  path          :text
#  source_url    :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  reference_id  :bigint
#
# Indexes
#
#  index_sources_on_name_and_version  (name,version) UNIQUE WHERE (version IS NOT NULL)
#  index_sources_on_reference_id      (reference_id)
#
# Foreign Keys
#
#  fk_rails_...  (reference_id => references.id)
#
require "test_helper"
require "tempfile"
require "csv"

class SourceTest < ActiveSupport::TestCase
  test "factory builds a valid source" do
    source = build(:source)
    assert source.valid?
  end

  test "requires name" do
    source = build(:source, name: nil)
    assert_not source.valid?
    assert_includes source.errors[:name], "can't be blank"
  end

  test "name must be unique per version" do
    create(:source, name: "my_project", version: "v1")
    duplicate = build(:source, name: "my_project", version: "v1")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "same name allowed for different versions" do
    create(:source, name: "my_project", version: "v1")
    other = build(:source, name: "my_project", version: "v2")
    assert other.valid?
  end

  test "same name allowed without version (API sources)" do
    create(:source, name: "my_project", version: "v1")
    api = build(:source, :api, name: "my_project")
    assert api.valid?
  end

  test "label includes version when present" do
    source = build(:source, name: "my_project", version: "v1")
    assert_equal "my_project (v1)", source.label
  end

  test "label omits version when absent" do
    source = build(:source, :api, name: "my_api")
    assert_equal "my_api", source.label
  end

  test "cannot destroy source with imports" do
    source = create(:source)
    create(:import, source: source)
    assert_not source.destroy
    assert_includes source.errors[:base], "Cannot delete record because dependent imports exist"
  end

  # --- .register ---

  test "register creates a new source with file manifest" do
    Dir.mktmpdir do |dir|
      write_csv(dir, "sites.csv", [%w[Name], %w[Alpha]])

      source = Source.register(name: "test", version: "v1", path: dir)

      assert source.persisted?
      assert_equal "test", source.name
      assert_equal "v1", source.version
      assert_equal dir, source.path
      assert source.file_manifest.key?("sites.csv")
    end
  end

  test "register sets metadata when creating" do
    Dir.mktmpdir do |dir|
      source = Source.register(
        name: "test", version: "v1", path: dir,
        source_url: "https://example.org",
        license: "CC-BY 4.0",
        access_date: Date.new(2026, 6, 24),
        notes: "Some notes"
      )

      assert_equal "https://example.org", source.source_url
      assert_equal "CC-BY 4.0", source.license
      assert_equal Date.new(2026, 6, 24), source.access_date
      assert_equal "Some notes", source.notes
    end
  end

  test "register with empty directory creates source with empty manifest" do
    Dir.mktmpdir do |dir|
      source = Source.register(name: "test", version: "v1", path: dir)
      assert_equal({}, source.file_manifest)
    end
  end

  test "register finds existing source with matching files" do
    Dir.mktmpdir do |dir|
      write_csv(dir, "sites.csv", [%w[Name], %w[Alpha]])
      original = Source.register(name: "test", version: "v1", path: dir)

      found = Source.register(name: "test", version: "v1", path: dir)

      assert_equal original.id, found.id
      assert_equal original.file_manifest, found.reload.file_manifest
    end
  end

  test "register updates path on existing source" do
    Dir.mktmpdir do |old_dir|
      write_csv(old_dir, "sites.csv", [%w[Name], %w[Alpha]])
      Source.register(name: "test", version: "v1", path: old_dir)

      Dir.mktmpdir do |new_dir|
        # Same files, different directory
        write_csv(new_dir, "sites.csv", [%w[Name], %w[Alpha]])
        source = Source.register(name: "test", version: "v1", path: new_dir)

        assert_equal new_dir, source.reload.path
      end
    end
  end

  test "register aborts on changed files" do
    Dir.mktmpdir do |dir|
      write_csv(dir, "sites.csv", [%w[Name], %w[Alpha]])
      Source.register(name: "test", version: "v1", path: dir)

      # Change the file content
      write_csv(dir, "sites.csv", [%w[Name], %w[Beta]])

      assert_raises(SystemExit) do
        Source.register(name: "test", version: "v1", path: dir)
      end
    end
  end

  private

  def write_csv(dir, filename, rows)
    path = File.join(dir, filename)
    CSV.open(path, "w") do |csv|
      rows.each { |row| csv << row }
    end
  end
end
