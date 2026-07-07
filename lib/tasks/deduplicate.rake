namespace :xronos do
  desc 'Merge exact-duplicates of MODEL. ' \
       'Usage: bin/rails "xronos:deduplicate[Taxon]"'
  task :deduplicate, [:model_name] => :environment do |_t, args|
    model_name = args[:model_name] ||
                 abort('Usage: bin/rails "xronos:deduplicate[MODEL]" — provide a model name (e.g. Taxon, Site, C14)')

    model_class = begin
      model_name.constantize
    rescue NameError
      abort "Unknown model: #{model_name}"
    end

    abort "#{model_class} does not include Mergeable — nothing to deduplicate" unless model_class.include?(Mergeable)

    dry_run = ENV['DRY_RUN'] != 'false'

    whodunnit = ENV.fetch('ADMIN_USER_ID') do
      abort 'ADMIN_USER_ID must be set'
    end

    label = model_class.name.pluralize.underscore

    puts "== Deduplicate #{label} =="
    puts "Dry run: #{dry_run}"
    puts "Whodunnit (ADMIN_USER_ID): #{whodunnit}"
    puts

    attrs = model_class.exact_duplicates_attrs

    duplicate_groups = model_class
                       .duplicate_group_scope
                       .pluck(*attrs, Arel.sql('COUNT(*)'))

    total_groups = duplicate_groups.size
    total_rows   = duplicate_groups.sum { |row| row.last - 1 }

    puts "Duplicate groups found: #{total_groups}"
    puts "Rows that would be merged: #{total_rows}"
    puts

    if total_groups.zero?
      # Don't early-return: an empty strict scope can still coexist
      # with cross-record duplicates (e.g. two chrons in different
      # samples that match on every other attribute). The cross-sample
      # pass below is what catches those.
      puts 'No exact-duplicate groups found.'
    end

    if dry_run
      puts 'Not merging any records because DRY_RUN=false is not set'
      if model_class.respond_to?(:cross_sample_deduplicate!)
        puts '(cross-sample dedup would also run with DRY_RUN=false)'
      end
      exit
    end

    PaperTrail.request(whodunnit: whodunnit) do
      unless total_groups.zero?
        progress = ProgressBar.create(
          title: 'Merging',
          total: total_groups,
          format: '%t |%B| %c/%C (%E)'
        )

        duplicate_groups.each do |*values, _count|
          values_hash = attrs.zip(values).to_h
          records = model_class.where(values_hash).order(:created_at, :id).to_a
          next if records.size < 2

          canonical = records.first
          records[1..].each { |dupe| dupe.merge_into!(canonical) }
          progress.increment
        rescue StandardError => e
          progress.log("FAILED group #{values_hash.inspect}: #{e.class} – #{e.message}")
          progress.increment
        end
      end

      # Cross-record dedup (e.g. Chrons that are duplicates across two
      # different samples). Opt-in via class method, so other Mergeable
      # models that lack cross-record detection are unaffected.
      if model_class.respond_to?(:cross_sample_deduplicate!)
        puts
        puts '== Cross-sample dedup =='
        model_class.cross_sample_deduplicate!
      end
    end

    puts
    puts 'Done.'
  end
end
