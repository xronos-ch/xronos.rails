require "csv"
require "ruby-progressbar"

module Xronos
  class ImportRunner
    def initialize(source, csv_dir:)
      @source = source
      @csv_dir = csv_dir
      @import = Import.create!(source: @source, success: false)
    end

    def csv(filename, **csv_options, &block)
      path = File.join(@csv_dir, filename.to_s)
      total = File.foreach(path, encoding: csv_options[:encoding]).count - 1

      progress = ProgressBar.create(
        title: filename.to_s,
        total: total,
        format: "%t |%B| %c/%C (%E)"
      )

      CSV.foreach(path, headers: true, **csv_options) do |row|
        block.call(row)
        progress.increment
      end
    end

    def process_enum(enumerable, title:, &block)
      total = enumerable.is_a?(Array) ? enumerable.size : enumerable.count
      progress = ProgressBar.create(
        title: title.to_s,
        total: total,
        format: "%t |%B| %c/%C (%E)"
      )
      enumerable.each do |item|
        block.call(item)
        progress.increment
      end
    end

    def describe!(whodunnit:, revision_comment:)
      puts "== Import: #{@source.label} =="
      puts "Source: #{@source.name}"
      puts "Version: (#{@source.version})"
      puts "Data path: #{@csv_dir}"
      puts "Whodunnit: #{whodunnit}"
      puts "Revision comment: #{revision_comment}"
      puts
    end

    def report!
      all_models = (@import.records_created.keys + @import.records_updated.keys).uniq.select { |m|
        @import.records_created.fetch(m, 0) + @import.records_updated.fetch(m, 0) > 0
      }.sort

      return if all_models.empty?

      rows = all_models.map do |model|
        created = @import.records_created.fetch(model, 0)
        updated = @import.records_updated.fetch(model, 0)
        [model.pluralize(created + updated), created.to_s, updated.to_s]
      end

      total_created = @import.records_created_total
      total_updated = @import.records_updated_total

      label_width = [rows.map { |r| r[0].length }.max, "Model".length].max
      num_width  = [total_created.to_s.length, total_updated.to_s.length, "Created".length, "Updated".length].max

      sep = "+-#{"-" * label_width}-+-#{"-" * num_width}-+-#{"-" * num_width}-+"

      puts
      puts "--- Import complete ---"
      puts
      puts sep
      puts "| #{'Model'.ljust(label_width)} | #{'Created'.rjust(num_width)} | #{'Updated'.rjust(num_width)} |"
      puts sep
      rows.each do |label, created, updated|
        puts "| #{label.ljust(label_width)} | #{created.rjust(num_width)} | #{updated.rjust(num_width)} |"
      end
      puts sep
      puts "| #{'Total'.ljust(label_width)} | #{total_created.to_s.rjust(num_width)} | #{total_updated.to_s.rjust(num_width)} |"
      puts sep
      puts
    end

    def cell(row, column)
      row[column].to_s.strip.presence
    end

    def increment_created(model)
      key = model.to_s
      @import.records_created[key] = @import.records_created.fetch(key, 0) + 1
    end

    def increment_updated(model)
      key = model.to_s
      @import.records_updated[key] = @import.records_updated.fetch(key, 0) + 1
    end

    def succeed!
      @import.update!(success: true)
    end

    def import_record
      @import
    end
  end
end
