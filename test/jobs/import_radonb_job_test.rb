# frozen_string_literal: true

require 'test_helper'

class ImportRadonbJobTest < ActiveJob::TestCase
  EXPORT_URL = 'https://radonb.ufg.uni-kiel.de/radondaily.txt'

  test 'archives downloads and imports only new rows on subsequent runs' do
    header, first, second = File.readlines(Rails.root.join('test/fixtures/files/radonb/radondaily.txt')).first(3)
    initial = header + first
    updated = header + first.sub('3400', '3401') + second
    stub_request(:get, EXPORT_URL).to_return({ body: initial }, { body: initial }, { body: updated })

    Dir.mktmpdir do |archive|
      assert_difference 'C14.unscoped.count', 2 do
        capture_io { 3.times { ImportRadonbJob.perform_now(admin.id, archive) } }
      end

      assert_equal [initial, initial, updated].sort, Dir.glob("#{archive}/*/radondaily.txt").map { |path|
        File.binread(path).force_encoding(Encoding::UTF_8)
      }.sort
    end

    imports = Import.joins(:source).where(sources: { name: 'RADONB' }).order(:id).to_a
    assert_equal [{}, { 'unchanged row' => 1 }, { 'changed row' => 1 }], imports.map(&:records_skipped)
    assert imports.all?(&:success?)
    assert_equal [3400, 3400], C14.unscoped.where(lab_identifier: 'K-42').pluck(:bp)
  end

  test 'a scheduled rerun keeps the historical measurement after a manual merge' do
    header, row = File.readlines(Rails.root.join('test/fixtures/files/radonb/radondaily.txt')).first(2)
    historical = create(:c14, lab_identifier: 'K-42', bp: 3400, std: 45)
    stub_request(:get, EXPORT_URL).to_return(body: header + row)

    Dir.mktmpdir do |archive|
      capture_io { ImportRadonbJob.perform_now(admin.id, archive) }
      imported = C14.where(lab_identifier: 'K-42').where.not(id: historical.id).sole
      imported.merge_into!(historical)

      assert_no_difference ['C14.unscoped.count', 'PaperTrail::Version.count'] do
        capture_io { ImportRadonbJob.perform_now(admin.id, archive) }
      end

      assert_equal historical, imported.reload.ultimately_superseded_by
      assert_equal [historical.id], C14.where(lab_identifier: 'K-42').pluck(:id)
      assert_equal({ 'unchanged row' => 1 }, Source.find_by!(name: 'RADONB').imports.last.records_skipped)
    end
  end

  test 'a failed download leaves the archive and import records untouched' do
    stub_request(:get, EXPORT_URL).to_return(status: 503)

    Dir.mktmpdir do |archive|
      assert_no_difference ['Import.count', 'C14.unscoped.count'] do
        assert_raises(Net::HTTPFatalError) { ImportRadonbJob.perform_now(admin.id, archive) }
      end
      assert_empty Dir.children(archive)
    end
  end

  private

  def admin
    @admin ||= create(:user, :admin)
  end
end
