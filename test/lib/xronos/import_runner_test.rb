# frozen_string_literal: true

require 'test_helper'
require 'stringio'
require 'tempfile'
require 'csv'
require 'roo'

module Xronos
  class ImportRunnerTest < ActiveSupport::TestCase
    setup do
      @source = create(:source)
      @csv_dir = Dir.mktmpdir
      @output = StringIO.new
    end

    teardown do
      FileUtils.remove_entry(@csv_dir)
    end

    test 'creates import record with success false' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      assert_equal false, runner.import_record.success
      assert_equal @source, runner.import_record.source
    end

    test 'csv yields rows from file in csv_dir' do
      write_csv('sites.csv', [%w[Name Lat], %w[Alpha 10.5], %w[Beta 20.3]])

      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      rows = []
      runner.csv('sites.csv') { |row| rows << row.to_h }

      assert_equal 2, rows.size
      assert_equal 'Alpha', rows[0]['Name']
      assert_equal '10.5', rows[0]['Lat']
    end

    test 'csv raises on missing file' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      assert_raises(Errno::ENOENT) { runner.csv('nonexistent.csv').each {} }
    end

    test 'csv processes all rows with progress bar' do
      write_csv('sites.csv', [%w[Name], %w[A], %w[B], %w[C]])

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.csv('sites.csv') { |row| rows << row.to_h }

      assert_equal 3, rows.size
    end

    test 'csv accepts options like col_sep and encoding' do
      path = File.join(@csv_dir, 'semicolons.csv')
      CSV.open(path, 'w', col_sep: ';') do |csv|
        csv << %w[Name Age]
        csv << %w[Alpha 10]
        csv << %w[Beta 20]
      end

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.csv('semicolons.csv', col_sep: ';') { |row| rows << row.to_h }

      assert_equal 2, rows.size
      assert_equal 'Alpha', rows[0]['Name']
      assert_equal '10', rows[0]['Age']
    end

    test 'increment_created increments per model' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.increment_created(:site)
      runner.increment_created(:c14)
      runner.increment_created(:site)

      assert_equal 2, runner.import_record.records_created['site']
      assert_equal 1, runner.import_record.records_created['c14']
    end

    test 'succeed! sets success to true' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.succeed!
      assert runner.import_record.success
    end

    test 'succeed! persists counters' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.increment_created(:site)
      runner.increment_created(:c14)
      runner.succeed!

      runner.import_record.reload
      assert_equal 1, runner.import_record.records_created['site']
      assert_equal 1, runner.import_record.records_created['c14']
      assert runner.import_record.success
    end

    test 'cell strips whitespace and returns nil for blank' do
      row = CSV::Row.new(%w[a b c], ['  hello  ', '', '   '])

      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

      assert_equal 'hello', runner.cell(row, 'a')
      assert_nil runner.cell(row, 'b')
      assert_nil runner.cell(row, 'c')
    end

    test 'process_enum yields items with progress bar' do
      items = %w[a b c]
      yielded = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.process_enum(items, title: 'letters') { |item| yielded << item }
      assert_equal %w[a b c], yielded
    end

    test 'import! creates a record and increments counter' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      site = runner.import!(Site, keys: { name: 'Alpha' },
                                  attributes: { lat: '10.5', country_code: 'ES' })

      assert site.persisted?
      assert_equal 'Alpha', site.name
      assert_equal BigDecimal('10.5'), site.lat
      assert_equal 'ES', site.country_code
      assert_equal 1, runner.import_record.records_created['site']
    end

    test 'import! creates new records for attribute variations' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

      site_a = runner.import!(Site, keys: { name: 'Alpha' },
                                    attributes: { lat: '10.5', lng: '20.3', country_code: 'ES' })
      site_b = runner.import!(Site, keys: { name: 'Alpha' },
                                    attributes: { lat: '99.9', lng: '88.8', country_code: 'PT' })

      assert_not_equal site_a.id, site_b.id
      assert_equal 2, runner.import_record.records_created['site']
    end

    test 'import! does not create duplicates for identical data' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

      site_a = runner.import!(Site, keys: { name: 'Alpha' },
                                    attributes: { lat: '10.5', lng: '20.3', country_code: 'ES' })
      site_b = runner.import!(Site, keys: { name: 'Alpha' },
                                    attributes: { lat: '10.5', lng: '20.3', country_code: 'ES' })

      assert_equal site_a.id, site_b.id
      assert_equal 1, runner.import_record.records_created['site']
    end

    test 'import! works with association scope' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      site = create(:site, name: 'Test')

      context = runner.import!(site.contexts,
                               keys: { name: 'Trench A' },
                               revision_comment: 'import')

      assert context.persisted?
      assert_equal site, context.site
      assert_equal 1, runner.import_record.records_created['context']
    end

    test 'import! works without attributes' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

      material = runner.import!(Material, keys: { name: 'Wood' })

      assert material.persisted?
      assert_equal 'Wood', material.name
      assert_equal 1, runner.import_record.records_created['material']
    end

    test 'import! does not require revision_comment on models without Versioned' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      material = runner.import!(Material, keys: { name: 'Bone' })
      assert material.persisted?
    end

    test 'build_new! creates a record and increments counter' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      site = runner.build_new!(Site,
                               attributes: { name: 'Alpha', lat: '10.5', country_code: 'ES' })

      assert site.persisted?
      assert_equal 'Alpha', site.name
      assert_equal BigDecimal('10.5'), site.lat
      assert_equal 'ES', site.country_code
      assert_equal 1, runner.import_record.records_created['site']
    end

    test 'build_new! creates new records even for identical data' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      context = create(:context)
      material = create(:material)

      sample_a = runner.build_new!(context.samples,
                                   attributes: { material: material })
      sample_b = runner.build_new!(context.samples,
                                   attributes: { material: material })

      assert_not_equal sample_a.id, sample_b.id
      assert_equal 2, runner.import_record.records_created['sample']
    end

    test 'build_new! works with association scope' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      site = create(:site, name: 'Test')

      context = runner.build_new!(site.contexts,
                                  attributes: { name: 'Trench A' },
                                  revision_comment: 'import')

      assert context.persisted?
      assert_equal site, context.site
      assert_equal 1, runner.import_record.records_created['context']
    end

    test 'import record is persisted immediately' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      assert_predicate runner.import_record, :persisted?
      assert_not runner.import_record.success
    end

    test 'skip_unless skips row in csv block and counts reason' do
      write_csv('samples.csv', [%w[Name BP], %w[Alpha 100], %w[Beta], %w[Gamma 200]])

      kept = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.csv('samples.csv') do |row|
        skip_unless cell(row, 'BP'), 'missing BP'
        kept << cell(row, 'Name')
      end

      assert_equal %w[Alpha Gamma], kept
      assert_equal 1, runner.import_record.records_skipped['missing BP']
    end

    test 'skip_unless skips row in process_enum block and counts reason' do
      items = [{ name: 'A', val: '1' }, { name: 'B', val: '' }, { name: 'C', val: '3' }]

      kept = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.process_enum(items, title: 'test') do |item|
        skip_unless item[:val].present?, 'blank val'
        kept << item[:name]
      end

      assert_equal %w[A C], kept
      assert_equal 1, runner.import_record.records_skipped['blank val']
    end

    test "skip_unless uses 'unknown' reason when none given" do
      items = [{ name: 'A' }, { name: 'B' }]

      kept = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.process_enum(items, title: 'test') do |item|
        skip_unless item[:name] == 'A'
        kept << item[:name]
      end

      assert_equal %w[A], kept
      assert_equal 1, runner.import_record.records_skipped['unknown']
    end

    test 'skip_unless does not skip when condition is true' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.process_enum([1, 2, 3], title: 'test') do |n|
        skip_unless n.is_a?(Integer), 'not int'
      end

      assert runner.import_record.records_skipped.empty?
    end

    test 'xlsx yields rows from specified sheet' do
      write_xlsx('data.xlsx', { 'Sheet1' => [%w[Name Lat], %w[Alpha 10.5], %w[Beta 20.3]] })

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.xlsx('data.xlsx', sheets: 'Sheet1') { |row| rows << row }

      assert_equal 2, rows.size
      assert_equal 'Alpha', rows[0]['Name']
      assert_equal '10.5', rows[0]['Lat'].to_s
    end

    test 'xlsx iterates multiple sheets' do
      sheets = {
        'North' => [%w[Site], %w[A], %w[B]],
        'South' => [%w[Site], %w[C]]
      }
      write_xlsx('data.xlsx', sheets)

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.xlsx('data.xlsx', sheets: %w[North South]) { |row| rows << row['Site'] }

      assert_equal %w[A B C], rows
    end

    test 'xlsx strips HTML tags from headers' do
      sheets = { 'Data' => [
        ['<html><b>Name</b></html>', '<sup>14</sup>C age'],
        %w[Alpha 3000],
        %w[Beta 4000]
      ] }
      write_xlsx('data.xlsx', sheets)

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.xlsx('data.xlsx', sheets: 'Data') { |row| rows << row }

      assert_equal 2, rows.size
      assert_equal 'Alpha', rows[0]['Name']
      assert_equal '3000', rows[0]['14C age'].to_s
    end

    test 'xlsx uses specified header_row' do
      sheets = { 'Data' => [
        ['Category header', nil],
        %w[Name Age],
        %w[Alpha 100],
        %w[Beta 200]
      ] }
      write_xlsx('data.xlsx', sheets)

      rows = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.xlsx('data.xlsx', sheets: 'Data', header_row: 2) { |row| rows << row }

      assert_equal 2, rows.size
      assert_equal 'Alpha', rows[0]['Name']
      assert_equal '100', rows[0]['Age'].to_s
    end

    test 'xlsx skip_unless works like csv' do
      write_xlsx('data.xlsx', { 'Sheet1' => [%w[Name BP], %w[Alpha 100], %w[Beta], %w[Gamma 200]] })

      kept = []
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.xlsx('data.xlsx', sheets: 'Sheet1') do |row|
        skip_unless row['BP'], 'missing BP'
        kept << row['Name']
      end

      assert_equal %w[Alpha Gamma], kept
      assert_equal 1, runner.import_record.records_skipped['missing BP']
    end

    test 'with_merges_suppressed prevents cross-sample sample destruction inside the block' do
      context = create(:context)
      canonical = create(:sample, nameless_attrs(context: context))
      canonical_c14 = create(:c14, c14_attrs(sample: canonical))

      dupe = create(:sample, nameless_attrs(context: context))
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)

      runner.with_merges_suppressed do
        dupe_c14 = runner.import!(dupe.c14s,
                                  keys: { lab_identifier: canonical_c14.lab_identifier },
                                  attributes: c14_attrs(sample: dupe).except(:lab_identifier),
                                  revision_comment: 'test')
        # With suppression, the cross-sample merge has not fired:
        # dupe is still alive and the new c14 is not yet superseded.
        assert_not dupe.destroyed?, 'sample was destroyed despite suppression'
        assert_not dupe_c14.superseded?, 'c14 was superseded despite suppression'
        assert_equal dupe.id, dupe_c14.sample_id
      end
    end

    test 'with_merges_suppressed restores callbacks after the block' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.with_merges_suppressed {}
      assert_not Xronos::ImportRunner.merges_suppressed

      context = create(:context)
      s1 = create(:sample, nameless_attrs(context: context))
      c1 = create(:c14, c14_attrs(sample: s1))

      Sample.skip_callback(:save, :after, :merge_exact_duplicates)
      Sample.skip_callback(:validate, :before, :no_exact_duplicate, on: :create)
      begin
        s2 = create(:sample, nameless_attrs(context: context))
        c2 = create(:c14, c14_attrs(sample: s2).merge(lab_identifier: c1.lab_identifier))
        assert_predicate s2, :destroyed?
        assert_predicate c2.reload, :superseded?
      ensure
        Sample.set_callback(:save, :after, :merge_exact_duplicates)
        Sample.set_callback(:validate, :before, :no_exact_duplicate, on: :create)
      end
    end

    test 'with_merges_suppressed restores callbacks even when the block raises' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      assert_raises(RuntimeError) do
        runner.with_merges_suppressed { raise 'boom' }
      end
      assert_not Xronos::ImportRunner.merges_suppressed
    end

    test 'with_merges_suppressed is idempotent for nested calls' do
      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.with_merges_suppressed do
        runner.with_merges_suppressed do
          assert Xronos::ImportRunner.merges_suppressed
        end
        # Inner call must not have restored callbacks mid-way.
        assert Xronos::ImportRunner.merges_suppressed
      end
      assert_not Xronos::ImportRunner.merges_suppressed
    end

    test 'deduplicate_chrons! resolves deferred cross-sample duplicates with no orphans' do
      context = create(:context)
      canonical = create(:sample, nameless_attrs(context: context))
      _canonical_typo = create(:typo, sample: canonical, name: 'Neolithic')
      dupe = create(:sample, nameless_attrs(context: context))

      runner = Xronos::ImportRunner.new(@source, csv_dir: @csv_dir, output: @output)
      runner.with_merges_suppressed do
        runner.import!(dupe.typos,
                       keys: { name: 'Neolithic' },
                       revision_comment: 'test')
        assert_not dupe.destroyed?
      end

      runner.deduplicate_chrons!

      # dupe was merged (physical destroy) into canonical.
      assert_nil Sample.unscoped.find_by(id: dupe.id),
                 'dupe sample should have been physically merged'
      # No typos should have a dangling sample_id.
      orphaned = Typo.left_outer_joins(:sample).where(samples: { id: nil })
      assert_equal 0, orphaned.count, "orphaned typos: #{orphaned.map(&:id)}"
    end

    private

    def nameless_attrs(context:)
      { context: context, name: nil, material: nil, taxon: nil,
        part_of_organism: nil, position_description: nil, position_crs: nil,
        position_x: nil, position_y: nil, position_z: nil }
    end

    def c14_attrs(sample:)
      { lab_identifier: "OxA-#{sample.id}-#{SecureRandom.hex(3)}",
        sample: sample, bp: 3500, std: 30, method: 'AMS',
        delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5 }
    end

    def write_csv(filename, rows)
      path = File.join(@csv_dir, filename)
      CSV.open(path, 'w') do |csv|
        rows.each { |row| csv << row }
      end
    end

    def write_xlsx(filename, sheets_data)
      path = File.join(@csv_dir, filename)
      workbook = RubyXL::Workbook.new

      sheets_data.each_with_index do |(sheet_name, rows), idx|
        sheet = idx.zero? ? workbook[0] : workbook.add_worksheet(sheet_name)
        sheet.sheet_name = sheet_name if idx.zero?

        rows.each_with_index do |row_data, row_idx|
          row_data.each_with_index do |cell_value, col_idx|
            cell = sheet.add_cell(row_idx, col_idx, cell_value)
            cell.change_number_format(RubyXL::NumberFormat::NUMBER_GENERAL) if cell_value.is_a?(Numeric)
          end
        end
      end

      workbook.write(path)
    end
  end
end
