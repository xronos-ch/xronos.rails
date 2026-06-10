namespace :xronos do
  namespace :citations do
    desc "Remove duplicate citations (keeps the lowest id per citing + reference)"
    task deduplicate: :environment do
      dry_run = ENV["DRY_RUN"].present?

      puts "== Citation deduplication =="
      puts "Mode: #{dry_run ? 'DRY RUN (no changes)' : 'DELETE duplicates'}"
      puts

      duplicates = Citation
        .select("MIN(id) AS keep_id, citing_type, citing_id, reference_id, COUNT(*) AS duplicate_count")
        .group(:citing_type, :citing_id, :reference_id)
        .having("COUNT(*) > 1")
        .to_a

      total_groups = duplicates.size
      total_rows   = duplicates.sum { |d| d.count - 1 }

      puts "Duplicate groups found: #{total_groups}"
      puts "Rows to be removed:     #{total_rows}"
      puts

      if total_groups.zero?
        puts "No duplicates found. Nothing to do."
        next
      end

      duplicates.find_each(batch_size: 100) do |dup|
        scope = Citation.where(
          citing_type: dup.citing_type,
          citing_id: dup.citing_id,
          reference_id: dup.reference_id
        ).where.not(id: dup.keep_id)

        if dry_run
          puts "Would delete #{scope.count} rows for " \
            "#{dup.citing_type}(#{dup.citing_id}) → reference #{dup.reference_id}"
        else
          deleted = scope.delete_all
          puts "Deleted #{deleted} rows for " \
            "#{dup.citing_type}(#{dup.citing_id}) → reference #{dup.reference_id}"
        end
      end

      puts
      puts dry_run ? "Dry run completed." : "Deduplication completed."
    end
  end
end
