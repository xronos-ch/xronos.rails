require "test_helper"
require "stringio"
require "tempfile"
require "csv"

class Xronos::ImportRunnerTest < ActiveSupport::TestCase
  setup do
    @source = create(:source)
    @csv_dir = Dir.mktmpdir
    @output = StringIO.new
  end

  teardown do
    FileUtils.remove_entry(@csv_dir)
  end

  test "creates import record with success false" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    assert_equal false, runner.import_record.success
    assert_equal @source, runner.import_record.source
  end

  test "csv yields rows from file in csv_dir" do
    write_csv("sites.csv", [%w[Name Lat], %w[Alpha 10.5], %w[Beta 20.3]])

    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    rows = []
    runner.csv("sites.csv") { |row| rows << row.to_h }

    assert_equal 2, rows.size
    assert_equal "Alpha", rows[0]["Name"]
    assert_equal "10.5", rows[0]["Lat"]
  end

  test "csv raises on missing file" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    assert_raises(Errno::ENOENT) { runner.csv("nonexistent.csv").each { } }
  end

  test "csv processes all rows with progress bar" do
    write_csv("sites.csv", [%w[Name], %w[A], %w[B], %w[C]])

    rows = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.csv("sites.csv") { |row| rows << row.to_h }

    assert_equal 3, rows.size
  end

  test "csv accepts options like col_sep and encoding" do
    path = File.join(@csv_dir, "semicolons.csv")
    CSV.open(path, "w", col_sep: ";") do |csv|
      csv << ["Name", "Age"]
      csv << ["Alpha", "10"]
      csv << ["Beta", "20"]
    end

    rows = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.csv("semicolons.csv", col_sep: ";") { |row| rows << row.to_h }

    assert_equal 2, rows.size
    assert_equal "Alpha", rows[0]["Name"]
    assert_equal "10", rows[0]["Age"]
  end

  test "increment_created increments per model" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.increment_created(:site)
    runner.increment_created(:c14)
    runner.increment_created(:site)

    assert_equal 2, runner.import_record.records_created["site"]
    assert_equal 1, runner.import_record.records_created["c14"]
  end

  test "succeed! sets success to true" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.succeed!
    assert runner.import_record.success
  end

  test "succeed! persists counters" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.increment_created(:site)
    runner.increment_created(:c14)
    runner.succeed!

    runner.import_record.reload
    assert_equal 1, runner.import_record.records_created["site"]
    assert_equal 1, runner.import_record.records_created["c14"]
    assert runner.import_record.success
  end

  test "cell strips whitespace and returns nil for blank" do
    row = CSV::Row.new(%w[a b c], ["  hello  ", "", "   "])

    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

    assert_equal "hello", runner.cell(row, "a")
    assert_nil runner.cell(row, "b")
    assert_nil runner.cell(row, "c")
  end

  test "process_enum yields items with progress bar" do
    items = %w[a b c]
    yielded = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.process_enum(items, title: "letters") { |item| yielded << item }
    assert_equal %w[a b c], yielded
  end

  test "import! creates a record and increments counter" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    site = runner.import!(Site, keys: { name: "Alpha" },
      attributes: { lat: "10.5", country_code: "ES" })

    assert site.persisted?
    assert_equal "Alpha", site.name
    assert_equal BigDecimal("10.5"), site.lat
    assert_equal "ES", site.country_code
    assert_equal 1, runner.import_record.records_created["site"]
  end

  test "import! creates new records for attribute variations" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

    site_a = runner.import!(Site, keys: { name: "Alpha" },
      attributes: { lat: "10.5", lng: "20.3", country_code: "ES" })
    site_b = runner.import!(Site, keys: { name: "Alpha" },
      attributes: { lat: "99.9", lng: "88.8", country_code: "PT" })

    assert_not_equal site_a.id, site_b.id
    assert_equal 2, runner.import_record.records_created["site"]
  end

  test "import! does not create duplicates for identical data" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

    site_a = runner.import!(Site, keys: { name: "Alpha" },
      attributes: { lat: "10.5", lng: "20.3", country_code: "ES" })
    site_b = runner.import!(Site, keys: { name: "Alpha" },
      attributes: { lat: "10.5", lng: "20.3", country_code: "ES" })

    assert_equal site_a.id, site_b.id
    assert_equal 1, runner.import_record.records_created["site"]
  end

  test "import! works with association scope" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    site = create(:site, name: "Test")

    context = runner.import!(site.contexts,
      keys: { name: "Trench A" },
      revision_comment: "import"
    )

    assert context.persisted?
    assert_equal site, context.site
    assert_equal 1, runner.import_record.records_created["context"]
  end

  test "import! works without attributes" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

    material = runner.import!(Material, keys: { name: "Wood" })

    assert material.persisted?
    assert_equal "Wood", material.name
    assert_equal 1, runner.import_record.records_created["material"]
  end

  test "import! does not require revision_comment on models without Versioned" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    material = runner.import!(Material, keys: { name: "Bone" })
    assert material.persisted?
  end

  test "import record is persisted immediately" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    assert_predicate runner.import_record, :persisted?
    assert_not runner.import_record.success
  end

  test "skip_unless skips row in csv block and counts reason" do
    write_csv("samples.csv", [%w[Name BP], %w[Alpha 100], %w[Beta], %w[Gamma 200]])

    kept = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.csv("samples.csv") do |row|
      skip_unless cell(row, "BP"), "missing BP"
      kept << cell(row, "Name")
    end

    assert_equal %w[Alpha Gamma], kept
    assert_equal 1, runner.import_record.records_skipped["missing BP"]
  end

  test "skip_unless skips row in process_enum block and counts reason" do
    items = [{name: "A", val: "1"}, {name: "B", val: ""}, {name: "C", val: "3"}]

    kept = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.process_enum(items, title: "test") do |item|
      skip_unless item[:val].present?, "blank val"
      kept << item[:name]
    end

    assert_equal %w[A C], kept
    assert_equal 1, runner.import_record.records_skipped["blank val"]
  end

  test "skip_unless uses 'unknown' reason when none given" do
    items = [{name: "A"}, {name: "B"}]

    kept = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.process_enum(items, title: "test") do |item|
      skip_unless item[:name] == "A"
      kept << item[:name]
    end

    assert_equal %w[A], kept
    assert_equal 1, runner.import_record.records_skipped["unknown"]
  end

  test "skip_unless does not skip when condition is true" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
    runner.process_enum([1, 2, 3], title: "test") do |n|
      skip_unless n.is_a?(Integer), "not int"
    end

    assert runner.import_record.records_skipped.empty?
  end

  private

  def write_csv(filename, rows)
    path = File.join(@csv_dir, filename)
    CSV.open(path, "w") do |csv|
      rows.each { |row| csv << row }
    end
  end


end
