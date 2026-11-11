# frozen_string_literal: true

require 'test_helper'
require 'rake'
require 'minitest/mock'

class RadonbImportTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  FIXTURE_DIR = Rails.root.join('test/fixtures/files/radonb')
  SOURCE_URL = 'https://example.test/radonb'

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('xronos:import:radonb')
    @task = Rake::Task['xronos:import:radonb']
    @admin = create(:user, :admin)
    @old_admin = ENV['ADMIN_USER_ID']
    ENV['ADMIN_USER_ID'] = @admin.id.to_s
  end

  teardown do
    ENV['ADMIN_USER_ID'] = @old_admin
  end

  test 'imports data and keeps source rows traceable through measurement deduplication' do # rubocop:disable Metrics/BlockLength
    with_versioning { run_import }

    source = Source.find_by!(name: 'RADONB', version: 'fixture')
    assert_equal Digest::SHA256.file(FIXTURE_DIR.join('radondaily.txt')).hexdigest,
                 source.file_manifest.fetch('radondaily.txt')
    assert source.imports.last.success?
    expected_skips = {
      'invalid BP or SD' => 3,
      'conflicting site coordinates' => 2,
      'missing or invalid site coordinates' => 2,
      'missing site name' => 1
    }
    assert_equal expected_skips, source.imports.last.records_skipped

    versions = source_versions(source)
    assert_equal %w[1 15 16 17 2 3 4 5 6], versions.keys.sort
    date = original_date(versions.fetch('1')).ultimately_superseded_by
    assert_equal date, original_date(versions.fetch('2')).ultimately_superseded_by
    assert_not_equal versions.fetch('1').item_id, versions.fetch('2').item_id
    assert_equal [-20.5, 3400, 45], [date.delta_c13, date.bp, date.std]
    assert_equal 'K-42', date.lab_identifier
    assert_equal 'Collagène', date.sample.material.name
    assert_equal 'Grab "A".', date.context.name
    assert_equal 'DE', date.site.country_code
    assert_includes date.references, source.reference
    expected_refs = ['Meyer 1998', 'Müller 1996, 203; Meyer 1997', source.label]
    assert_equal expected_refs.sort, date.references.pluck(:short_ref).sort
    assert_equal @admin.id.to_s, versions.fetch('1').whodunnit
    assert_includes versions.fetch('1').revision_comment, SOURCE_URL

    assert_equal 'Müller 1996, 203; Meyer 1997', provenance(versions.fetch('1')).fetch('reference')
    assert_equal 'Meyer 1998', provenance(versions.fetch('2')).fetch('reference')
    assert_equal 'fixture', provenance(versions.fetch('2')).fetch('version')
    assert_equal 3410, original_date(versions.fetch('3')).bp
    assert_equal 'Autre lieu', original_date(versions.fetch('4')).site.name
    assert_equal 'FR', original_date(versions.fetch('5')).site.country_code
    assert_nil original_date(versions.fetch('6')).lab_identifier
    assert_nil original_date(versions.fetch('6')).delta_c13
  end

  test 'rerunning a source version does not duplicate imported records' do
    run_import

    counts = ['PaperTrail::Version.count', 'C14.unscoped.count', 'Sample.count', 'Site.count', 'Citation.count']
    assert_no_difference counts do
      run_import
    end

    import = Source.find_by!(name: 'RADONB', version: 'fixture').imports.last
    assert import.success?
    assert_equal 9, import.records_skipped.fetch('already imported')
  end

  test 'deduplicates existing exact pairs and preserves site coordinates' do
    site = create(:site, name: 'Gräberfeld', country_code: 'DE', lat: '51.3', lng: '9.2')
    context = create(:context, site: site)
    runner = Xronos::ImportRunner.new(create(:source), csv_dir: FIXTURE_DIR)
    dates = runner.with_merges_suppressed do
      Array.new(2) { C14.create!(sample: context.samples.create!, lab_identifier: 'K-42', bp: 3400, std: 45) }
    end
    assert_includes C14.cross_sample_pairs, [dates.last.id, dates.first.id]

    run_import

    assert_equal BigDecimal('51.3'), site.reload.lat
    assert_equal BigDecimal('51.1'), original_date(source_versions(Source.find_by!(name: 'RADONB')).fetch('1')).site.lat
    assert_equal dates.first, dates.last.reload.ultimately_superseded_by
  end

  test 'source qualifiers remain in the audit trail after exact deduplication' do
    run_import

    versions = source_versions(Source.find_by!(name: 'RADONB'))
    first, second, third = %w[15 16 17].map { |id| original_date(versions.fetch(id)).ultimately_superseded_by }
    assert_equal first, second
    assert_equal first, third
    assert_equal 'Culture A', provenance(versions.fetch('16')).fetch('qualifiers').fetch('CULTURE')
    assert_equal 'Culture B', provenance(versions.fetch('17')).fetch('qualifiers').fetch('CULTURE')
  end

  test 'refuses to import when PaperTrail cannot record the provenance' do
    PaperTrail.request(enabled: false) do
      assert_no_difference ['C14.unscoped.count', 'Site.count'] do
        error = assert_raises(RuntimeError) { run_import }
        assert_match(/requires PaperTrail/, error.message)
      end
    end

    import = Source.find_by!(name: 'RADONB', version: 'fixture').imports.sole
    assert_not import.success?
  end

  test 'rolls back the fixture if deduplication fails' do
    failure = ->(**) { raise 'deduplication failed' }
    assert_no_difference ['PaperTrail::Version.count', 'C14.unscoped.count', 'Site.count', 'Reference.count'] do
      C14.stub(:cross_sample_deduplicate!, failure) do
        assert_raises(RuntimeError) { run_import }
      end
    end

    import = Source.find_by!(name: 'RADONB', version: 'fixture').imports.sole
    assert_not import.success?
    assert_empty import.records_created
    assert_match(/deduplication failed/, import.error)
    assert_not Xronos::ImportRunner.merges_suppressed
  end

  test 'duplicate source ids fail preflight and record a failed import' do
    Dir.mktmpdir do |dir|
      header, row = File.readlines(FIXTURE_DIR.join('radondaily.txt')).first(2)
      File.write(File.join(dir, 'radondaily.txt'), header + row + row)

      assert_no_difference ['PaperTrail::Version.count', 'C14.unscoped.count', 'Site.count'] do
        error = assert_raises(ArgumentError) { run_import(dir) }
        assert_match(/duplicate ID/, error.message)
      end
    end

    import = Source.find_by!(name: 'RADONB', version: 'fixture').imports.sole
    assert_not import.success?
    assert_match(/duplicate ID/, import.error)
  end

  private

  def source_versions(source)
    PaperTrail::Version.where(item_type: 'C14', event: 'create')
                       .where('starts_with(revision_comment, ?)', "RADONB import source #{source.id}: ")
                       .index_by { |version| provenance(version).fetch('id') }
  end

  def provenance(version)
    JSON.parse(version.revision_comment.lines.first.partition(': ').last)
  end

  def original_date(version)
    C14.unscoped.find(version.item_id)
  end

  def run_import(dir = FIXTURE_DIR)
    @task.reenable
    capture_io { @task.invoke('fixture', dir.to_s, SOURCE_URL) }
  end
end
