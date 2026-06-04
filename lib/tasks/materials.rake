namespace :materials do
  desc "Destroy materials not associated with any samples"
  task destroy_orphans: :environment do
    # Default to dry-run unless explicitly disabled
    dry_run = ENV["DRY_RUN"] != "false"

    puts "== Destroy orphaned materials =="
    puts "Dry run: #{dry_run}"
    puts

    scope =
      Material
        .left_outer_joins(:samples)
        .where(samples: { id: nil })

    total = scope.count

    puts "Found #{total} materials not associated with a sample"
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

    scope.find_each do |material|
      if dry_run
        progress.increment
        next
      end

      material.destroy!
      progress.increment
    rescue => e
      progress.log(
        "FAILED Material ##{material.id}: #{e.class} – #{e.message}"
      )
      progress.increment
    end

    puts
    puts "Done."
  end
end
