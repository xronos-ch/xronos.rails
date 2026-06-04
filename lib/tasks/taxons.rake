namespace :taxons do
  desc "Match taxons to GBIF Backbone Taxonomy"
  task match_unknown: :environment do
    # Default to dry-run unless explicitly disabled
    dry_run = ENV["DRY_RUN"] != "false"

    puts "== Match unknown taxons to GBIF =="
    puts "Dry run: #{dry_run}"
    puts "EXACT MATCHES ONLY"
    puts

    unknown_taxons = Taxon.unknown_taxon
    total = unknown_taxons.count

    puts "Found #{total} unknown taxons"
    puts

    if dry_run
      puts "Not doing anything because DRY_RUN=false is not set"
      exit
    end

    progressbar =
      ProgressBar.create(
        title: "Matching",
        total: total,
        format: "%t |%B| %c/%C (%E)"
      )

    unknown_taxons.find_each do |taxon|
      if dry_run
        progressbar.increment
        next
      end

      taxon.set_gbif_id_from_match
      taxon.save!

      progressbar.increment
    rescue => e
      progressbar.log(
        "FAILED Taxon ##{taxon.id}: #{e.class} – #{e.message}"
      )
      progressbar.increment
    end

    puts
    puts "Done."
  end


  desc "Destroy taxons not associated with any samples"
  task destroy_orphans: :environment do
    # Default to dry-run unless explicitly disabled
    dry_run = ENV["DRY_RUN"] != "false"

    puts "== Destroy orphaned taxons =="
    puts "Dry run: #{dry_run}"
    puts

    scope =
      Taxon
        .left_outer_joins(:samples)
        .where(samples: { id: nil })

    total = scope.count

    puts "Found #{total} taxons not associated with a sample"
    puts

    if dry_run
      puts "Not deleting any records because DRY_RUN=false is not set"
      exit
    end

    progress =
      ProgressBar.create(
        title: "Destroying",
        total: total,
        format: "%t |%B| %c/%C"
      )

    scope.find_each do |taxon|
      if dry_run
        progress.increment
        next
      end

      taxon.destroy!
      progress.increment
    rescue => e
      progress.log(
        "FAILED Taxon ##{taxon.id}: #{e.class} – #{e.message}"
      )
      progress.increment
    end

    puts
    puts "Done."
  end
end

