# frozen_string_literal: true

require 'csv'
require 'roo'
require 'ruby-progressbar'

module Xronos
  class ImportRunner
    # Chron and Sample callbacks whose auto-merge behaviour would
    # destroy the parent a script is holding. Suppressed for the
    # duration of `with_merges_suppressed`; restored unconditionally
    # (including on exception) so the process state is never leaked.
    #
    # Note: the chron list is explicit (not `Chron.subclasses`) because
    # the rake process may not have eager-loaded subclasses yet; new
    # chron subclasses must be added here.
    MERGE_CALLBACKS = [
      [Sample, :save, :after, :merge_exact_duplicates],
      [C14,    :save, :after, :merge_exact_duplicates],
      [C14,    :save, :after, :merge_cross_sample_duplicates],
      [Typo,   :save, :after, :merge_exact_duplicates],
      [Typo,   :save, :after, :merge_cross_sample_duplicates]
    ].freeze

    @merges_suppressed = false

    class << self
      attr_accessor :merges_suppressed

      def suppress_callbacks!
        MERGE_CALLBACKS.each { |model, kind, chain, method| model.skip_callback(kind, chain, method) }
      end

      def restore_callbacks!
        MERGE_CALLBACKS.each { |model, kind, chain, method| model.set_callback(kind, chain, method) }
      end
    end

    def initialize(source, csv_dir:, output: $stderr)
      @source = source
      @csv_dir = csv_dir
      @output = output
      @import = Import.create!(source: @source, success: false)
    end

    def self.parse_args!(args)
      version = args[:version] || abort('Usage: bin/rails "xronos:import:TASK[version,dir,source_url]" — provide a version, data directory, and source URL')
      dir = args[:dir] || abort('Usage: bin/rails "xronos:import:TASK[version,dir,source_url]" — provide a version, data directory, and source URL')
      source_url = args[:source_url] || abort('Usage: bin/rails "xronos:import:TASK[version,dir,source_url]" — provide a version, data directory, and source URL')
      abort "Source directory not found: #{dir}" unless Dir.exist?(dir)

      [version, dir, source_url]
    end

    def csv(filename, **csv_options, &block)
      path = File.join(@csv_dir, filename.to_s)
      total = File.foreach(path, encoding: csv_options[:encoding]).count - 1

      progress = ProgressBar.create(
        title: filename.to_s,
        total: total,
        format: '%t |%B| %c/%C (%E)',
        output: @output
      )

      CSV.foreach(path, headers: true, **csv_options) do |row|
        catch(:skip_row) { instance_exec(row, &block) }
        progress.increment
      end
    end

    def xlsx(filename, sheets:, header_row: 1, &block)
      path = File.join(@csv_dir, filename.to_s)
      workbook = Roo::Spreadsheet.open(path)
      sheets = Array(sheets)

      sheets.each do |sheet_name|
        sheet = workbook.sheet(sheet_name)
        headers = sheet.row(header_row).map { |h| h.to_s.gsub(/<[^>]+>/, '') }
        total = sheet.last_row - header_row

        progress = ProgressBar.create(
          title: sheet_name.to_s,
          total: total,
          format: '%t |%B| %c/%C (%E)',
          output: @output
        )

        ((header_row + 1)..sheet.last_row).each do |row_num|
          row_values = sheet.row(row_num)
          row_hash = headers.each_with_index.each_with_object({}) do |(header, idx), hash|
            hash[header] = row_values[idx]
          end
          catch(:skip_row) { instance_exec(row_hash, &block) }
          progress.increment
        end
      end
    end

    def process_enum(enumerable, title:, &block)
      total = enumerable.is_a?(Array) ? enumerable.size : enumerable.count
      progress = ProgressBar.create(
        title: title.to_s,
        total: total,
        format: '%t |%B| %c/%C (%E)',
        output: @output
      )
      enumerable.each do |item|
        catch(:skip_row) { instance_exec(item, &block) }
        progress.increment
      end
    end

    def describe!(whodunnit:, revision_comment:)
      puts "== Import: #{@source.label} =="
      puts "Source: #{@source.name} (#{@source.version})"
      puts "Data path: #{@csv_dir}"
      puts "Whodunnit: #{whodunnit}"
      puts "Revision comment: #{revision_comment}"
      puts
    end

    # Run a block with chron/sample auto-merge callbacks suppressed.
    # Safe to nest. Callbacks are restored even if the block raises,
    # so the process never leaks suppressed state between runs.
    #
    # During the block, chrons created on name-relaxed duplicate
    # samples no longer trigger sample destruction, which means the
    # script's in-memory sample references stay valid across all
    # child creations (citations, typos, etc.) in the same row.
    #
    # Pair with `deduplicate_chrons!` after the block to resolve the
    # deferred merges with the existing audited cross-sample
    # machinery. Must be called within the task's PaperTrail.request
    # block so all resulting SupersessionEvents carry the correct
    # whodunnit.
    #
    # For non-block callers, use `suppress_merges!` /
    # `restore_merges!` with an explicit `ensure` (see the rake
    # tasks for an example).
    def with_merges_suppressed
      if self.class.merges_suppressed
        yield
      else
        suppress_merges!
        begin
          yield
        ensure
          restore_merges!
        end
      end
    end

    # Suppress chron/sample auto-merge callbacks. Pair with
    # `restore_merges!` inside an `ensure` so the process never
    # leaks suppressed state. No-op if already suppressed (reentrant).
    def suppress_merges!
      return if self.class.merges_suppressed

      self.class.suppress_callbacks!
      self.class.merges_suppressed = true
    end

    # Restore the suppressed merge callbacks. Safe to call without a
    # prior suppress (idempotent).
    def restore_merges!
      return unless self.class.merges_suppressed

      self.class.restore_callbacks!
      self.class.merges_suppressed = false
    end

    # Resolve the chron duplicates that accumulated during a
    # `with_merges_suppressed` run. Runs `cross_sample_deduplicate!`
    # for each chron subclass; same-sample exact duplicates cannot
    # exist at this point (each chron lands on a per-row fresh sample,
    # and `no_exact_duplicate` would have raised otherwise), and
    # cross-sample merges resolve their own chron-level duplicates
    # internally. Must be called within the task's PaperTrail.request
    # block so all resulting SupersessionEvents carry the correct
    # whodunnit.
    def deduplicate_chrons!
      puts 'Deduplicating chrons...'
      [C14, Typo].each do |klass|
        pairs = klass.cross_sample_pairs.size
        next if pairs.zero?

        klass.cross_sample_deduplicate!
      end
    end

    def report!
      all_models = @import.records_created.keys.select do |m|
        @import.records_created.fetch(m, 0).positive?
      end.sort

      return if all_models.empty?

      rows = all_models.map do |model|
        count = @import.records_created.fetch(model, 0)
        [model.pluralize(count), count.to_s]
      end

      total = @import.records_created_total

      skipped = @import.records_skipped.reject { |_, v| v.zero? }

      label_width = [rows.map { |r| r[0].length }.max, 'Model'.length].max
      num_width = [total.to_s.length, 'Created'.length].max

      sep = "+-#{'-' * label_width}-+-#{'-' * num_width}-+"

      puts
      puts '--- Import complete ---'
      puts
      puts sep
      puts "| #{'Model'.ljust(label_width)} | #{'Created'.rjust(num_width)} |"
      puts sep
      rows.each do |label, count|
        puts "| #{label.ljust(label_width)} | #{count.rjust(num_width)} |"
      end
      puts sep
      puts "| #{'Total'.ljust(label_width)} | #{total.to_s.rjust(num_width)} |"
      puts sep

      return if skipped.empty?

      total_skipped = skipped.values.sum
      puts
      puts "Skipped rows: #{total_skipped}"
      skipped.each do |reason, count|
        puts "  #{reason}: #{count}"
      end
      puts
    end

    def cell(row, column)
      row[column].to_s.strip.presence
    end

    def skip_unless(condition, reason = nil)
      return if condition

      key = reason || 'unknown'
      @import.records_skipped[key] = @import.records_skipped.fetch(key, 0) + 1
      throw :skip_row
    end

    # Imports a record into the given scope, finding it by the combined set of
    # identity keys and attributes. A record is created only when no exact
    # match exists — any difference in keys or attributes produces a new record.
    # This ensures that all data from the source is represented, even minor
    # variants, without ever silently overwriting existing data.
    def import!(scope, keys:, attributes: {}, revision_comment: nil)
      find_attrs = keys.merge(attributes)
      record = scope.find_or_initialize_by(find_attrs)

      if record.new_record?
        record.assign_attributes(find_attrs)
        record.revision_comment = revision_comment if record.respond_to?(:revision_comment=)
        record.save!
        increment_created(record.model_name.singular)
      end

      record
    end

    # Always creates a new record in the given scope, never finding existing ones.
    # Use when source data implies each row is distinct (e.g. samples without a
    # shared identifier). Model-level duplicate detection still applies after save.
    def build_new!(scope, attributes: {}, revision_comment: nil)
      record = scope.new(attributes)
      record.revision_comment = revision_comment if record.respond_to?(:revision_comment=)
      record.save!
      increment_created(record.model_name.singular)
      record
    end

    # Links a citable record to the source's own bibliographic reference.
    # The source reference must be set on the Source record before this is
    # called (typically created from a BibTeX entry in the rake task).
    # Safe to call multiple times — will not create duplicate citations.
    def cite_source!(citable)
      ref = @source.reference
      return unless ref

      Citation.find_or_create_by!(citing: citable, reference: ref)
    end

    def increment_created(model)
      key = model.to_s
      @import.records_created[key] = @import.records_created.fetch(key, 0) + 1
    end

    def succeed!
      @import.update!(success: true)
      Sites::RefreshCountsJob.perform_later
    end

    def import_record
      @import
    end
  end
end
