require "csv"
require "ruby-progressbar"

module Xronos
  class ImportRunner
    def initialize(source, csv_dir:, output: $stderr)
      @source = source
      @csv_dir = csv_dir
      @output = output
      @import = Import.create!(source: @source, success: false)
    end

    def self.parse_args!(args)
      version = args[:version] || abort("Usage: bin/rails \"xronos:import:TASK[version,dir,source_url]\" — provide a version, data directory, and source URL")
      dir = args[:dir] || abort("Usage: bin/rails \"xronos:import:TASK[version,dir,source_url]\" — provide a version, data directory, and source URL")
      source_url = args[:source_url] || abort("Usage: bin/rails \"xronos:import:TASK[version,dir,source_url]\" — provide a version, data directory, and source URL")
      abort "Source directory not found: #{dir}" unless Dir.exist?(dir)

      [version, dir, source_url]
    end

    def csv(filename, **csv_options, &block)
      path = File.join(@csv_dir, filename.to_s)
      total = File.foreach(path, encoding: csv_options[:encoding]).count - 1

      progress = ProgressBar.create(
        title: filename.to_s,
        total: total,
        format: "%t |%B| %c/%C (%E)",
        output: @output
      )

      CSV.foreach(path, headers: true, **csv_options) do |row|
        catch(:skip_row) { instance_exec(row, &block) }
        progress.increment
      end
    end

    def process_enum(enumerable, title:, &block)
      total = enumerable.is_a?(Array) ? enumerable.size : enumerable.count
      progress = ProgressBar.create(
        title: title.to_s,
        total: total,
        format: "%t |%B| %c/%C (%E)",
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

    def report!
      all_models = @import.records_created.keys.select { |m|
        @import.records_created.fetch(m, 0) > 0
      }.sort

      return if all_models.empty?

      rows = all_models.map do |model|
        count = @import.records_created.fetch(model, 0)
        [model.pluralize(count), count.to_s]
      end

      total = @import.records_created_total

      skipped = @import.records_skipped.reject { |_, v| v == 0 }

      label_width = [rows.map { |r| r[0].length }.max, "Model".length].max
      num_width  = [total.to_s.length, "Created".length].max

      sep = "+-#{"-" * label_width}-+-#{"-" * num_width}-+"

      puts
      puts "--- Import complete ---"
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

      unless skipped.empty?
        total_skipped = skipped.values.sum
        puts
        puts "Skipped rows: #{total_skipped}"
        skipped.each do |reason, count|
          puts "  #{reason}: #{count}"
        end
        puts
      end
    end

    def cell(row, column)
      row[column].to_s.strip.presence
    end

    def skip_unless(condition, reason = nil)
      return if condition

      key = reason || "unknown"
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
    end

    def import_record
      @import
    end
  end
end
