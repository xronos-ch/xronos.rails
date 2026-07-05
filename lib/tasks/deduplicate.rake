namespace :xronos do
  desc "Merge exact-duplicates of MODEL. " \
       "Usage: bin/rails \"xronos:deduplicate[Taxon]\""
  task :deduplicate, [:model_name] => :environment do |_t, args|
    model_name = args[:model_name] ||
      abort("Usage: bin/rails \"xronos:deduplicate[MODEL]\" — provide a model name (e.g. Taxon, Site, C14)")

    model_class = begin
      model_name.constantize
    rescue NameError
      abort "Unknown model: #{model_name}"
    end

    abort "#{model_class} does not include Mergeable — nothing to deduplicate" unless model_class.include?(Mergeable)

    dry_run = ENV["DRY_RUN"] != "false"

    whodunnit = ENV.fetch("ADMIN_USER_ID") do
      abort "ADMIN_USER_ID must be set"
    end

    label = model_class.name.pluralize.underscore

    puts "== Deduplicate #{label} =="
    puts "Dry run: #{dry_run}"
    puts "Whodunnit (ADMIN_USER_ID): #{whodunnit}"
    puts

    attrs = model_class.exact_duplicates_attrs
    duplicate_groups = model_class
      .group(*attrs)
      .having("COUNT(*) > 1")
      .pluck(*attrs, Arel.sql("COUNT(*)"))

    total_groups = duplicate_groups.size
    total_rows   = duplicate_groups.sum { |row| row.last - 1 }

    puts "Duplicate groups found: #{total_groups}"
    puts "Rows that would be merged: #{total_rows}"
    puts

    if total_groups.zero?
      puts "No duplicates found. Nothing to do."
      next
    end

    if dry_run
      puts "Not merging any records because DRY_RUN=false is not set"
      exit
    end

    progress = ProgressBar.create(
      title: "Merging",
      total: total_groups,
      format: "%t |%B| %c/%C (%E)"
    )

    PaperTrail.request(whodunnit: whodunnit) do
      duplicate_groups.each do |*values, _count|
        values_hash = attrs.zip(values).to_h
        records = model_class.where(values_hash).order(:created_at, :id).to_a
        next if records.size < 2

        canonical = records.first
        records[1..].each { |dupe| dupe.merge_into!(canonical) }
        progress.increment
      rescue => e
        progress.log("FAILED group #{values_hash.inspect}: #{e.class} – #{e.message}")
        progress.increment
      end
    end

    puts
    puts "Done."
  end
end
