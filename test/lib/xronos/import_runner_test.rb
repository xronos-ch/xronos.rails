require "test_helper"
require "tempfile"
require "csv"

class Xronos::ImportRunnerTest < ActiveSupport::TestCase
  setup do
    @source = create(:source)
    @csv_dir = Dir.mktmpdir
  end

  teardown do
    FileUtils.remove_entry(@csv_dir)
  end

  test "creates import record with success false" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    assert_equal false, runner.import_record.success
    assert_equal @source, runner.import_record.source
  end

  test "csv yields rows from file in csv_dir" do
    write_csv("sites.csv", [%w[Name Lat], %w[Alpha 10.5], %w[Beta 20.3]])

    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    rows = []
    runner.csv("sites.csv") { |row| rows << row.to_h }

    assert_equal 2, rows.size
    assert_equal "Alpha", rows[0]["Name"]
    assert_equal "10.5", rows[0]["Lat"]
  end

  test "csv raises on missing file" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    assert_raises(Errno::ENOENT) { runner.csv("nonexistent.csv").each { } }
  end

  test "csv processes all rows with progress bar" do
    write_csv("sites.csv", [%w[Name], %w[A], %w[B], %w[C]])

    rows = []
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    runner.csv("sites.csv") { |row| rows << row.to_h }

    assert_equal 3, rows.size
  end

  test "increment_created increments per model" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    runner.increment_created(:site)
    runner.increment_created(:c14)
    runner.increment_created(:site)

    assert_equal 2, runner.import_record.records_created["site"]
    assert_equal 1, runner.import_record.records_created["c14"]
  end

  test "increment_updated increments per model" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    runner.increment_updated(:site)
    runner.increment_updated(:site)

    assert_equal 2, runner.import_record.records_updated["site"]
  end

  test "succeed! sets success to true" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    runner.succeed!
    assert runner.import_record.success
  end

  test "succeed! persists counters" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    runner.increment_created(:site)
    runner.increment_created(:c14)
    runner.succeed!

    runner.import_record.reload
    assert_equal 1, runner.import_record.records_created["site"]
    assert_equal 1, runner.import_record.records_created["c14"]
    assert runner.import_record.success
  end

  test "import record is persisted immediately" do
    runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir)
    assert_predicate runner.import_record, :persisted?
    assert_not runner.import_record.success
  end

  private

  def write_csv(filename, rows)
    path = File.join(@csv_dir, filename)
    CSV.open(path, "w") do |csv|
      rows.each { |row| csv << row }
    end
  end


end
