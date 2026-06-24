require "csv"
require "ruby-progressbar"

module Xronos
  class ImportRunner
    def initialize(source, csv_dir:)
      @source = source
      @csv_dir = csv_dir
      @import = Import.create!(source: @source, success: false)
    end

    def csv(filename, &block)
      path = File.join(@csv_dir, filename.to_s)
      total = File.foreach(path).count - 1

      progress = ProgressBar.create(
        title: filename.to_s,
        total: total,
        format: "%t |%B| %c/%C (%E)"
      )

      CSV.foreach(path, headers: true) do |row|
        block.call(row)
        progress.increment
      end
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
