namespace :xronos do
  desc "Destroy record by ID"
  task destroy: :environment do
    model_name = ENV["MODEL"]
    record_id  = ENV["ID"]&.to_i

    abort "MODEL must be set" unless model_name
    abort "ID must be set" unless record_id

    # Default to dry-run unless explicitly disabled
    dry_run = ENV["DRY_RUN"] != "false"

    whodunnit = ENV.fetch("ADMIN_USER_ID") do
      abort "ADMIN_USER_ID must be set"
    end

    revision_comment =
      ENV["REVISION_COMMENT"] || "Deleted #{model_name}".humanize

    model =
      begin
        model_name.constantize
      rescue NameError
        abort "Unknown model #{model_name}"
      end

    record = model.find_by(id: record_id)
    abort "#{model_name} ##{record_id} not found" unless record

    puts "== Destroy record =="
    puts "Model: #{model_name}"
    puts "Record ID: #{record.id}"
    puts "Dry run: #{dry_run}"
    puts "Whodunnit: #{whodunnit}"
    puts "Revision comment: #{revision_comment}"
    puts

    #
    # Report dependent records (dependent: :destroy only)
    #
    destroy_count = Xronos::DestroyTree.print_destroy_tree_and_count(record)

    puts "* = records scheduled to be destroyed asynchronously"
    puts
    puts "Total records to be destroyed: #{destroy_count}"
    puts

    if dry_run
      puts "Not deleting any records because DRY_RUN=false is not set"
      exit
    end

    #
    # Execute destruction
    #
    progress =
      ProgressBar.create(
        title: "Records destroyed",
        total: destroy_count,
        format: "%t |%B| %c/%C"
      )

    subscriber =
      ActiveSupport::Notifications.subscribe("destroy.active_record") do |_name, _start, _finish, _id, payload|
        # Only count destroys for the model tree we initiated
        # (prevents unrelated destroys from incrementing the bar)
        if payload[:record]&.persisted? == false
          progress.increment
        end
      end

    PaperTrail.request(whodunnit: whodunnit) do
      if record.respond_to?(:revision_comment=)
        record.revision_comment = revision_comment
      end

      record.destroy!
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    puts
    puts "#{model_name} ##{record_id} destroyed."

  end
end

