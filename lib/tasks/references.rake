namespace :references do
  desc "Destroy references with no citations"
  task destroy_orphans: :environment do
    dry_run = ENV["DRY_RUN"] != "false"

    whodunnit = ENV.fetch("ADMIN_USER_ID") do
      abort "ADMIN_USER_ID must be set"
    end

    revision_comment =
      ENV["REVISION_COMMENT"] || "Deleted uncited reference."

    puts "== Destroy orphaned references =="
    puts "Dry run: #{dry_run}"
    puts "Whodunnit (ADMIN_USER_ID): #{whodunnit}"
    puts "Revision comment: #{revision_comment}"
    puts

    scope =
      Reference
        .left_outer_joins(:citations)
        .where(citations: { id: nil })

    total = scope.count

    puts "Found #{total} references not cited by any records"
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

    PaperTrail.request(whodunnit: whodunnit) do
      scope.find_each do |reference|
        if dry_run
          progress.increment
          next
        end

        reference.revision_comment = revision_comment
        reference.destroy!

        progress.increment
      rescue => e
        progress.log(
          "FAILED Reference ##{reference.id}: #{e.class} – #{e.message}"
        )
        progress.increment
      end
    end

    puts
    puts "Done."
  end
end
